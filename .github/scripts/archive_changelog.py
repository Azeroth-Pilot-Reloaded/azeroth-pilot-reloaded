#!/usr/bin/env python3
"""Archive CurseForge changelogs for every APR locale (preview by default).

Logs each download, upload, retry and verification to the console and a .log
file. A matching JSON backup records original values and progress per language.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import logging
import math
import os
from pathlib import Path
import re
import sys
import time

import requests
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
PROJECT_ID = 618667
LOCALES = ("enUS", "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW")
KEYS = ("New Changelog", "Prev Changelog")
MAX_VERSIONS = 4
VERSION = re.compile(
    r"(?m)^[ \t]*[vV]?(\d+(?:\.\d+){1,3}(?:[-+][0-9A-Za-z.-]+)?)"
    r"[ \t]*(?:\([^\r\n]*\))?[ \t]*$"
)
LONG_STRING = re.compile(r"\[(=*)\[")
LOG = logging.getLogger("archive_changelog")
RETRY_STATUS = {429, 500, 502, 503, 504}


class UploadNotApplied(RuntimeError):
    """All upload attempts failed and a fresh export confirmed unchanged values."""


def normalize(text: str) -> str:
    return text.replace("\r\n", "\n").replace("\r", "\n")


def lua_tokens(text: str):
    """Read Lua data without executing it; preserve UTF-8 and multiline strings."""
    index = 0
    while index < len(text):
        char = text[index]
        if char.isspace() or char == "\ufeff":
            index += 1
            continue
        if text.startswith("--", index):
            start = LONG_STRING.match(text, index + 2)
            if start:
                close = "]" + start[1] + "]"
                end = text.find(close, start.end())
                if end < 0:
                    raise ValueError("Unterminated Lua comment")
                index = end + len(close)
            else:
                end = text.find("\n", index)
                index = len(text) if end < 0 else end + 1
            continue
        start = LONG_STRING.match(text, index)
        if start:
            close = "]" + start[1] + "]"
            end = text.find(close, start.end())
            if end < 0:
                raise ValueError("Unterminated Lua long string")
            value = normalize(text[start.end():end])
            if value.startswith("\n"):
                value = value[1:]
            yield "string", value
            index = end + len(close)
            continue
        if char in ('"', "'"):
            quote = char
            index += 1
            value = bytearray()
            while index < len(text) and text[index] != quote:
                char = text[index]
                index += 1
                if char != "\\":
                    value.extend(char.encode("utf-8"))
                    continue
                if index == len(text):
                    raise ValueError("Unterminated Lua escape")
                char = text[index]
                index += 1
                escapes = {"a": "\a", "b": "\b", "f": "\f", "n": "\n", "r": "\r", "t": "\t", "v": "\v", "\\": "\\", '"': '"', "'": "'"}
                if char in escapes:
                    value.extend(escapes[char].encode("utf-8"))
                elif char.isascii() and char.isdigit():
                    digits = char
                    while index < len(text) and len(digits) < 3 and text[index] in "0123456789":
                        digits += text[index]
                        index += 1
                    value.append(int(digits))
                elif char in "\r\n":
                    if char == "\r" and index < len(text) and text[index] == "\n":
                        index += 1
                    value.extend(b"\n")
                else:
                    raise ValueError(f"Unsupported Lua escape: \\{char}")
            if index == len(text):
                raise ValueError("Unterminated Lua quoted string")
            index += 1
            yield "string", normalize(value.decode("utf-8"))
            continue
        word = re.match(r"[A-Za-z_][A-Za-z_0-9]*", text[index:])
        if word:
            yield "word", word[0]
            index += len(word[0])
        else:
            yield "symbol", char
            index += 1


def parse_changelogs(text: str) -> dict[str, str]:
    tokens = list(lua_tokens(text))
    values = {}
    for index in range(len(tokens) - 5):
        part = tokens[index:index + 6]
        if (part[0] == ("word", "L") and part[1] == ("symbol", "[")
                and part[2][0] == "string" and part[2][1] in KEYS
                and part[3] == ("symbol", "]") and part[4] == ("symbol", "=")):
            key = part[2][1]
            if key in values or part[5][0] != "string":
                raise ValueError(f"Duplicate or non-string {key!r} in export")
            if index + 6 < len(tokens) and tokens[index + 6] == ("symbol", "."):
                raise ValueError(f"Expected a literal string for {key!r}")
            values[key] = part[5][1]
    return values


def split_versions(text: str) -> list[tuple[str, str]]:
    text = normalize(text).strip()
    if not text:
        return []
    headers = list(VERSION.finditer(text))
    if not headers or headers[0].start() != 0:
        raise ValueError("Changelog must start with a version header, e.g. v6.8.0 (2026-10-08)")
    return [
        (header[1], text[header.start():headers[index + 1].start() if index + 1 < len(headers) else len(text)].strip())
        for index, header in enumerate(headers)
    ]


def archive_values(values: dict[str, str]) -> dict[str, str] | None:
    new = values.get(KEYS[0], "")
    if not new.strip():
        return None
    releases = split_versions(new) + split_versions(values.get(KEYS[1], ""))
    seen = set()
    kept = []
    for version, block in releases:
        if version not in seen:
            seen.add(version)
            kept.append(block)
        if len(kept) == MAX_VERSIONS:
            break
    return {KEYS[0]: "", KEYS[1]: "\n\n".join(kept)}


def lua_quote(value: str) -> str:
    escapes = {"\\": "\\\\", '"': '\\"', "\n": "\\n", "\r": "\\r", "\t": "\\t"}
    return '"' + "".join(escapes.get(char, f"\\{ord(char):03d}" if ord(char) < 32 else char) for char in value) + '"'


class CurseForge:
    def __init__(self, project_id: int, token: str, *, retries: int = 3,
                 timeout: float = 60, retry_delay: float = 2):
        self.url = f"https://wow.curseforge.com/api/projects/{project_id}/localization"
        self.import_url = f"https://legacy.curseforge.com/api/projects/{project_id}/localization/import"
        self._token = token
        self.retries = retries
        self.timeout = timeout
        self.retry_delay = retry_delay
        self.session = requests.Session()
        self.session.headers.update({"X-Api-Token": token})

    def log_error_response(self, label: str, response) -> None:
        # CurseForge's errorMessage can echo request data, including the API token.
        body = response.text if isinstance(response.text, str) else ""
        for secret in (self._token, json.dumps(self._token)[1:-1]):
            if secret:
                body = body.replace(secret, "[REDACTED]")
        body = re.sub(r"\s+", " ", re.sub(r"[\x00-\x1f\x7f]", " ", body)).strip()
        LOG.warning("%s: server response: %s%s", label, body[:4000] or "(empty body)",
                    " [truncated]" if len(body) > 4000 else "")

    def request(self, method: str, endpoint: str, label: str, *, reconcile=None, **kwargs):
        for attempt in range(1, self.retries + 2):
            LOG.info("%s: attempt %s/%s (read timeout %ss)", label, attempt, self.retries + 1, self.timeout)
            started = time.monotonic()
            response = None
            try:
                response = getattr(self.session, method)(
                    self.import_url if endpoint == "/import" else self.url + endpoint,
                    timeout=(10, self.timeout), **kwargs,
                )
                response.raise_for_status()
                LOG.info("%s: HTTP %s received in %.1fs%s", label, response.status_code,
                         time.monotonic() - started, " (upload response only; verification follows)" if method == "post" else "")
                return response
            except (requests.Timeout, requests.ConnectionError, requests.HTTPError) as error:
                if response is not None:
                    self.log_error_response(label, response)
                if isinstance(error, requests.HTTPError) and (
                        response is None or response.status_code not in RETRY_STATUS):
                    LOG.error("%s: HTTP %s; not retrying", label, response.status_code if response is not None else "unknown")
                    raise
                reason = f"HTTP {response.status_code}" if response is not None else type(error).__name__
                LOG.warning("%s: %s after %.1fs", label, reason, time.monotonic() - started)
                # A timed-out POST may have succeeded. Read the server before resending.
                if reconcile is not None and reconcile():
                    LOG.info("%s: write confirmed by a fresh export; no resend needed", label)
                    return None
                if attempt > self.retries:
                    LOG.error("%s: all %s attempts failed", label, attempt)
                    if reconcile is not None:
                        raise UploadNotApplied(
                            f"{label}: all {attempt} attempts failed; fresh export confirmed server values unchanged"
                        ) from error
                    raise
                delay = min(60, self.retry_delay * 2 ** min(attempt - 1, 10))
                if response is not None:
                    retry_after = response.headers.get("Retry-After", "")
                    if retry_after.isdigit():
                        delay = min(60, max(delay, int(retry_after)))
                LOG.warning("%s: retry in %ss", label, delay)
                time.sleep(delay)

    def export(self, locale: str) -> dict[str, str]:
        response = self.request("get", "/export", f"[DOWNLOAD] {locale}", params={
            "lang": locale, "export-type": "TableAdditions", "table-name": "L",
            "unlocalized": "Ignore", "escape-non-ascii-characters": "false",
            "true-if-value-equals-key": "false",
        })
        response.encoding = "utf-8"
        if "<html" in response.text.lower() or "<!doctype html" in response.text.lower():
            raise ValueError(f"{locale}: received an HTML page instead of a localization export")
        values = parse_changelogs(response.text)
        LOG.info("[DOWNLOAD] %s: parsed New Changelog (%s chars), Prev Changelog (%s chars)",
                 locale, len(values.get(KEYS[0], "")), len(values.get(KEYS[1], "")))
        return values

    def upload(self, locale: str, values: dict[str, str], *, expected_before=None) -> None:
        def reconcile():
            LOG.warning("[VERIFY AFTER UPLOAD ERROR] %s: checking whether the server applied %s",
                        locale, ", ".join(values))
            try:
                actual = self.export(locale)
            except (requests.RequestException, ValueError) as error:
                raise RuntimeError(
                    f"{locale}: upload outcome unknown; could not re-export. No further POST sent. "
                    "Rerun to read the current server values before proceeding."
                ) from error
            expected_after = {**(expected_before or {}), **values}
            if expected_before is not None:
                if same_values(actual, expected_after):
                    return True
                if not same_values(actual, expected_before):
                    raise RuntimeError(f"{locale}: translations changed during upload recovery; stopped without resending")
            elif all(actual.get(key, "") == value for key, value in values.items()):
                return True
            LOG.info("[VERIFY AFTER UPLOAD ERROR] %s: change not present; safe to retry the same values", locale)
            return False

        # Match the working localization client rather than the JSON-only docs:
        # https://github.com/p3lim/curseforge-localizations/blob/master/update.py
        # TableAdditions is the default; metadata and Lua text are separate form parts.
        metadata = {"language": locale, "missing-phrase-handling": "DoNothing"}
        localizations = "\n".join(f"L[{lua_quote(key)}] = {lua_quote(value)}" for key, value in values.items())
        LOG.info("[UPLOAD FORMAT] %s: multipart/form-data to %s (metadata + localizations)", locale, self.import_url)
        self.request("post", "/import", f"[UPLOAD] {locale} {', '.join(values)}", reconcile=reconcile, files={
            "metadata": (None, json.dumps(metadata)),
            "localizations": (None, localizations),
        })


def same_values(actual: dict[str, str], expected: dict[str, str]) -> bool:
    # CurseForge may omit an explicitly empty translation from Ignore exports.
    return all(actual.get(key, "") == expected.get(key, "") for key in KEYS)


def prepare(api: CurseForge, locales: list[str], *, plan=None, save=lambda: None) -> dict:
    if plan is None:
        plan = {}
    for locale in locales:
        plan[locale] = {"status": "downloading", "upload_started": False}
        save()
        before = api.export(locale)
        plan[locale]["before"] = before
        plan[locale]["status"] = "validating"
        save()
        try:
            after = archive_values(before)
        except ValueError as error:
            raise ValueError(f"{locale}: {error}") from error
        plan[locale].update(before=before, after=after, status="skipped" if after is None else "planned")
        save()
        if after is None:
            LOG.info("[SKIP] %s: New Changelog empty or untranslated; no upload needed", locale)
        else:
            versions = ", ".join(version for version, _ in split_versions(after[KEYS[1]]))
            LOG.info("[PLAN ONLY] %s: would clear New Changelog; archive versions: %s. Nothing uploaded yet.", locale, versions)
    return plan


def apply_plan(api: CurseForge, plan: dict, *, save=lambda: None) -> None:
    def progress(locale, status, message):
        plan[locale]["status"] = status
        save()
        LOG.info("%s %s", locale, message)

    # Update the primary locale last, after archiving all existing translations.
    for locale in sorted(plan, key=lambda value: value == "enUS"):
        before, after = plan[locale]["before"], plan[locale]["after"]
        if after is None:
            continue
        progress(locale, "checking", "[CHECK] re-exporting before any upload")
        if not same_values(api.export(locale), before):
            raise RuntimeError(f"{locale}: translations changed after export; stopped before upload")
        # Store and verify the archive before clearing the current changelog.
        plan[locale]["upload_started"] = True
        progress(locale, "uploading_archive", "[UPLOAD] starting Prev Changelog upload")
        try:
            api.upload(locale, {KEYS[1]: after[KEYS[1]]}, expected_before=before)
        except UploadNotApplied:
            progress(locale, "archive_not_applied", "[NOT APPLIED] archive upload failed; fresh export confirmed both values unchanged")
            raise
        archived = {**before, KEYS[1]: after[KEYS[1]]}
        progress(locale, "verifying_archive", "[VERIFY] re-exporting to confirm Prev Changelog; New Changelog still retained")
        if not same_values(api.export(locale), archived):
            raise RuntimeError(f"{locale}: archive verification failed; New Changelog has not been cleared")
        progress(locale, "archive_verified", "[VERIFIED] Prev Changelog archived successfully")
        progress(locale, "clearing_current", "[UPLOAD] starting New Changelog clear")
        try:
            api.upload(locale, {KEYS[0]: ""}, expected_before=archived)
        except UploadNotApplied:
            progress(locale, "clear_not_applied", "[NOT APPLIED] clear failed; archive verified and New Changelog still retained")
            raise
        progress(locale, "verifying_final", "[VERIFY] re-exporting to confirm both final values")
        if not same_values(api.export(locale), after):
            raise RuntimeError(f"{locale}: final verification failed; check the saved backup and CurseForge")
        progress(locale, "completed", "[DONE] Prev Changelog archived and New Changelog empty; both verified")


def save_backup(path: Path, record: dict) -> None:
    temporary = path.with_suffix(".json.tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        json.dump(record, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    temporary.replace(path)


def close_logging() -> None:
    for handler in LOG.handlers[:]:
        LOG.removeHandler(handler)
        handler.close()


def configure_logging(path: Path) -> None:
    close_logging()
    LOG.setLevel(logging.INFO)
    LOG.propagate = False
    for handler in (logging.StreamHandler(sys.stdout), logging.FileHandler(path, encoding="utf-8")):
        handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s", datefmt="%H:%M:%S"))
        LOG.addHandler(handler)


def summarize(plan: dict) -> None:
    descriptions = {
        "pending_download": "not downloaded; no upload",
        "downloading": "download unfinished; no upload",
        "validating": "downloaded; plan validation unfinished; no upload",
        "planned": "downloaded and planned; no upload",
        "skipped": "New Changelog empty/untranslated; skipped",
        "checking": "pre-upload check unfinished; no upload",
        "uploading_archive": "archive upload started; outcome not verified",
        "archive_not_applied": "archive NOT applied; fresh export confirmed both original values unchanged",
        "verifying_archive": "archive upload returned; verification unfinished",
        "archive_verified": "archive verified; New Changelog not cleared",
        "clearing_current": "archive verified; clear started, outcome not verified",
        "clear_not_applied": "archive VERIFIED; clear NOT applied; New Changelog still retained",
        "verifying_final": "clear returned; final verification unfinished",
        "completed": "archive and empty New Changelog VERIFIED",
    }
    LOG.info("[SUMMARY] Per-language results:")
    for locale, entry in plan.items():
        LOG.info("[SUMMARY] %s: %s", locale, descriptions[entry["status"]])
    if not any(entry.get("upload_started") for entry in plan.values()):
        LOG.info("[SUMMARY] No uploads were started during this run.")


def main(argv: list[str] | None = None) -> int:
    load_dotenv(ROOT / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--apply", action="store_true", help="Upload changes to CurseForge")
    mode.add_argument("--dry-run", action="store_true", help="Preview only (default)")
    parser.add_argument("--project-id", type=int, default=PROJECT_ID)
    parser.add_argument("--locales", default=",".join(LOCALES), help="Comma-separated locales (default: all eleven APR locales)")
    parser.add_argument("--backup-dir", type=Path, default=ROOT / ".cache/changelog", help="Directory for JSON backups/progress and .log files (default: .cache/changelog)")
    parser.add_argument("--retries", type=int, default=3, help="Additional attempts after transient errors (default: 3)")
    parser.add_argument("--timeout", type=float, default=60, help="Read timeout per request in seconds (default: 60)")
    parser.add_argument("--retry-delay", type=float, default=2, help="Initial retry delay in seconds; doubles up to 60s (default: 2)")
    args = parser.parse_args(argv)
    token = os.getenv("CF_API_KEY")
    if not token:
        parser.error("Set CF_API_KEY in the environment or the repository's .env file")
    locales = list(dict.fromkeys(value.strip() for value in args.locales.split(",") if value.strip()))
    if args.project_id <= 0 or not locales or any(locale not in LOCALES for locale in locales):
        parser.error("Use a positive project ID and supported APR locales: " + ",".join(LOCALES))
    if args.retries < 0 or not math.isfinite(args.timeout) or args.timeout <= 0 or not math.isfinite(args.retry_delay) or args.retry_delay < 0:
        parser.error("Use retries >= 0, a finite timeout > 0, and a finite retry delay >= 0")
    backup = None
    plan = {locale: {"status": "pending_download", "upload_started": False} for locale in locales}
    record = {"project_id": args.project_id, "mode": "apply" if args.apply else "dry-run",
              "phase": "download", "result": "running", "locales": plan}
    try:
        args.backup_dir.mkdir(parents=True, exist_ok=True)
        backup = args.backup_dir / (datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ") + ".json")
        configure_logging(backup.with_suffix(".log"))
        save = lambda: save_backup(backup, record)
        save()
        LOG.info("[START] mode=%s project=%s locales=%s retries=%s timeout=%ss",
                 record["mode"], args.project_id, ",".join(locales), args.retries, args.timeout)
        LOG.info("[FILES] Log: %s", backup.with_suffix(".log"))
        LOG.info("[FILES] Backup and progress: %s", backup)
        LOG.info("[PHASE 1/2] Downloading all languages and preparing the plan. No uploads in this phase.")
        api = CurseForge(args.project_id, token, retries=args.retries, timeout=args.timeout, retry_delay=args.retry_delay)
        prepare(api, locales, plan=plan, save=save)
        if args.apply:
            record["phase"] = "upload"
            save()
            LOG.info("[PHASE 2/2] All downloads validated and backed up. Starting uploads (enUS last).")
            apply_plan(api, plan, save=save)
        else:
            LOG.info("[PREVIEW] Preview only. Run again with --apply to upload.")
        record.update(result="success", phase="finished")
        save()
        summarize(plan)
        return 0
    except (requests.RequestException, ValueError, RuntimeError, OSError, KeyboardInterrupt) as error:
        record.update(result="interrupted" if isinstance(error, KeyboardInterrupt) else "failed", error=str(error) or "Interrupted by user")
        LOG.error("[STOP] phase=%s: %s", record["phase"], record["error"])
        if backup:
            try:
                save_backup(backup, record)
            except OSError as save_error:
                LOG.error("Could not save final progress: %s", save_error)
        summarize(plan)
        LOG.info("[RERUN] A rerun first downloads current server values. Empty New Changelog is skipped; already archived versions are deduplicated.")
        if backup:
            LOG.info("[FILES] Original values and last recorded stage: %s", backup)
        return 130 if isinstance(error, KeyboardInterrupt) else 1
    finally:
        close_logging()


if __name__ == "__main__":
    raise SystemExit(main())
