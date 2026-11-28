-- Read-only configuration for group features. Runtime state stays with the owning module.
APR.GroupConstants = {
    -- Party row layout and snapshot transport limits.
    Party = {
        FRAME_WIDTH = 250,
        MIN_ROW_HEIGHT = 40,
        ROW_PADDING = 6,
        ROW_TEXT_GAP = 2,
        MAX_FRAGMENT_COUNT = 128, -- Bound an incomplete group snapshot to 23 KiB.
        GROUP_SEND_THROTTLE = 2,
        GROUP_SEND_COALESCE = 0.5,
        GROUP_REQUEST_THROTTLE = 5,
        MAX_OUTGOING_BYTES = 2048, -- Optional tooltip rows never grow the progression stream beyond 2 KiB.
        MAX_TOOLTIP_ROWS = 128,
        MAX_PENDING_MESSAGES = 80, -- Two snapshots per raid member, at most.
        FRAGMENT_TTL = 10,
        FRAGMENT_SWEEP_INTERVAL = 5,
        TOOLTIP_FIELDS = { "extraLines", "questSteps" },
    },

    -- Shared discovery prefix and query, cache and presentation settings.
    PartyFinder = {
        PREFIX = "APRFindV1",
        ZERO = "00000000",
        CACHE_TTL = 120,
        REQUEST_LIMIT = 200,
        QUERY_INTERVAL = 30,
        QUERY_TTL = 10,
        RESPONSE_INTERVAL = 30,
        AUTO_QUERY_INTERVAL = 60,
        AUTO_QUERY_QUIET = 30,
        RESPONSE_PACE = 5,
        PRESENTATION_OPTIONS = { showButton = true, showBadge = true },
        ALERT_OPTIONS = { notifications = true, notificationCooldown = true, soundEnabled = true, soundChannel = true },
        PROGRESS_KEYS = {
            same = "GROUP_SYNCED",
            ahead = "GROUP_STEPS_AHEAD",
            behind = "GROUP_STEPS_BEHIND",
            different = "GROUP_DIFFERENT_STEP",
            other = "GROUP_OTHER_ROUTE",
            unknown = "GROUP_SYNC_UNAVAILABLE",
        },
    },

    -- Private packet limit.
    PartyFinderDirect = {
        LIMIT = 32,
    },

    -- Friend discovery limits and pacing.
    PartyFinderFriends = {
        ROSTER_LIMIT = 512,
        ACCOUNT_LIMIT = 8,
        PEER_LIMIT = 512,
        SEARCH_LIMIT = 32,
        QUEUE_LIMIT = 128,
        SEND_INTERVAL = 0.125,
        SEARCH_FIELDS = {
            "context",
            "alternateContext",
            "route",
            "revision",
            "progressId",
            "step",
            "total",
            "mode",
            "range",
            "minLevel",
            "maxLevel",
            "primary",
            "languages",
            "warMode",
            "showIncompatibleWarMode",
        },
    },

    -- Invite reporting actions.
    PartyFinderInvites = {
        EMPTY_SOUND_CATALOG = {},
        INVITE_DIALOG_ACTIONS = { LFGInvitePopupAcceptButton = "accepted", LFGInvitePopupDeclineButton = "declined" },
    },

    -- Wire bounds and supported locales.
    PartyFinderProtocol = {
        MODULO = 4294967296,
        MAX_PROGRESS = 1000000,
        languages = { "en", "fr", "de", "es", "pt", "it", "ru", "ko", "zhCN", "zhTW" },
        languageInfo = {
            en = "enUS",
            fr = "frFR",
            de = "deDE",
            es = "esES",
            pt = "ptBR",
            it = "itIT",
            ru = "ruRU",
            ko = "koKR",
            zhCN = "zhCN",
            zhTW = "zhTW",
        },
        languageFlags = {
            en = "gb",
            fr = "fr",
            de = "de",
            es = "es",
            pt = "pt",
            it = "it",
            ru = "ru",
            ko = "kr",
            zhCN = "cn",
            zhTW = "tw",
        },
        localeLanguages = {
            en = "en",
            enus = "en",
            engb = "en",
            fr = "fr",
            frfr = "fr",
            de = "de",
            dede = "de",
            es = "es",
            eses = "es",
            esmx = "es",
            pt = "pt",
            ptbr = "pt",
            ptpt = "pt",
            it = "it",
            itit = "it",
            ru = "ru",
            ruru = "ru",
            ko = "ko",
            kokr = "ko",
            zhcn = "zhCN",
            zhtw = "zhTW",
            ["zh-hans"] = "zhCN",
            ["zh-hant"] = "zhTW",
        },
    },

    -- Progression payload bounds and field names.
    PartyProtocol = {
        MAX_INDEX = 1000000,
        MAX_ROWS = 128,
        ROUTE_FIELDS = { "route", "routeFileName" },
        PROGRESS_FIELDS = { "index", "step", "total" },
        DETAIL_FIELDS = { "extraLines", "questSteps", "fillerSteps" },
    },
}
