"""Synthetic inputs for the reusable read-only structural audit."""
from pathlib import Path
import tempfile
import unittest

from tests.routes.route_loader import load_routes
from tools.validation.route_structure_audit import audit_routes, audit_sources


class StructureAuditTests(unittest.TestCase):
    def catalog(self, text):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'fixture.lua'
            path.write_text(text, encoding='utf-8')
            return load_routes([path])

    def test_valid_scenario_parallel_and_references(self):
        catalog = self.catalog('''
        APR.RouteQuestStepList["first"] = {label="One", requiredRoute={"second"},
          nextRoute={{route="second",conditions={Faction="Horde"}}},
          steps={{Note="Act",_index=1},{RouteCompleted=true,_index=2}},
          parallelSteps={{steps={{Note="Side",_index=1}}}}}
        APR.RouteQuestStepList["second"] = {label="Two", scenarios={
          {scenarioID=12,steps={{Note="Block"}}},
          {scenarioID=12,steps={{Note="Continuation"}}}}}
        ''')
        self.assertEqual(audit_routes(catalog), [])

    def test_schema_per_declaration_and_missing_reference(self):
        catalog = self.catalog('''
        APR.RouteQuestStepList["bad"]={label="Bad",steps={{Faction="Horde"}}}
        APR.RouteQuestStepList["other"]={label="Other",nextRoute={"absent"},
          steps={{Note="Do"}}}
        ''')
        findings = audit_routes(catalog)
        self.assertEqual({f['rule'] for f in findings},
                         {'route_schema','missing-route-reference','missing-route-completion'})
        self.assertEqual(next(f for f in findings if f['rule']=='route_schema')['route'], 'bad')

    def test_cycles_indexes_and_conditional_ends_are_review_warnings(self):
        catalog = self.catalog('''
        APR.RouteQuestStepList["a"]={label="A",requiredRoute={"b"},steps={
          {Note="A",_index=1},{RouteCompleted=true,Faction="Horde",_index=1}}}
        APR.RouteQuestStepList["b"]={label="B",requiredRoute={"a"},steps={
          {RouteCompleted=true},{Note="Later"},{RouteCompleted=true}}}
        ''')
        findings = audit_routes(catalog)
        self.assertEqual({f['rule'] for f in findings}, {'required-route-cycle',
                         'duplicate-step-index','conditional-route-completion','early-route-completion'})
        self.assertTrue(all(f['severity']=='warning' for f in findings))

    def sources(self, *texts):
        with tempfile.TemporaryDirectory() as folder:
            paths = []
            for i, text in enumerate(texts):
                path = Path(folder) / f'{i}.lua'
                path.write_text(text, encoding='utf-8')
                paths.append(path)
            return audit_sources(paths)

    def test_conditional_shortcuts_with_unconditional_end_do_not_warn(self):
        catalog = self.catalog('''
        APR.RouteQuestStepList["shortcut"]={label="Shortcut",steps={
          {RouteCompleted=true,Faction="Horde"}, {Note="Continue"},
          {RouteCompleted=true,Class="MAGE"}, {RouteCompleted=true}}}
        APR.RouteQuestStepList["filtered"]={label="Filtered",steps={
          {RouteCompleted=true,Faction="Horde"}, {Note="Continue"},
          {RouteCompleted=true,Class="MAGE"}}}
        ''')
        findings = audit_routes(catalog)
        self.assertEqual([(f['rule'],f['route'],f['path']) for f in findings],
                         [('conditional-route-completion','filtered','steps[3]')])

    def test_unconditional_early_end_reports_skipped_content_only(self):
        catalog = self.catalog('''
        APR.RouteQuestStepList["early"]={label="Early",steps={
          {RouteCompleted=true},{Note="Unreachable"},
          {RouteCompleted=true,Faction="Horde"}}}
        ''')
        findings = audit_routes(catalog)
        self.assertEqual([(f['rule'],f['path']) for f in findings],
                         [('early-route-completion','steps[1]')])

    def test_duplicate_literals_and_scopes(self):
        findings = self.sources('''
        APR.RouteQuestStepList["synthetic"]={label="One", steps={
          {Faction="Horde", child={Note="once"}, ["Faction"]="Alliance"},
          {Note="first", Note="second"}, {Note="separate"}},
          [1]="explicit", "implicit", [true]="bool"}
        ''')
        self.assertEqual([f['evidence']['key'] for f in findings], [1, 'Faction', 'Note'])
        self.assertTrue(all(f['route']=='synthetic' for f in findings))
        self.assertEqual(findings[1]['path'], '$.steps[1].Faction')
        self.assertEqual(findings[1]['evidence']['first_line'], 3)

    def test_comments_strings_calls_expressions_and_anonymous_functions(self):
        findings = self.sources('''
        local x={
          text=[=[ a=1,a=2,{ } ]=], -- a=1,a=2
          nested=call({a=1}, {a=2}),
          fn=function(a,b) if a then return {a=1,b=2} end
            for i=1,2 do local t={v=i} end return a,b end,
          expression=(call(1,2) or call(3,4)),
          --[==[ text=1,text=2 ]==]
          separate={a=1}, another={a=2}, [true]=1,[1]=2,
          ["escaped\\097"]=1, escapeda=2,
        }
        ''')
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]['evidence']['key'], 'escapeda')

    def test_syntax_failure_does_not_abort_later_files(self):
        findings = self.sources('local broken = {', 'local x={a=1,a=2}')
        self.assertEqual([f['rule'] for f in findings], ['lua-syntax','duplicate-lua-table-key'])

    def test_call_argument_tables_keep_route_context(self):
        findings = self.sources('''APR.RouteQuestStepList["example"]={
          steps=make({Note="a",Note="b"}, {Note="c"}),label="Example"}''')
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0]['route'], 'example')
        self.assertEqual(findings[0]['evidence']['key'], 'Note')

    def test_implicit_numeric_and_long_string_keys(self):
        findings = self.sources('local t={"one",[1.0]="again",[[long]]=1}')
        self.assertEqual([f['rule'] for f in findings], ['lua-syntax'])
        findings = self.sources('local t={"one",[1.0]="again", [ [=[long]=] ]=1, long=2}')
        self.assertEqual([f['evidence']['key'] for f in findings], [1.0,'long'])
        findings = self.sources('local t={[.5]=1,[0.5]=2,[1e2]=3,[100]=4}')
        self.assertEqual([f['evidence']['key'] for f in findings], [0.5,100])


if __name__ == '__main__':
    unittest.main()
