import os
import sys
import json
import requests
import re
from dotenv import load_dotenv
import argparse

load_dotenv()

# Read the Discord webhook URL from an environment variable
DISCORD_WEBHOOK_URL = os.getenv('DISCORD_WEBHOOK_URL')

# Check if the DISCORD_WEBHOOK_URL is set
if not DISCORD_WEBHOOK_URL:
    print("Error: DISCORD_WEBHOOK_URL environment variable is not set.")
    sys.exit(1)

# Parse command line arguments
parser = argparse.ArgumentParser(description='Post release notes to Discord.')
parser.add_argument('--tag', required=True, help='Release tag name')
parser.add_argument('--body', required=True, help='Release body')
args = parser.parse_args()

tag_name = args.tag
release_body = args.body

# Split release_body by lines
lines = release_body.splitlines()

# Remove the first line if it exists
if lines:
    lines = lines[1:]

# Create a new header line
header_line = f"## Patch Note - Version {tag_name} <:apr:1271743726225719296>"

# Rebuild the body with our custom first line
new_release_body = header_line + "\n".join(lines)

# Transform the Full Changelog URL to the desired markdown format
new_release_body = re.sub(
    r'\*\*Full Changelog\*\*: https://github\.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/([\w\.]+...[\w\.]+)',
    r'**Full Changelog**: [\1](https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/\1)',
    new_release_body
)

# Remove unnecessary newline(s) before header lines (lines starting with '#')
# This regex replaces any occurrence of a newline, optional whitespace, and another newline
# when it is immediately followed by a '#' with a single newline.
new_release_body = re.sub(r'\n\s*\n(?=\#)', '\n', new_release_body)

# Build the message to post on Discord
message = new_release_body

# Send the message to Discord
print("Posting to Discord...")
response = requests.post(DISCORD_WEBHOOK_URL, json={"content": message, "flags": 4})
if response.status_code != 204:
    print(f"Error posting to Discord: {response.status_code} {response.text}")
    sys.exit(1)

print("Message successfully posted to Discord!")
