# Security Policy

## Supported Versions

Security updates are provided for the latest released version of the addon.

| Version | Supported |
| --- | --- |
| Latest release | :white_check_mark:  |
| Older releases | :x: |
| Alpha, beta, and development builds | Best effort |

Before reporting an issue, please verify that it can still be reproduced with
the latest version available from an official distribution source.

## Reporting a Vulnerability

Please do not report security vulnerabilities through public GitHub issues,
Discord channels, or other public discussions.

Use GitHub's private vulnerability reporting feature:

1. Open the **Security** tab of this repository.
2. Select **Report a vulnerability**.
3. Provide the information requested below.

If private vulnerability reporting is unavailable, contact a repository
maintainer privately before sharing technical details.

Please include:

- The affected addon version and World of Warcraft client version.
- Whether the issue affects Retail, Classic, PTR, or Beta.
- A clear description of the vulnerability and its potential impact.
- The steps required to reproduce it.
- A minimal proof of concept, if available.
- Any relevant error messages, stack traces, screenshots, or logs.
- Suggested mitigations or fixes, if known.

Remove account names, character names, access tokens, private chat messages,
and other personal or sensitive information from submitted material.

## What Counts as a Security Issue

Examples of relevant reports include:

- Untrusted chat messages, links, addon messages, or imported data causing
  unintended Lua execution or persistent data corruption.
- Malformed data causing significant client instability or denial of service.
- Unsafe deserialization, validation bypasses, or trust-boundary violations.
- Sensitive information being exposed through logs, exports, SavedVariables,
  addon communication, or external tooling maintained by this project.
- Vulnerabilities in companion applications, websites, build scripts, or
  release workflows maintained by this project.

Normal gameplay bugs, Lua errors without a security impact, route errors,
performance issues, and compatibility problems should be reported through the
regular GitHub issue tracker.

World of Warcraft addons run inside Blizzard's restricted Lua environment.
Reports based only on capabilities that addons do not have—such as arbitrary
filesystem access, operating-system command execution, or unrestricted network
access—may be closed unless a concrete exploit path is demonstrated.

## Disclosure Process

After receiving a report, the maintainers will:

1. Acknowledge the report as soon as reasonably possible.
2. Investigate and attempt to reproduce the issue.
3. Assess its severity and affected versions.
4. Prepare and test a fix when required.
5. Coordinate release and public disclosure with the reporter.

Please allow a reasonable amount of time for investigation and remediation
before publicly disclosing the vulnerability. We ask reporters not to exploit
the issue, access data that does not belong to them, disrupt services, or share
sensitive details before a fix is available.

## Scope

This policy covers the addon source code and any companion tools, websites,
build scripts, or release workflows maintained in this repository. Third-party
libraries, World of Warcraft itself, Blizzard services, addon distribution
platforms, and unrelated services should be reported to their respective
maintainers or vendors.

Thank you for helping keep the project and its users safe.
