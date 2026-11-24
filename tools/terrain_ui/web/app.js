"use strict";

const translations = {
    fr: {
        language: "Langue de l’interface", title: "Graphes de terrain", selection: "Périmètre",
        client: "Client WoW", continent: "Continent", zone: "Zone", area: "Sous-zone",
        allContinents: "Tous les continents et mondes", allZones: "Toutes les zones", allAreas: "Toutes les sous-zones",
        clientEmpty: "Recherche des clients…", noClients: "Aucun client détecté. Indiquez son dossier avec --wow.",
        selectionEmpty: "Choisissez un client", chooseContinent: "Choisissez un continent ou un monde", chooseZone: "Choisissez une zone",
        catalogueLoading: "Lecture du catalogue du client…", catalogueError: "Impossible de lire le catalogue de ce client.",
        catalogueNote: "Certains noms de lieux ne sont disponibles que dans la langue installée.",
        worldCount: "{count} cartes de terrain lisibles",
        continentsGroup: "Continents", worldsGroup: "Mondes et instances", withoutName: "ID {id}",
        mapSearch: "Rechercher une carte", mapSearchPlaceholder: "Nom, MapID, UiMapID ou AreaID",
        noMapResults: "Aucun résultat dans le catalogue de ce client.",
        mapResultCount: "{count} résultats affichés. Précisez la recherche pour affiner.",
        advanced: "Réglages avancés", cells: "Résolution par tuile",
        cellsHelp: "Une grille plus fine détecte les petits passages et augmente la durée et la taille des packs. Si le graphe dépasse la capacité du format, le moteur retente la carte à la résolution inférieure.",
        threads: "Threads par monde", threadsHelp: "Nombre de threads pour le calcul des tuiles. Augmentez-le pour accélérer le calcul si de la mémoire est disponible.",
        minRegion: "Taille minimale des régions", regionHelp: "Nombre minimal de cellules connectées à conserver. Augmentez-le pour écarter les petites surfaces isolées.",
        stretch: "Tolérance de détour (%)", stretchHelp: "Surcoût maximal permis lorsqu’une liaison redondante est retirée du graphe. 0 % privilégie les distances originales.",
        roadThreshold: "Seuil principal des routes", roadHelp: "Opacité minimale, de 1 à 255, à partir de laquelle une texture marquée comme route sert de noyau au réseau de routes.",
        roadWeak: "Seuil secondaire des routes", weakHelp: "Opacité minimale pour étendre une route autour de son noyau. Ce seuil doit être inférieur ou égal au seuil principal.",
        wideHeights: "Altitudes étendues", heightHelp: "Conserve les dénivelés qui dépassent la plage du format compact. Les packs concernés utilisent davantage d’espace.",
        wideLayers: "Couches étendues", layersHelp: "Conserve davantage de surfaces superposées, par exemple sous un pont ou dans un bâtiment à étages.",
        keepPartial: "Conserver les packs partiels", partialHelp: "Construit un pack avec les tuiles lisibles si une partie du terrain est indisponible. Le bilan signale les packs incomplets.",
        reset: "Rétablir les valeurs par défaut", monitor: "Génération", pathLabel: "Périmètre en cours",
        elapsed: "Temps passé", eta: "Temps restant estimé", temporary: "Poids temporaire", packSize: "Poids des packs",
        start: "Lancer la génération", pause: "Demander une pause", resume: "Reprendre", pauseHelp: "La pause s’applique au prochain point d’arrêt du moteur. L’opération en cours peut se terminer.",
        logs: "Journaux du moteur", noLogs: "Les messages du moteur s’afficheront ici.", output: "Données de LibAPRNavigation",
        downloadLog: "Télécharger le journal complet", downloadReport: "Télécharger le rapport JSON",
        retryMaps: "Relancer les cartes à traiter ({count})", recovery: "Nouvelle lecture des tuiles",
        excludedTiles: "{count} tuiles écartées",
        copy: "Copier", copied: "Copié", copyError: "Sélectionnez le chemin pour le copier.",
        idle: "En attente", running: "En cours", pausing: "Pause demandée", paused: "En pause", complete: "Terminé", partial: "Résultat partiel", failed: "Échec",
        ready: "Prêt à générer", planning: "Inventaire des tuiles", preparing: "Préparation du moteur", extraction: "Extraction de la géométrie",
        raster: "Calcul du graphe", packing: "Assemblage du pack", verification: "Vérification du pack",
        installation: "Installation dans LibAPRNavigation", finished: "Génération terminée",
        world: "Carte {id}", tile: "Tuile {id}", tileCount: "{done} / {total} tuiles", free: "{size} disponibles sur le disque",
        worldsDone: "{done} / {total} cartes traitées", tilesDone: "{count} tuiles exportées", failures: "{count} en échec", partials: "{count} partielles",
        requestError: "L’interface n’a pas pu joindre le générateur.", jobError: "La génération a rencontré une erreur.",
        invalidRoad: "Le seuil secondaire doit être inférieur ou égal au seuil principal.",
        sizes: ["o", "Kio", "Mio", "Gio", "Tio"],
    },
    en: {
        language: "Interface language", title: "Terrain graphs", selection: "Scope",
        client: "WoW client", continent: "Continent", zone: "Zone", area: "Subzone",
        allContinents: "All continents and worlds", allZones: "All zones", allAreas: "All subzones",
        clientEmpty: "Detecting clients…", noClients: "No client detected. Pass its installation folder with --wow.",
        selectionEmpty: "Choose a client", chooseContinent: "Choose a continent or world", chooseZone: "Choose a zone",
        catalogueLoading: "Reading client catalogue…", catalogueError: "Could not read this client’s catalogue.",
        catalogueNote: "Some place names are available in the installed language only.",
        worldCount: "{count} readable terrain maps",
        continentsGroup: "Continents", worldsGroup: "Worlds and instances", withoutName: "ID {id}",
        mapSearch: "Find a map", mapSearchPlaceholder: "Name, MapID, UiMapID or AreaID",
        noMapResults: "No matches in this client’s catalogue.",
        mapResultCount: "Showing {count} results. Refine your search to narrow the list.",
        advanced: "Advanced settings", cells: "Tile resolution",
        cellsHelp: "A finer grid detects narrow passages and increases build time and pack size. If a graph exceeds the format’s capacity, the engine retries the map at the next lower resolution.",
        threads: "Threads per world", threadsHelp: "Number of threads used to build tiles. Increase it for faster builds when memory is available.",
        minRegion: "Minimum region size", regionHelp: "Minimum number of connected cells to keep. Increase it to remove small, isolated surfaces.",
        stretch: "Detour tolerance (%)", stretchHelp: "Maximum extra distance allowed when removing a redundant link. At 0%, the generator prioritizes retaining the original distances.",
        roadThreshold: "Main road threshold", roadHelp: "Minimum opacity, from 1 to 255, for a road texture to anchor a road in the network.",
        roadWeak: "Secondary road threshold", weakHelp: "Minimum opacity for extending a road around its core. This value must be at or below the main threshold.",
        wideHeights: "Extended elevations", heightHelp: "Keeps elevation differences that exceed the compact format’s range. Affected packs use more space.",
        wideLayers: "Extended layers", layersHelp: "Keeps more overlapping surfaces, for example under a bridge or inside a multistory building.",
        keepPartial: "Keep partial packs", partialHelp: "Builds a pack from readable tiles if some terrain is unavailable. The summary flags incomplete packs.",
        reset: "Restore defaults", monitor: "Generation", pathLabel: "Current scope",
        elapsed: "Elapsed time", eta: "Estimated time left", temporary: "Working disk usage", packSize: "Pack size",
        start: "Start generation", pause: "Request pause", resume: "Resume", pauseHelp: "The engine pauses at its next checkpoint. The operation already in progress may finish.",
        logs: "Engine logs", noLogs: "Engine messages will appear here.", output: "LibAPRNavigation data",
        downloadLog: "Download full log", downloadReport: "Download JSON report",
        retryMaps: "Retry unfinished maps ({count})", recovery: "Retrying tile reads",
        excludedTiles: "{count} tiles excluded",
        copy: "Copy", copied: "Copied", copyError: "Select the path to copy it.",
        idle: "Idle", running: "Running", pausing: "Pause requested", paused: "Paused", complete: "Complete", partial: "Partial result", failed: "Failed",
        ready: "Ready to generate", planning: "Finding terrain tiles", preparing: "Preparing the engine", extraction: "Extracting geometry",
        raster: "Building the graph", packing: "Writing pack", verification: "Verifying pack",
        installation: "Installing into LibAPRNavigation", finished: "Generation finished",
        world: "Map {id}", tile: "Tile {id}", tileCount: "{done} / {total} tiles", free: "{size} free on disk",
        worldsDone: "{done} / {total} maps processed", tilesDone: "{count} tiles exported", failures: "{count} failed", partials: "{count} partial",
        requestError: "The interface could not reach the generator.", jobError: "Generation encountered an error.",
        invalidRoad: "The secondary threshold must be at or below the main threshold.",
        sizes: ["B", "KiB", "MiB", "GiB", "TiB"],
    },
};

