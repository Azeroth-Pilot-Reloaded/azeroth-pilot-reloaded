import requests
import yaml
import os

def get_latest_releases():
    token = os.getenv('GITHUB_TOKEN')
    headers = {'Authorization': f'token {token}'}
    response = requests.get('https://api.github.com/repos/Azeroth-Pilot-Reloaded/azeroth-pilot-reloaded/releases', headers=headers)
    releases = response.json()
    versions = [release['tag_name'] for release in releases]
    return sorted(versions, reverse=True)

def update_yaml_file(versions):
    with open('.github/ISSUE_TEMPLATE/bug-report.yml', 'r') as file:
        data = yaml.safe_load(file)

    # Update versions in the APR Version dropdown
    for field in data['body']:
        if field.get('attributes', {}).get('label') == 'APR Version':
            field['attributes']['options'] = versions
        if field.get('attributes', {}).get('label') == 'Last Good Version':
            field['attributes']['options'] = versions

    with open('.github/ISSUE_TEMPLATE/bug-report.yml', 'w') as file:
        yaml.safe_dump(data, file)

if __name__ == '__main__':
    versions = get_latest_releases()
    update_yaml_file(versions)
