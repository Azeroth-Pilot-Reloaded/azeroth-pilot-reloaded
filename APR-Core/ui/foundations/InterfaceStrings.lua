-- Built-in English/French labels for the new interface, with AceLocale override support.
-- Keeping fallbacks here makes development builds readable before localization packaging.

local L = LibStub("AceLocale-3.0"):GetLocale("APR")
local labels = {
    DATA_UNAVAILABLE = { "Unavailable", "Indisponible" },
    HIDDEN = { "Hidden", "Masqué" },
    YES = { "Yes", "Oui" },
    NO = { "No", "Non" },
    STATUS_STEP = { "Step", "Étape" },
    PERF_SECOND = { "Second %+d · displayed 120-second window", "Seconde %+d · fenêtre affichée de 120 secondes" },
    PERF_EMPTY_SECOND = { "No instrumented calls in this second.", "Aucun appel instrumenté pendant cette seconde." },
    PERF_SLOW_COUNT = { "Calls ≥ 10 ms", "Appels ≥ 10 ms" },
    PERF_PEAK_CALL = { "Largest call", "Appel le plus long" },
    PERF_GRAPH_LIVE = { "Last 120 seconds · hover for details. Capture continues when the graph is frozen.", "120 dernières secondes · survolez pour les détails. Figer le graphique laisse la capture active." },
    PERF_GRAPH_FROZEN = { "Graph frozen · live measurements and tables continue.", "Graphique figé · les mesures et les tableaux continuent." },
    PERF_FREEZE_GRAPH = { "Freeze graph", "Figer le graphique" },
    PERF_RESUME_GRAPH = { "Resume graph", "Reprendre le graphique" },
    PERF_METRIC_MAX = { "Largest call / second (ms)", "Appel maximal / seconde (ms)" },
    PERF_METRIC_TOTAL = { "Cumulative time / second (ms)", "Temps cumulé / seconde (ms)" },
    PERF_METRIC_CALLS = { "Calls / second", "Appels / seconde" },
    PERF_LIMITS = { "APR instrumented calls only. Nested timings overlap. Capture is off by default; it continues when this window closes.", "Appels instrumentés d'APR uniquement. Les durées imbriquées se recouvrent. La capture est désactivée par défaut et continue après fermeture." },
    COUNTERS = { "Cache / activity counters", "Compteurs de cache / activité" },
    COPY_HINT = { "Select the report, then press Ctrl+C.", "Sélectionnez le rapport, puis appuyez sur Ctrl+C." },
    AFK = { "Break timer", "Minuteur de pause" },
    CATEGORY = { "Category", "Catégorie" },
    AUTHOR = { "Author", "Auteur" },
    COMPLETE = { "Completed", "Terminée" },
    STEPS = { "steps", "étapes" },
    UP = { "Move up", "Monter" },
    DOWN = { "Move down", "Descendre" },
    RESET = { "Reset", "Réinitialiser" },
    CLOSE = { "Close", "Fermer" },
    THEME_WOW = { "World of Warcraft", "World of Warcraft" },
    PERFORMANCE = { "Performance", "Performances" },
    CAPTURE = { "Start capture", "Démarrer la capture" },
    STOP = { "Stop capture", "Arrêter la capture" },
    CLEAR = { "Clear", "Effacer" },
    EXPORT = { "Copy report", "Copier le rapport" },
    OVERVIEW = { "Overview", "Vue d'ensemble" },
    SLOW_CALLS = { "Slow calls", "Appels lents" },
    NO_CAPTURE = { "Start a capture, then play normally to collect measurements.", "Démarrez une capture, puis jouez normalement pour recueillir des mesures." },
    REDACT = { "Hide character and realm", "Masquer le personnage et le royaume" },
    UNDO = { "Undo last skip", "Annuler le dernier saut" },
    UNDO_UNAVAILABLE = { "No manual skip to undo for this step.", "Aucun saut manuel à annuler pour cette étape." },
    NO_ROUTE = { "Choose a route to start your guide.", "Choisissez une route pour démarrer le guide." },
    CALLS = { "Calls", "Appels" },
    TOTAL = { "Total ms", "Total ms" },
    AVERAGE = { "Mean ms", "Moyenne ms" },
    MAX = { "Max ms", "Max ms" },
    SEARCH = { "Search...", "Rechercher..." },
    ENABLE_ADDON = { "Enable guide", "Activer le guide" },
    SHOW_ARROW = { "Navigation arrow", "Flèche de navigation" },
    FONT_SIZE = { "Text size", "Taille du texte" },
}

function APR:LocalizeUI(key, ...)
    local pair = labels[key]
    local text = rawget(L, "UI_" .. key) or (pair and pair[GetLocale() == "frFR" and 2 or 1]) or key
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end