const products = {
    wow: "Retail", wowf: "Forever", wowt: "PTR", wowxptr: {fr: "PTR (autre branche)", en: "PTR (alternate branch)"},
    wow_classic: "Classic", wow_classic_era: "Classic Era",
    wow_classic_ptr: "Classic PTR", wow_classic_era_ptr: "Classic Era PTR", wow_beta: "Beta",
};
const get = (id) => document.getElementById(id);
const clientSelect = get("client");
const continentSelect = get("continent");
const zoneSelect = get("zone");
const areaSelect = get("area");
const mapSearch = get("map-search");
const mapResults = get("map-results");
const logsSection = get("log-section");
const fields = [...document.querySelectorAll("[data-setting]")];
const activeStates = new Set(["running", "pausing", "paused"]);
let language = localStorage.getItem("aprTerrainLanguage") === "en" ? "en" : "fr";
let clients = [], defaults = {}, catalogue = null, generation = {state: "idle"};
let hasClients = false, catalogueLoading = false, catalogueRequest = 0, actionPending = false;
let catalogueError = null, actionError = null, statusRequest = 0;
let searchableMaps = [];
const mapIdTypes = {map: "MapID", mapid: "MapID", world: "MapID", ui: "UiMapID", uimapid: "UiMapID",
    area: "AreaID", areaid: "AreaID"};

