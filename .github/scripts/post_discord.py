import os
import sys
import json
import requests
import re
from dotenv import load_dotenv

load_dotenv()

# We read the Discord webhook URL from an environment variable
DISCORD_WEBHOOK_URL = os.getenv('DISCORD_WEBHOOK_URL')

# We expect two arguments: the release tag and the release body
if len(sys.argv) < 3:
    print("Usage: python post_discord.py <tag_name> <release_body>")
    sys.exit(1)

tag_name = sys.argv[1]
release_body = sys.argv[2]


# Split release_body by lines
lines = release_body.splitlines()

# Remove the first line if it exists
if lines:
    lines = lines[1:]

# Create a new header line
header_line = f"## Patch Note - Version {tag_name} <:apr:1271743726225719296>"

# Rebuild the body with our custom first line
new_release_body = header_line + "\n" + "\n".join(lines)

# Transform the last line to the desired format
new_release_body = re.sub(
    r'\*\*Full Changelog\*\*: https://github\.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/([\w\.]+...[\w\.]+)',
    r'**Full Changelog**: [\1](https://github.com/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/compare/\1)',
    new_release_body
)

# Build the message to post on Discord
message = new_release_body

# Send the message to Discord
print("Posting to Discord...")
response = requests.post(DISCORD_WEBHOOK_URL, json={"content": message, "flags": 4})
if response.status_code != 204:
    print(f"Error posting to Discord: {response.status_code} {response.text}")
    sys.exit(1)

print("Message successfully posted to Discord!")
