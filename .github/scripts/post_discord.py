import argparse
import os
import re
import time

import requests
from dotenv import load_dotenv


DISCORD_MESSAGE_LIMIT = 2000
MAX_RATE_LIMIT_RETRIES = 3


def format_release_notes(tag_name, release_body):
    # Replace the release title with our Discord header.
    lines = release_body.splitlines()[1:]
    header = f"## Patch Note - Version {tag_name} <:apr:1271743726225719296>"
    message = header + "\n" + "\n".join(lines)

    message = re.sub(
        r'\*\*Full Changelog\*\*: https://github\.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/([\w\.]+...[\w\.]+)',
        r'**Full Changelog**: [\1](https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/\1)',
        message,
    )
    return re.sub(r'\n\s*\n(?=\#)', '\n', message)


def split_message(message, limit=DISCORD_MESSAGE_LIMIT):
    """Prefer paragraphs, Markdown entries, then complete sentences.

    A sentence longer than the limit must be split between words. Hard cuts
    are only needed for a single token longer than the limit.
    """
    if limit < 1:
        raise ValueError("The message limit must be positive")

    boundaries = (
        r'\n[ \t]*\n',
        # A wrapped prose line is not necessarily the end of a sentence.
        r'\n(?=[ \t]*(?:[-*+] |\d+[.)] |#{1,6} ))',
        r'(?<=[.!?\u2026])[\"\'\u201d\u2019\u00bb)\]*_]*\s+',
        r'\s+',
    )
    messages = []
    remaining = message.strip()
    while len(remaining) > limit:
        # Include the next character so a separator just after the limit counts.
        window = remaining[:limit + 1]
        split_at = limit
        for pattern in boundaries:
            candidates = [
                match.end() for match in re.finditer(pattern, window)
                if 0 < len(window[:match.end()].rstrip()) <= limit
            ]
            if candidates:
                split_at = candidates[-1]
                break

        messages.append(remaining[:split_at].rstrip())
        remaining = remaining[split_at:]
        # Keep Markdown indentation after a line/paragraph boundary.
        if pattern in boundaries[:2] and candidates:
            remaining = remaining.lstrip('\r\n')
        else:
            remaining = remaining.lstrip()

    if remaining:
        messages.append(remaining)
    return messages


def post_messages(webhook_url, messages):
    for index, message in enumerate(messages, start=1):
        print(f"Posting message {index}/{len(messages)} to Discord...")
        for attempt in range(MAX_RATE_LIMIT_RETRIES + 1):
            response = requests.post(
                webhook_url, json={"content": message, "flags": 4}, timeout=30,
            )
            if response.status_code == 429 and attempt < MAX_RATE_LIMIT_RETRIES:
                retry_after = response.headers.get("Retry-After")
                if retry_after is None:
                    retry_after = response.json()["retry_after"]
                time.sleep(float(retry_after))
                continue
            if response.status_code not in (200, 204):
                raise RuntimeError(
                    f"Error posting message {index}/{len(messages)} to Discord: "
                    f"{response.status_code} {response.text}"
                )
            break

        if index < len(messages) and response.headers.get("X-RateLimit-Remaining") == "0":
            time.sleep(float(response.headers.get("X-RateLimit-Reset-After", 0)))


def main():
    load_dotenv()
    parser = argparse.ArgumentParser(description="Post release notes to Discord")
    parser.add_argument('--tag', type=str, help='Release tag name')
    parser.add_argument('--body', type=str, help='Release body text')
    parser.add_argument('--webhook', type=str, help='Discord webhook URL')
    args = parser.parse_args()

    webhook_url = args.webhook or os.getenv('DISCORD_WEBHOOK_URL')
    if not webhook_url:
        print("Error: DISCORD_WEBHOOK_URL environment variable or --webhook argument is not set.")
        return 1

    tag_name = args.tag or os.getenv('RELEASE_TAG')
    release_body = args.body or os.getenv('RELEASE_BODY')
    if not tag_name or not release_body:
        print("Error: RELEASE_TAG/--tag or RELEASE_BODY/--body is not set.")
        return 1

    messages = split_message(format_release_notes(tag_name, release_body))
    try:
        post_messages(webhook_url, messages)
    except (requests.RequestException, RuntimeError) as error:
        print(error)
        return 1

    print(f"Successfully posted {len(messages)} message(s) to Discord!")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