function t(key, variables = {}) {
    return translations[language][key].replaceAll(/\{(\w+)\}/g, (_, name) => variables[name]);
}

function localized(names, fallback = "") {
    return names?.[language] || names?.[language === "fr" ? "en" : "fr"] || fallback;
}

function locationName(item) {
    return localized(item.name, t("withoutName", {id: item.id}));
}

function searchText(value) {
    return value.toLowerCase().normalize("NFD").replace(/\p{M}/gu, "")
        .replaceAll("œ", "oe").replace(/[^\p{L}\p{N}]+/gu, " ").trim();
}

function indexMaps(tree) {
    const entries = [];
    const add = (item, scope, parents, ids) => {
        entries.push({item, scope, parents, ids, names: Object.values(item.name).map(searchText)});
    };
    for (const continent of tree) {
        const scope = {continent: continent.id};
        if (continent.world !== undefined) {
            add(continent, scope, [], [["MapID", continent.world]]);
        } else if (continent.id.startsWith("ui:")) {
            add(continent, scope, [], [["UiMapID", Number(continent.id.slice(3))]]);
        }
        for (const zone of continent.zones) {
            const zoneScope = {...scope, zone: zone.id};
            const ids = zone.roots.map((id) => ["AreaID", id]);
            if (/^\d+$/.test(zone.id)) ids.unshift(["UiMapID", Number(zone.id)]);
            add(zone, zoneScope, [continent.name], ids);
            for (const area of zone.subzones) {
                add(area, {...zoneScope, area: area.id}, [continent.name, zone.name, ...area.trail.slice(0, -1)],
                    [["AreaID", area.id]]);
            }
        }
    }
    return entries;
}

