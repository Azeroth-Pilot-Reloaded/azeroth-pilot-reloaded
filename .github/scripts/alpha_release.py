"""Gate alpha uploads using publication history, with a manual override."""

from datetime import datetime, timedelta, timezone
import json
import os
from pathlib import Path
import subprocess
import urllib.parse
import urllib.request


COOLDOWN = timedelta(hours=1)
PACKAGER_STEP = "WoW Packager (alpha)"


def timestamp(value):
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def api(path, **params):
    url = f"{os.environ.get('GITHUB_API_URL', 'https://api.github.com')}/repos/{os.environ['GITHUB_REPOSITORY']}/{path}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {os.environ['GH_TOKEN']}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "APR-alpha-release",
    })
    # API failures fail the gate rather than accidentally permitting an upload.
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def pages(path, key, **params):
    page = 1
    while True:
        items = api(path, per_page=100, page=page, **params)[key]
        yield from items
        if len(items) < 100:
            return
        page += 1


def decision(sha, event, now, tagged=False, automated=False):
    if tagged:
        return False, "This commit has a tag; use the tag release instead."
    if event == "workflow_dispatch":
        return True, "Manual alpha: bypassing cooldown and duplicate checks."
    if automated:
        return False, "Automation commit: no automatic alpha."

    cutoff = now - COOLDOWN
    # Do not filter by run creation time: an old run can have a recent rerun.
    # No status filter also avoids GitHub's 1,000-result search limit.
    for run in pages("actions/workflows/release.yml/runs", "workflow_runs"):
        if timestamp(run["updated_at"]) <= cutoff and run["head_sha"] != sha:
            continue
        for job in pages(f"actions/runs/{run['id']}/jobs", "jobs", filter="all"):
            for step in job.get("steps", []):
                if step["name"] != PACKAGER_STEP or step.get("conclusion") != "success":
                    continue
                if run["head_sha"] == sha:
                    return False, "This commit already has a published alpha."
                if timestamp(step["completed_at"]) > cutoff:
                    return False, "An alpha was published less than one hour ago."
    return True, "New commit and no alpha publication in the last hour."


def main():
    sha = os.environ["GITHUB_SHA"]
    event = os.environ["GITHUB_EVENT_NAME"]
    tagged = bool(subprocess.check_output(
        ["git", "tag", "--points-at", "HEAD"], text=True
    ).strip())
    automated = False
    if event == "schedule":
        commit = api(f"commits/{sha}")
        automated = (commit.get("committer") or {}).get("login") == "github-actions[bot]"
    publish, reason = decision(
        sha, event, datetime.now(timezone.utc), tagged=tagged, automated=automated
    )
    print(reason)
    with Path(os.environ["GITHUB_OUTPUT"]).open("a", encoding="utf-8") as output:
        output.write(f"publish={str(publish).lower()}\n")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(os.environ["GITHUB_STEP_SUMMARY"]).open("a", encoding="utf-8") as summary:
            summary.write(f"Alpha release: {reason}\n")


if __name__ == "__main__":
    main()
