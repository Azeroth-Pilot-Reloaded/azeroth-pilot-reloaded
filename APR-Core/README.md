# APR-Core structure

The source tree is organized by responsibility:

- `core/`: addon bootstrap, events, commands, and version checks.
- `config/`: settings and route configuration.
- `data/`: internal models and static zone data.
- `features/`: gameplay features grouped by domain (`group`, `navigation`, `player`, and `questing`).
- `integrations/`: adapters for external addons and libraries.
- `ui/`: shared UI foundations, route UI, and standalone panels.
- `utils/`: reusable helpers and route-processing utilities.
- `locales/`, `assets/`, and `libs/`: translations, media, and vendored dependencies.

`APR.toc` remains the source of truth for runtime load order. Keep dependencies before their consumers when adding or moving modules.

`FarstriderLibData.xml` intentionally stays at this level because its embedded-library paths are resolved relative to the XML file.