function findMaps(query) {
    const number = query.match(/^(?:(mapid|uimapid|areaid|map|world|ui|area)\s*[:#]?\s*|#)?(\d+)$/i);
    const needle = searchText(query);
    if (!needle) return [];
    const words = needle.split(" ");
    const matches = [];
    for (const entry of searchableMaps) {
        let id = entry.ids[0], rank = Infinity;
        if (number) {
            const type = mapIdTypes[number[1]?.toLowerCase()];
            id = entry.ids.find(([kind, value]) => (!type || kind === type) && value === Number(number[2]));
            if (id) rank = ["MapID", "UiMapID", "AreaID"].indexOf(id[0]);
        } else {
            for (const name of entry.names) {
                if (name === needle) rank = 0;
                else if (words.every((word) => name.includes(word))) rank = Math.min(rank, name.startsWith(needle) ? 1 : 2);
            }
        }
        if (rank !== Infinity) matches.push({entry, id, rank});
    }
    return matches.sort((a, b) => a.rank - b.rank || locationName(a.entry.item).localeCompare(locationName(b.entry.item), language));
}

function renderMapSearch() {
    const query = mapSearch.disabled ? "" : mapSearch.value.trim();
    const matches = query ? findMaps(query) : [];
    const limit = 12;
    mapResults.replaceChildren();
    mapResults.hidden = !matches.length;
    for (const {entry, id} of matches.slice(0, limit)) {
        const li = document.createElement("li");
        const button = document.createElement("button");
        button.type = "button";
        const title = document.createElement("strong");
        title.textContent = locationName(entry.item);
        const detail = document.createElement("small");
        const parentMap = entry.scope.area !== undefined && /^\d+$/.test(entry.scope.zone)
            ? `UiMapID ${entry.scope.zone}` : "";
        detail.textContent = [id?.join(" "), ...entry.parents.map((name) => localized(name)), parentMap]
            .filter(Boolean).join(" · ");
        button.append(title, detail);
        button.addEventListener("click", () => {
            mapSearch.value = "";
            renderScope(entry.scope);
            renderMonitor();
            mapSearch.focus({preventScroll: true});
        });
        li.append(button);
        mapResults.append(li);
    }
    const status = get("map-search-status");
    const key = !matches.length && query ? "noMapResults" : matches.length > limit ? "mapResultCount" : null;
    status.textContent = key ? t(key, {count: format(limit)}) : "";
}

function validSelection() {
    const continent = catalogue?.tree.find((item) => item.id === continentSelect.value);
    const zone = continent?.zones.find((item) => item.id === zoneSelect.value);
    const area = zone?.subzones.find((item) => String(item.id) === areaSelect.value);
    return {continent, zone, area};
}

function sort(items, name) {
    return [...items].sort((left, right) => name(left).localeCompare(name(right), language, {numeric: true}));
}

function fill(select, prompt, items, label, groups = []) {
    const chosen = select.value;
    select.replaceChildren(new Option(prompt, ""));
    const add = (parent, entries) => {
        const labels = entries.map(label);
        const counts = new Map();
        for (const name of labels) counts.set(name, (counts.get(name) || 0) + 1);
        entries.forEach((item, index) => {
            const name = labels[index];
            parent.append(new Option(counts.get(name) > 1 ? `${name} (${item.id})` : name, item.id));
        });
    };
    add(select, items);
    for (const [groupLabel, entries] of groups) {
        if (!entries.length) continue;
        const group = document.createElement("optgroup");
        group.label = groupLabel;
        add(group, entries);
        select.append(group);
    }
    if ([...select.options].some((item) => item.value === chosen)) select.value = chosen;
}

function renderScope(selection) {
    const active = activeStates.has(generation.state);
    const selectedClient = clients.find((item) => item.id === clientSelect.value);
    const items = catalogue?.tree || [];
    const divisions = items.filter((item) => item.id.startsWith("ui:"));
    const worlds = items.filter((item) => !item.id.startsWith("ui:"));
    fill(continentSelect, t(catalogue ? "allContinents" : "selectionEmpty"), [], locationName, [
        [t("continentsGroup"), sort(divisions, locationName)], [t("worldsGroup"), sort(worlds, locationName)],
    ]);
    if (selection) continentSelect.value = selection.continent;
    const {continent} = validSelection();
    const areaLabel = (item) => item.trail.map((name) => localized(name)).filter(Boolean).join(" › ") || locationName(item);
    fill(zoneSelect, t(continent ? "allZones" : "chooseContinent"), sort(continent?.zones || [], locationName), locationName);
    if (selection) zoneSelect.value = selection.zone ?? "";
    const {zone} = validSelection();
    fill(areaSelect, t(zone ? "allAreas" : "chooseZone"), sort(zone?.subzones || [], areaLabel), areaLabel);
    if (selection) areaSelect.value = selection.area ?? "";
    clientSelect.disabled = !clients.length || active || actionPending;
    continentSelect.disabled = !catalogue || active || actionPending;
    zoneSelect.disabled = !continent?.zones.length || active || actionPending;
    areaSelect.disabled = !zone?.subzones.length || active || actionPending;
    const meta = get("client-meta");
    meta.textContent = !hasClients ? "" : !selectedClient ? t("noClients") : catalogueLoading ? t("catalogueLoading")
        : catalogue ? t("worldCount", {count: format(catalogue.worlds)}) : "";
    meta.title = selectedClient?.root || "";
    const notice = get("catalogue-error");
    notice.hidden = !catalogueError && !catalogue?.notes.length;
    notice.textContent = catalogueError ? [t(catalogueError.key), catalogueError.detail].filter(Boolean).join(" ") : t("catalogueNote");
    notice.title = catalogueError?.detail || catalogue?.notes.join("\n") || "";
    get("settings").disabled = active || actionPending;
    get("start").disabled = !catalogue || active || actionPending;
    mapSearch.disabled = !catalogue || active || actionPending;
    renderMapSearch();
}

function format(number, options) {
    return new Intl.NumberFormat(language, options).format(number);
}

function duration(seconds) {
    const parts = [Math.floor(seconds / 3600), Math.floor(seconds / 60) % 60, seconds % 60];
    return (parts[0] ? parts : parts.slice(1)).map((part) => String(part).padStart(2, "0")).join(":");
}

function bytes(value) {
    if (value === undefined) return "—";
    const unit = value ? Math.min(4, Math.floor(Math.log(value) / Math.log(1024))) : 0;
    return `${format(value / 1024 ** unit, {maximumFractionDigits: unit ? 1 : 0})} ${translations[language].sizes[unit]}`;
}

function renderMonitor() {
    const job = generation;
    const active = activeStates.has(job.state);
    const {continent, zone, area} = validSelection();
    const names = job.current?.trail || (job.state !== "idle" ? job.scope : []);
    const trail = names?.map((name) => localized(name)).filter(Boolean);
    const selection = [
        continent ? locationName(continent) : t("allContinents"),
        zone ? locationName(zone) : t("allZones"),
        ...(area ? area.trail.map((name) => localized(name)).filter(Boolean) : [t("allAreas")]),
    ];
    const path = trail?.length ? [...trail] : selection;
    if (trail?.length) {
        if (path.length < 2) path.push(t("allZones"));
        if (path.length < 3) path.push(t("allAreas"));
    }
    get("trail").replaceChildren(...path.map((name, index) => {
        const item = document.createElement("li");
        const level = document.createElement("span");
        level.textContent = t(["continent", "zone", "area"][Math.min(index, 2)]);
        const value = document.createElement("strong");
        value.textContent = name;
        item.append(level, value);
        return item;
    }));
    const state = get("job-state");
    state.dataset.state = job.state;
    state.textContent = t(job.state);
    get("phase").textContent = t(job.phase || "ready");
    const indeterminate = job.state === "running" && !job.progress && ["planning", "preparing"].includes(job.phase);
    if (indeterminate) get("progress").removeAttribute("value");
    else get("progress").value = job.progress || 0;
    get("percent").textContent = indeterminate ? "—" : format(job.progress || 0, {style: "percent", maximumFractionDigits: 1});
    const current = job.current;
    get("tile").textContent = current ? [
        t("world", {id: current.world}),
        current.tile && t("tile", {id: current.tile}),
        current.expected > 0 && t("tileCount", {done: format(current.files), total: format(current.expected)}),
    ].filter(Boolean).join(" · ") : "";
    get("elapsed").textContent = duration(job.elapsed || 0);
    get("eta").textContent = job.state === "complete" ? duration(0) : job.eta == null ? "—" : duration(job.eta);
    get("temporary").textContent = bytes(job.workBytes);
    get("pack-size").textContent = bytes(job.packBytes);
    if (job.freeBytes !== undefined) get("temporary").title = t("free", {size: bytes(job.freeBytes)});
    get("summary").textContent = job.total ? [
        t("worldsDone", {done: format(job.done), total: format(job.total)}),
        t("tilesDone", {count: format(job.tiles)}),
        job.failed && t("failures", {count: format(job.failed)}),
        job.partial && t("partials", {count: format(job.partial)}),
        job.excludedTiles && t("excludedTiles", {count: format(job.excludedTiles)}),
    ].filter(Boolean).join(" · ") : "";
    get("pause").textContent = t(["pausing", "paused"].includes(job.state) ? "resume" : "pause");
    get("pause").disabled = !active || actionPending;
    const retry = get("retry");
    retry.hidden = active || !job.retryMaps || job.client !== clientSelect.value;
    retry.disabled = actionPending;
    retry.textContent = t("retryMaps", {count: format(job.retryMaps || 0)});
    get("download-log").hidden = !job.logReady;
    get("download-report").hidden = !job.reportReady;
    get("pause-help").hidden = !active;
    get("output").hidden = !job.output;
    get("output-path").textContent = job.output || "";
    const error = get("job-error");
    error.hidden = !(actionError || job.error);
    error.textContent = [t(actionError?.key || "jobError"), actionError?.detail || job.error].filter(Boolean).join(" ");
    error.title = actionError?.detail || job.error || "";
    const logs = get("logs");
    const previous = logs.scrollHeight - logs.scrollTop - logs.clientHeight;
    if (job.logs || !active || !logs.textContent) {
        logs.textContent = job.logs?.length ? job.logs.join("\n") : t("noLogs");
        if (previous < 20) logs.scrollTop = logs.scrollHeight;
    }
}

function renderLanguage() {
    document.documentElement.lang = language;
    document.title = `APR Terrain · ${t("title")}`;
    mapSearch.placeholder = t("mapSearchPlaceholder");
    document.querySelectorAll("[data-copy]").forEach((node) => { node.textContent = t(node.dataset.copy); });
    document.querySelectorAll("[data-label]").forEach((node) => node.setAttribute("aria-label", t(node.dataset.label)));
    document.querySelectorAll("[data-lang]").forEach((node) => node.setAttribute("aria-pressed", node.dataset.lang === language));
    const existing = clientSelect.value;
    const label = (item) => {
        const product = products[item.product];
        return `${typeof product === "string" ? product : localized(product, item.product)} · ${item.build}`;
    };
    fill(clientSelect, hasClients && !clients.length ? t("noClients") : t("clientEmpty"), clients, label);
    if (!existing && clients.length) clientSelect.value = clients[0].id;
    if (clients.length) clientSelect.options[0].hidden = true;
    renderScope();
    renderMonitor();
}

async function request(path, payload) {
    const response = await fetch(path, payload === undefined ? {} : {
        method: "POST", headers: {"Content-Type": "application/json"}, body: JSON.stringify(payload),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error);
    return result;
}

async function changeClient() {
    const requestId = ++catalogueRequest;
    catalogue = null;
    searchableMaps = [];
    mapSearch.value = "";
    catalogueError = null;
    catalogueLoading = !!clientSelect.value;
    renderScope();
    renderMonitor();
    if (!catalogueLoading) return;
    try {
        const result = await request(`/api/catalogue?client=${encodeURIComponent(clientSelect.value)}`);
        if (requestId === catalogueRequest) {
            catalogue = result;
            searchableMaps = indexMaps(result.tree);
        }
    } catch (error) {
        if (requestId === catalogueRequest) catalogueError = {key: "catalogueError", detail: error.message};
    } finally {
        if (requestId === catalogueRequest) {
            catalogueLoading = false;
            renderScope();
            renderMonitor();
        }
    }
}

function resetSettings() {
    for (const field of fields) {
        const value = defaults[field.dataset.setting];
        if (field.type === "checkbox") field.checked = value;
        else field.value = value;
    }
}

async function refresh() {
    if (actionPending) return;
    const requestId = ++statusRequest;
    try {
        const next = await request(`/api/status?logs=${logsSection.open ? 1 : 0}`);
        if (requestId !== statusRequest) return;
        const stateChanged = next.state !== generation.state;
        generation = next;
        if (actionError?.key === "requestError") actionError = null;
        if (stateChanged) renderScope();
        renderMonitor();
    } catch (error) {
        if (requestId !== statusRequest) return;
        actionError = {key: "requestError", detail: error.message};
        renderMonitor();
    }
}

async function action(path, payload) {
    if (actionPending) return;
    statusRequest++;
    actionPending = true;
    actionError = null;
    renderScope();
    renderMonitor();
    try {
        generation = await request(path, payload);
        if ((path === "/api/start" || path === "/api/retry") && window.matchMedia("(max-width: 690px)").matches) {
            get("monitor-title").scrollIntoView({block: "start"});
        }
    } catch (error) {
        actionError = {key: "jobError", detail: error.message};
    } finally {
        actionPending = false;
        renderScope();
        renderMonitor();
    }
}

document.querySelectorAll("[data-lang]").forEach((button) => button.addEventListener("click", () => {
    language = button.dataset.lang;
    localStorage.setItem("aprTerrainLanguage", language);
    renderLanguage();
}));
clientSelect.addEventListener("change", changeClient);
mapSearch.addEventListener("input", renderMapSearch);
mapSearch.addEventListener("keydown", (event) => {
    if (event.isComposing) return;
    const first = mapResults.querySelector("button");
    if (event.key === "Enter") {
        event.preventDefault();
        first?.click();
    } else if (event.key === "ArrowDown" && first) {
        event.preventDefault();
        first.focus();
    }
});
mapResults.addEventListener("keydown", (event) => {
    const row = event.target.closest("li");
    if (!row || event.isComposing) return;
    if (event.key === "Enter") {
        event.preventDefault();
        row.firstElementChild.click();
    } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
        event.preventDefault();
        const neighbor = event.key === "ArrowDown" ? row.nextElementSibling : row.previousElementSibling;
        if (neighbor) neighbor.firstElementChild.focus();
        else if (event.key === "ArrowUp") mapSearch.focus();
    } else if (event.key === "Escape") {
        mapSearch.value = "";
        renderMapSearch();
        mapSearch.focus({preventScroll: true});
    }
});
continentSelect.addEventListener("change", () => {
    zoneSelect.value = "";
    areaSelect.value = "";
    renderScope();
    renderMonitor();
});
zoneSelect.addEventListener("change", () => {
    areaSelect.value = "";
    renderScope();
    renderMonitor();
});
areaSelect.addEventListener("change", renderMonitor);
get("reset").addEventListener("click", resetSettings);
get("configuration").addEventListener("submit", (event) => {
    event.preventDefault();
    const selected = validSelection();
    const settings = Object.fromEntries(fields.map((field) => [field.dataset.setting,
        field.type === "checkbox" ? field.checked : Number(field.value)]));
    if (settings.roadWeak > settings.roadThreshold) {
        actionError = {key: "invalidRoad"};
        renderMonitor();
        return;
    }
    action("/api/start", {client: clientSelect.value, scope: {
        continent: selected.continent?.id ?? null, zone: selected.zone?.id ?? null, area: selected.area?.id ?? null,
    }, options: settings});
});
get("pause").addEventListener("click", () => action(
    ["pausing", "paused"].includes(generation.state) ? "/api/resume" : "/api/pause", {},
));
get("retry").addEventListener("click", () => action("/api/retry", {}));
logsSection.addEventListener("toggle", refresh);
get("copy").addEventListener("click", async () => {
    try {
        await navigator.clipboard.writeText(generation.output);
        get("copy").textContent = t("copied");
        setTimeout(() => { get("copy").textContent = t("copy"); }, 1500);
    } catch {
        get("copy").textContent = t("copyError");
    }
});

async function initialize() {
    renderLanguage();
    try {
        const response = await request("/api/clients");
        clients = response.clients;
        defaults = response.defaults;
        hasClients = true;
        get("threads").max = response.cpu;
        fields.filter((field) => field.type === "number").forEach((field) => { field.required = true; });
        resetSettings();
        renderLanguage();
        changeClient();
    } catch (error) {
        catalogueError = {key: "requestError", detail: error.message};
        renderScope();
    }
    async function poll() {
        await refresh();
        setTimeout(poll, 850);
    }
    poll();
}

initialize();
