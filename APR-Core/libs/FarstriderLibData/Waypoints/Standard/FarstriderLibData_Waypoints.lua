-- FarstriderLibData_Waypoints.lua
local _, FarstriderLibData = ...

if not FarstriderLibData.Internal then return end

local squishLookup = {
  [1] = 1,
  [2] = 2,
  [3] = 2,
  [4] = 2,
  [5] = 3,
  [6] = 3,
  [7] = 3,
  [8] = 4,
  [9] = 4,
  [10] = 5,
  [11] = 5,
  [12] = 6,
  [13] = 6,
  [14] = 7,
  [15] = 7,
  [16] = 8,
  [17] = 8,
  [18] = 9,
  [19] = 9,
  [20] = 10,
  [21] = 10,
  [22] = 10,
  [23] = 11,
  [24] = 11,
  [25] = 11,
  [26] = 12,
  [27] = 12,
  [28] = 12,
  [29] = 13,
  [30] = 13,
  [31] = 13,
  [32] = 14,
  [33] = 14,
  [34] = 14,
  [35] = 15,
  [36] = 15,
  [37] = 16,
  [38] = 16,
  [39] = 17,
  [40] = 17,
  [41] = 18,
  [42] = 18,
  [43] = 19,
  [44] = 19,
  [45] = 20,
  [46] = 20,
  [47] = 20,
  [48] = 21,
  [49] = 21,
  [51] = 22,
  [52] = 22,
  [53] = 22,
  [54] = 23,
  [55] = 23,
  [56] = 23,
  [57] = 24,
  [58] = 24,
  [59] = 24,
  [60] = 25,
  [61] = 25,
  [62] = 25,
  [63] = 25,
  [64] = 26,
  [65] = 26,
  [66] = 26,
  [67] = 26,
  [68] = 27,
  [69] = 27,
  [70] = 27,
  [71] = 27,
  [72] = 28,
  [73] = 28,
  [74] = 28,
  [75] = 28,
  [76] = 29,
  [77] = 29,
  [78] = 29,
  [79] = 29,
  [80] = 30,
  [81] = 30,
  [82] = 31,
  [83] = 31,
  [84] = 32,
  [85] = 32,
  [86] = 33,
  [87] = 33,
  [88] = 34,
  [89] = 34,
  [90] = 35,
  [91] = 35,
  [92] = 36,
  [93] = 36,
  [94] = 37,
  [95] = 37,
  [96] = 38,
  [97] = 38,
  [98] = 39,
  [99] = 39,
  [100] = 40,
  [101] = 40,
  [102] = 41,
  [103] = 41,
  [104] = 42,
  [105] = 42,
  [106] = 43,
  [107] = 43,
  [108] = 44,
  [109] = 44,
  [110] = 45,
  [111] = 45,
  [112] = 46,
  [113] = 46,
  [114] = 47,
  [115] = 47,
  [116] = 48,
  [117] = 48,
  [118] = 49,
  [119] = 49,
  [120] = 50,
}

---@param level number
---@return integer correctedLevel
local function GetCorrectedLevel(level)
  if GetExpansionLevel() >= 8 then
    return squishLookup[level] or level
  end

  return level
end

---@type Waypoint[]
local waypoints = {
  {
    id = 4,
    from = {
      locaId = 26,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = -311.70999145508,
          y = -1776.8199462891,
          z = 62.6702003479
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 5,
    from = {
      locaId = 6,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9005.400390625,
          y = 928.81500244141,
          z = 68.08239746094
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    to = {
      locaId = 7,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = -307.16000366211,
          y = -1772.8900146484,
          z = 62.24110031128
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 6,
    from = {
      locaId = 10,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8233.009765625,
          y = 415.66799926758,
          z = 118.04399871826
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 16,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -9443.3095703125,
          y = -958.35998535156,
          z = 111.01000213623
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 7,
    from = {
      locaId = 11,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8212.4296875,
          y = 399.02398681641,
          z = 117.63600158691
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(80)) and (GetExpansionLevel() >= 3) end,
      important = true
    },
    to = {
      locaId = 17,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 5534.080078125,
          y = -3624.6899414062,
          z = 1567.0400390625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 8,
    from = {
      locaId = 12,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8186.1499023438,
          y = 413.64599609375,
          z = 117.1129989624
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(84)) and (UnitLevel("player") <= GetCorrectedLevel(255)) and (GetExpansionLevel() >= 3) end,
      important = true
    },
    to = {
      locaId = 20,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4890.0698242188,
          y = -6626.740234375,
          z = 10.28460025787
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 9,
    from = {
      locaId = 13,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8191.0200195312,
          y = 449.61999511719,
          z = 116.81099700928
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (GetExpansionLevel() >= 3) and (C_QuestLog.IsQuestFlaggedCompleted(14482)) end,
      important = true
    },
    to = {
      locaId = 21,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4454.7700195312,
          y = 3806.1298828125,
          z = -82.45909881592
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 10,
    from = {
      locaId = 14,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8208.73046875,
          y = 451.0299987793,
          z = 117.6549987793
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 22,
      flags = 0,
      loc = {
        mapId = 732,
        pos = {
          x = -369.2080078125,
          y = 1058.7299804688,
          z = 21.771900177
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 11,
    from = {
      locaId = 18,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 5541.509765625,
          y = -3587.830078125,
          z = 1567.9300537109
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 19,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8209.330078125,
          y = 428.63500976563,
          z = 117.46499633789
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 12,
    from = {
      locaId = 23,
      flags = 0,
      loc = {
        mapId = 732,
        pos = {
          x = -343.93399047852,
          y = 1030.0200195312,
          z = 22.28809928894
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 19,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8209.330078125,
          y = 428.63500976563,
          z = 117.46499633789
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 13,
    from = {
      locaId = 15,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8223.4296875,
          y = 451.32598876953,
          z = 117.46399688721
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(82)) end,
      important = true
    },
    to = {
      locaId = 24,
      flags = 0,
      loc = {
        mapId = 646,
        pos = {
          x = 974.92102050781,
          y = 566.76800537109,
          z = -47.51630020142
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 14,
    from = {
      locaId = 25,
      flags = 0,
      loc = {
        mapId = 646,
        pos = {
          x = 965.33697509766,
          y = 577.083984375,
          z = -44.26079940796
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 19,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8209.330078125,
          y = 428.63500976563,
          z = 117.46499633789
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 15,
    from = {
      locaId = 36,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -275.21899414063,
          y = 931.87298583984,
          z = 84.37999725342
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 18,
    from = {
      locaId = 30,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9005.9599609375,
          y = 965.13500976563,
          z = 68.22290039063
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 31,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -4031.2399902344,
          y = -11569.599609375,
          z = -138.29899597168
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 19,
    from = {
      locaId = 29,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 5718.9501953125,
          y = 719.59997558594,
          z = 641.72698974609
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 20,
    from = {
      locaId = 27,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9023.4599609375,
          y = 952.32598876953,
          z = 68.33709716797
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(58)) end,
      important = true
    },
    to = {
      locaId = 28,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 5807.75,
          y = 588.34997558594,
          z = 660.94000244141
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 21,
    from = {
      locaId = 37,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -8988.7001953125,
          y = 942.4580078125,
          z = 68.13189697266
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(58)) end,
      important = true
    },
    to = {
      locaId = 38,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1824.3199462891,
          y = 5417.2299804688,
          z = -12.43000030518
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 22,
    from = {
      locaId = 39,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1839.9200439453,
          y = 5500.7900390625,
          z = -12.42720031738
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 40,
      flags = 0,
      loc = {
        mapId = 122,
        pos = {
          x = 0.482494,
          y = 0.344811,
          z = 0
        },
        isUI = true
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 23,
    from = {
      locaId = 41,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1894.2399902344,
          y = 5387.8500976562,
          z = -12.42669963837
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 24,
    from = {
      locaId = 9,
      flags = 16,
      loc = {
        mapId = 0,
        pos = {
          x = -9016.9404296875,
          y = 877.29400634766,
          z = 148.6190032959
        }
      },
      type = 0,
      unknown1 = 0,
      uiMapHint = 1519,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 0,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 26,
    from = {
      locaId = 42,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9036.23046875,
          y = 1004.5300292969,
          z = 73.93900299072
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) end,
      important = true
    },
    to = {
      locaId = 43,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 3841.7199707031,
          y = -4013.7700195312,
          z = 26.71789932251
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 29,
    from = {
      locaId = 47,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 3734.9499511719,
          y = -4042.9099121094,
          z = 44.81859970093
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 30,
    from = {
      locaId = 48,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9053.8603515625,
          y = 991.80499267578,
          z = 73.99990081787
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    to = {
      locaId = 49,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -13.49310016632,
          y = 6756.6098632812,
          z = 53.51350021362
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 31,
    from = {
      locaId = 50,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -13.54139995575,
          y = 6756.7299804688,
          z = 53.5152015686
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 32,
    from = {
      locaId = 51,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9068.580078125,
          y = 1011.8800048828,
          z = 73.59269714355
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    to = {
      locaId = 52,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 728.16802978516,
          y = -445.57400512695,
          z = 14.94540023804
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 34,
    from = {
      locaId = 53,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -930.14898681641,
          y = 4547.7202148438,
          z = 729.22998046875
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 35,
    from = {
      locaId = 54,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = 828.24102783203,
          y = 176.80499267578,
          z = 519.93499755859
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 39,
    from = {
      locaId = 61,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1132.5300292969,
          y = -524.58801269531,
          z = 17.53420066834
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(110)) end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 40,
    from = {
      locaId = 62,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1154.1999511719,
          y = -529.19799804688,
          z = 17.69449996948
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(110)) end,
      important = true
    },
    to = {
      locaId = 31,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -4031.2399902344,
          y = -11569.599609375,
          z = -138.29899597168
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 41,
    from = {
      locaId = 63,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1149.6500244141,
          y = -538.03497314453,
          z = 17.69459915161
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(110)) end,
      important = true
    },
    to = {
      locaId = 46,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4613.7099609375,
          y = -915.28698730469,
          z = 501.06201171875
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 42,
    from = {
      locaId = 64,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8646.23046875,
          y = 1331.6300048828,
          z = 5.69915008545
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 165,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1020.5599975586,
          y = -659.00701904297,
          z = 6.48783016205
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 43,
    from = {
      locaId = 66,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8293.919921875,
          y = 1405.7099609375,
          z = 4.4330701828
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 67,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 2230.9899902344,
          y = 5130.7700195312,
          z = 5.34427976608
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 44,
    from = {
      locaId = 68,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -3863.5700683594,
          y = -652.81097412109,
          z = 5.42934989929
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 69,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -4005.5500488281,
          y = -4729.66015625,
          z = 4.72207021713
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 45,
    from = {
      locaId = 70,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -3684.8798828125,
          y = -600.22698974609,
          z = 4.35799980164
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 71,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 589.74597167969,
          y = -5103.83984375,
          z = 5.2604598999
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 46,
    from = {
      locaId = 72,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -14284.5,
          y = 557.97900390625,
          z = 8.68416976929
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 73,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -996.90600585938,
          y = -3829.7700195312,
          z = 5.59738016129
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 47,
    from = {
      locaId = 74,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 2836.4099121094,
          y = 4022.5600585938,
          z = 4.87723016739
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 75,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 2629.9099121094,
          y = 938.416015625,
          z = 4.63339996338
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = true,
    cost = 60,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 48,
    from = {
      locaId = 76,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 2642.0500488281,
          y = 844.01501464844,
          z = 4.5511598587
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 77,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 787.65399169922,
          y = -2816.8701171875,
          z = 4.56562995911
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = true,
    cost = 60,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 51,
    from = {
      locaId = 82,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = 2123.5700683594,
          y = 186.53999328613,
          z = 0.48722600937
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 81,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1009.7299804688,
          y = -526.26000976563,
          z = 13.10000038147
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 52,
    from = {
      locaId = 83,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2628.080078125,
          y = 2285.8798828125,
          z = 12.35229969025
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 81,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1009.7299804688,
          y = -526.26000976563,
          z = 13.10000038147
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 53,
    from = {
      locaId = 84,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = 2804.0900878906,
          y = 4311.3798828125,
          z = 19.04949951172
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 81,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1009.7299804688,
          y = -526.26000976563,
          z = 13.10000038147
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 54,
    from = {
      locaId = 90,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -247.29499816895,
          y = 895.95098876953,
          z = 84.34970092773
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 91,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 55,
    from = {
      locaId = 92,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 89,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -248.1130065918,
          y = 922.90002441406,
          z = 84.34970092773
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 56,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 86,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 3667.8000488281,
          y = -3843,
          z = 44.13999938965
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(34586) or C_QuestLog.IsQuestFlaggedCompleted(34378))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 57,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 86,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 3667.8000488281,
          y = -3843,
          z = 44.13999938965
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(34586) or C_QuestLog.IsQuestFlaggedCompleted(34378))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 58,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 87,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 2308.5700683594,
          y = 447.4700012207,
          z = 5.11999988556
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 59,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 87,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 2308.5700683594,
          y = 447.4700012207,
          z = 5.11999988556
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") and ((C_QuestLog.IsQuestFlaggedCompleted(35884) or C_QuestLog.IsQuestFlaggedCompleted(34446))) end
  },
  {
    id = 60,
    from = {
      locaId = 280,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 88,
      flags = 0,
      loc = {
        mapId = 1265,
        pos = {
          x = 4066.5,
          y = -2382.25,
          z = 94.84999847412
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 61,
    from = {
      locaId = 93,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 500.28100585938,
          y = 1469.6800537109,
          z = 742.44201660156
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 96,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -828.71997070313,
          y = 4371.7797851562,
          z = 738.63598632813
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 62,
    from = {
      locaId = 94,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 4727.4501953125,
          y = 9862.25,
          z = 40.93470001221
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 96,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -828.71997070313,
          y = 4371.7797851562,
          z = 738.63598632813
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 63,
    from = {
      locaId = 95,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = -2635.6398925781,
          y = 8698.669921875,
          z = -94.17440032959
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 96,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -828.71997070313,
          y = 4371.7797851562,
          z = 738.63598632813
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 66,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 42,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9036.23046875,
          y = 1004.5300292969,
          z = 73.93900299072
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) end,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 67,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 48,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9053.8603515625,
          y = 991.80499267578,
          z = 73.99990081787
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 68,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 51,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9068.580078125,
          y = 1011.8800048828,
          z = 73.59269714355
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 69,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 27,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9023.4599609375,
          y = 952.32598876953,
          z = 68.33709716797
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(58)) end,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 70,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 6,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9005.400390625,
          y = 928.81500244141,
          z = 68.08239746094
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 71,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 37,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -8988.7001953125,
          y = 942.4580078125,
          z = 68.13189697266
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(58)) end,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 72,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 30,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9005.9599609375,
          y = 965.13500976563,
          z = 68.22290039063
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 74,
    from = {
      locaId = 99,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2042.7199707031,
          y = -4395.740234375,
          z = 98.2991027832
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(80)) and (GetExpansionLevel() >= 3) end,
      important = true
    },
    to = {
      locaId = 17,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 5534.080078125,
          y = -3624.6899414062,
          z = 1567.0400390625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 75,
    from = {
      locaId = 100,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 5503.9501953125,
          y = -3624.5700683594,
          z = 1567.3800048828
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 76,
    from = {
      locaId = 102,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2065.919921875,
          y = -4390.91015625,
          z = 98.06620025635
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(82)) end,
      important = true
    },
    to = {
      locaId = 103,
      flags = 0,
      loc = {
        mapId = 646,
        pos = {
          x = 995.80798339844,
          y = 471.87899780273,
          z = -48.11719894409
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 77,
    from = {
      locaId = 104,
      flags = 0,
      loc = {
        mapId = 646,
        pos = {
          x = 990.41900634766,
          y = 454.3210144043,
          z = -44.24729919434
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 78,
    from = {
      locaId = 105,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2029.2800292969,
          y = -4379.7900390625,
          z = 98.38189697266
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(84)) and (UnitLevel("player") <= GetCorrectedLevel(255)) and (GetExpansionLevel() >= 3) end,
      important = true
    },
    to = {
      locaId = 106,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4032.7900390625,
          y = -6318.5297851562,
          z = 37.87910079956
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 79,
    from = {
      locaId = 107,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4038.3898925781,
          y = -6314.7797851562,
          z = 38.70640182495
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(26798)) end,
      important = true
    },
    to = {
      locaId = 108,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2047.3299560547,
          y = -4378.3901367188,
          z = 99.0858001709
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 80,
    from = {
      locaId = 109,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2039.4399414062,
          y = -4356.2299804688,
          z = 98.61560058594
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 16,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -9443.3095703125,
          y = -958.35998535156,
          z = 111.01000213623
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 81,
    from = {
      locaId = 110,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2063.4099121094,
          y = -4362.2001953125,
          z = 98.06020355225
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (GetExpansionLevel() >= 3) and (C_QuestLog.IsQuestFlaggedCompleted(25924)) end,
      important = true
    },
    to = {
      locaId = 111,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4609.1801757812,
          y = 3982.5400390625,
          z = -70.79720306396
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 82,
    from = {
      locaId = 112,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2031.1600341797,
          y = -4330.4702148438,
          z = 95.47160339355
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 113,
      flags = 0,
      loc = {
        mapId = 732,
        pos = {
          x = -603.72399902344,
          y = 1387.6199951172,
          z = 21.53840065002
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 83,
    from = {
      locaId = 114,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2031.1600341797,
          y = -4330.4702148438,
          z = 95.47160339355
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 108,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 2047.3299560547,
          y = -4378.3901367188,
          z = 99.0858001709
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 84,
    from = {
      locaId = 115,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1438.9399414062,
          y = -4456.490234375,
          z = -2.86433005333
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 116,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 9998.4599609375,
          y = -7106.5498046875,
          z = 47.70539855957
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 110,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 85,
    from = {
      locaId = 117,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 10003.299804688,
          y = -7109.8701171875,
          z = 47.70539855957
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 110,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 86,
    from = {
      locaId = 118,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 10032.299804688,
          y = -7000.330078125,
          z = 61.71269989014
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 110,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 119,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 1947.2600097656,
          y = -98.15000152588,
          z = 41.14670181274
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 87,
    from = {
      locaId = 120,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1424.0899658203,
          y = -4506.419921875,
          z = -3.07801008224
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(58)) end,
      important = true
    },
    to = {
      locaId = 38,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1824.3199462891,
          y = 5417.2299804688,
          z = -12.43000030518
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 88,
    from = {
      locaId = 121,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1899.6800537109,
          y = 5392.7299804688,
          z = -12.42640018463
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 89,
    from = {
      locaId = 122,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1420.0400390625,
          y = -4466.6401367188,
          z = -2.94770002365
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) end,
      important = true
    },
    to = {
      locaId = 123,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 5276.3999023438,
          y = -4045.2399902344,
          z = 19.57999992371
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 90,
    from = {
      locaId = 124,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 3719.6599121094,
          y = -3875.169921875,
          z = 30.72120094299
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(37969) or C_QuestLog.IsQuestFlaggedCompleted(38433))) end,
      important = true
    },
    to = {
      locaId = 125,
      flags = 0,
      loc = {
        mapId = 1464,
        pos = {
          x = 3816.8000488281,
          y = -1307.7099609375,
          z = 92.7799987793
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(37969) or C_QuestLog.IsQuestFlaggedCompleted(38433))) end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 91,
    from = {
      locaId = 126,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 5266.3999023438,
          y = -4075.8898925781,
          z = 21.13019943237
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 92,
    from = {
      locaId = 128,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 5307.6000976562,
          y = -4014.7900390625,
          z = 15.84570026398
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(37969)) end,
      important = true
    },
    to = {
      locaId = 127,
      flags = 0,
      loc = {
        mapId = 1464,
        pos = {
          x = 4276.1801757812,
          y = -1495.5699462891,
          z = 80.84349822998
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and ((C_QuestLog.IsQuestFlaggedCompleted(37969) or C_QuestLog.IsQuestFlaggedCompleted(38433))) end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 93,
    from = {
      locaId = 129,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1463.1400146484,
          y = -4501.3901367188,
          z = -2.95267009735
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 131,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -8.19145965576,
          y = 6756.2797851562,
          z = 53.83409881592
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 94,
    from = {
      locaId = 130,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -8.19145965576,
          y = 6756.2797851562,
          z = 53.83409881592
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 95,
    from = {
      locaId = 132,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1444.8800048828,
          y = -4512.0698242188,
          z = -3.08709001541
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 133,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1128.3900146484,
          y = 771.86602783203,
          z = 433.38598632813
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 96,
    from = {
      locaId = 134,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1114.6600341797,
          y = 759.44396972656,
          z = 433.62399291992
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 116,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 9998.4599609375,
          y = -7106.5498046875,
          z = 47.70539855957
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 110,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 97,
    from = {
      locaId = 135,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1123.9499511719,
          y = 759.76000976563,
          z = 433.62298583984
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(46931)) end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 98,
    from = {
      locaId = 136,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1132.9300537109,
          y = 759.64300537109,
          z = 433.62298583984
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 137,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -967.375,
          y = 284.82000732422,
          z = 110.77300262451
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 99,
    from = {
      locaId = 138,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1142.6500244141,
          y = 760.22399902344,
          z = 433.62298583984
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(120)) end,
      important = true
    },
    to = {
      locaId = 195,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -7096.169921875,
          y = 1294.5799560547,
          z = -93.40570068359
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 100,
    from = {
      locaId = 140,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1416.8100585938,
          y = -4505.9399414062,
          z = 19.84810066223
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 141,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = 2999.4099121094,
          y = -539.19897460938,
          z = 248.21299743652
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 101,
    from = {
      locaId = 142,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = 2999.4099121094,
          y = -539.19897460938,
          z = 248.21299743652
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 102,
    from = {
      locaId = 143,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = 1735.1600341797,
          y = 873.49298095703,
          z = 487.44400024414
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 103,
    from = {
      locaId = 144,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1423.1600341797,
          y = -4484.6201171875,
          z = 20.15740013123
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(58)) end,
      important = true
    },
    to = {
      locaId = 145,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 5807.75,
          y = 588.34997558594,
          z = 660.94000244141
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 104,
    from = {
      locaId = 146,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 5925.7900390625,
          y = 593.60400390625,
          z = 640.59301757813
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 105,
    from = {
      locaId = 147,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1842.1899414062,
          y = -4389.0400390625,
          z = 135.23300170898
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 119,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 1947.2600097656,
          y = -98.15000152588,
          z = 41.14670181274
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 106,
    from = {
      locaId = 148,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1871.0200195312,
          y = -4419.9399414062,
          z = 135.23300170898
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 149,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -12451.599609375,
          y = 219.81900024414,
          z = 31.6515007019
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 107,
    from = {
      locaId = 150,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1764.4000244141,
          y = -4285.9702148438,
          z = 133.10699462891
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 151,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 2837.0900878906,
          y = 6184.83984375,
          z = 121.99099731445
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 108,
    from = {
      locaId = 152,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -221.66900634766,
          y = 931.34997558594,
          z = 84.37999725342
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 109,
    from = {
      locaId = 351,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1842.1899414062,
          y = -4389.0400390625,
          z = 135.23300170898
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 352,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1805,
          y = 327,
          z = 70.5
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 110,
    from = {
      locaId = 154,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 1966.3900146484,
          y = 66.29170227051,
          z = 108.91999816895
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_Garrison.GetGarrisonInfo(Enum.GarrisonType.Type_6_0_Garrison) and C_Garrison.GetGarrisonInfo(Enum.GarrisonType.Type_6_0_Garrison) >= 3) and (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 43,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 3841.7199707031,
          y = -4013.7700195312,
          z = 26.71789932251
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 111,
    from = {
      locaId = 156,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = -393.53601074219,
          y = 4121.9599609375,
          z = 1.34221994877
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    to = {
      locaId = 155,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2146.6398925781,
          y = 766.86999511719,
          z = 14.26000022888
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 112,
    from = {
      locaId = 157,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = -218.90600585938,
          y = -1527.75,
          z = 1.42440998554
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    to = {
      locaId = 155,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2146.6398925781,
          y = 766.86999511719,
          z = 14.26000022888
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 113,
    from = {
      locaId = 158,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 4237.2001953125,
          y = 394.23400878906,
          z = 0.61002099514
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    to = {
      locaId = 155,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2146.6398925781,
          y = 766.86999511719,
          z = 14.26000022888
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 114,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 160,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 5535.009765625,
          y = 5019.8798828125,
          z = 12.64000034332
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") and ((C_QuestLog.IsQuestFlaggedCompleted(35884) or C_QuestLog.IsQuestFlaggedCompleted(34446))) end
  },
  {
    id = 115,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 160,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 5535.009765625,
          y = 5019.8798828125,
          z = 12.64000034332
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 116,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 161,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 5276.3999023438,
          y = -4045.2399902344,
          z = 19.57999992371
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(34586) or C_QuestLog.IsQuestFlaggedCompleted(34378))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 117,
    from = {
      locaId = 85,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11896.799804688,
          y = -3206.7700195312,
          z = -11.59619998932
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(90)) and (UnitFactionGroup("player") == "Alliance") and (C_UnitAuras.GetPlayerAuraBySpellID(176111) ~= nil) end,
      important = true
    },
    to = {
      locaId = 161,
      flags = 2,
      loc = {
        mapId = 1116,
        pos = {
          x = 5276.3999023438,
          y = -4045.2399902344,
          z = 19.57999992371
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(34586) or C_QuestLog.IsQuestFlaggedCompleted(34378))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 119,
    from = {
      locaId = 166,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 45.09560012817,
          y = 2490.5200195312,
          z = -4.29649019241
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 162,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8395.419921875,
          y = 562.01898193359,
          z = 91.79740142822
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 120,
    from = {
      locaId = 167,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 69.22769927979,
          y = 10.39319992065,
          z = -4.29664993286
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 163,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4839.4301757812,
          y = -1320.0899658203,
          z = 501.86801147461
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 121,
    from = {
      locaId = 46,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4613.7099609375,
          y = -915.28698730469,
          z = 501.06201171875
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 163,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4839.4301757812,
          y = -1320.0899658203,
          z = 501.86801147461
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 0,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 123,
    from = {
      locaId = 65,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1020.5599975586,
          y = -659.00701904297,
          z = 6.48783016205
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 164,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8646.23046875,
          y = 1331.6300048828,
          z = 5.69915008545
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 125,
    from = {
      locaId = 139,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -7096.169921875,
          y = 1294.5799560547,
          z = -93.40570068359
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(120)) end,
      important = true
    },
    to = {
      locaId = 133,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1128.3900146484,
          y = 771.86602783203,
          z = 433.38598632813
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 126,
    from = {
      locaId = 169,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1150.5,
          y = -519.55700683594,
          z = 17.53289985657
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(54972) or C_QuestLog.IsQuestFlaggedCompleted(55053)) end,
      important = true
    },
    to = {
      locaId = 168,
      flags = 0,
      loc = {
        mapId = 1718,
        pos = {
          x = 1292.3732910156,
          y = -106.5781326294,
          z = -330.10025024414
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 127,
    from = {
      locaId = 168,
      flags = 0,
      loc = {
        mapId = 1718,
        pos = {
          x = 1292.3732910156,
          y = -106.5781326294,
          z = -330.10025024414
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 170,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1150.5,
          y = -519.55700683594,
          z = 17.53289985657
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(54972) or C_QuestLog.IsQuestFlaggedCompleted(55053)) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 128,
    from = {
      locaId = 169,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1150.5,
          y = -519.55700683594,
          z = 17.53289985657
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(54972) or C_QuestLog.IsQuestFlaggedCompleted(55053)) end,
      important = true
    },
    to = {
      locaId = 171,
      flags = 0,
      loc = {
        mapId = 1718,
        pos = {
          x = 1292.3732910156,
          y = -106.5781326294,
          z = -330.10025024414
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 129,
    from = {
      locaId = 174,
      flags = 0,
      loc = {
        mapId = 1718,
        pos = {
          x = 1003.5,
          y = -417.76901245117,
          z = -281.89300537109
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 133,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1128.3900146484,
          y = 771.86602783203,
          z = 433.38598632813
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 130,
    from = {
      locaId = 173,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1142.5699462891,
          y = 779.25201416016,
          z = 433.32598876953
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(54972) or C_QuestLog.IsQuestFlaggedCompleted(55053)) end,
      important = true
    },
    to = {
      locaId = 175,
      flags = 0,
      loc = {
        mapId = 1718,
        pos = {
          x = 1003.5,
          y = -417.76901245117,
          z = -281.89300537109
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 131,
    from = {
      locaId = 80,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 45.09560012817,
          y = 2490.5200195312,
          z = -4.29649019241
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 60,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 4.62940979004,
          y = 2510.419921875,
          z = -3.27041006088
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 132,
    from = {
      locaId = 60,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 4.62940979004,
          y = 2510.419921875,
          z = -3.27041006088
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 167,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 69.22769927979,
          y = 10.39319992065,
          z = -4.29664993286
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 133,
    from = {
      locaId = 58,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 69.22769927979,
          y = 10.39319992065,
          z = -4.29664993286
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 59,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 4.62962007523,
          y = 28.13899993896,
          z = -3.45693993568
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 134,
    from = {
      locaId = 59,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 4.62962007523,
          y = 28.13899993896,
          z = -3.45693993568
        }
      },
      type = 0,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 166,
      flags = 0,
      loc = {
        mapId = 369,
        pos = {
          x = 45.09560012817,
          y = 2490.5200195312,
          z = -4.29649019241
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 135,
    from = {
      locaId = 179,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 3327.6000976562,
          y = 4856.080078125,
          z = 2.82741999626
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 177,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1906.9499511719,
          y = 1033.5899658203,
          z = 4.86709976196
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 136,
    from = {
      locaId = 176,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1906.9499511719,
          y = 1033.5899658203,
          z = 4.86709976196
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 178,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 3349.0200195312,
          y = 4850.5600585938,
          z = 0.26930400729
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 137,
    from = {
      locaId = 180,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -714.48498535156,
          y = 4418.8999023438,
          z = 728.09497070313
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 138,
    from = {
      locaId = 186,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2174.3999023438,
          y = 762.16497802734,
          z = 20.99869918823
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 189,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = -217.74000549316,
          y = -1554.5100097656,
          z = 2.73000001907
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 139,
    from = {
      locaId = 188,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2174.3999023438,
          y = 762.16497802734,
          z = 20.99869918823
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51986)) end,
      important = true
    },
    to = {
      locaId = 190,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 3986.9799804688,
          y = 445.14001464844,
          z = 109.30000305176
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51986)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 140,
    from = {
      locaId = 187,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2174.3999023438,
          y = 762.16497802734,
          z = 20.99869918823
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51340)) end,
      important = true
    },
    to = {
      locaId = 191,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = -406.70001220703,
          y = 4121.8198242188,
          z = 4.11000013351
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51340)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 141,
    from = {
      locaId = 184,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1014.0300292969,
          y = -485.51901245117,
          z = 20.00819969177
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 194,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = 2831.1799316406,
          y = 4264.2900390625,
          z = 7.19000005722
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 142,
    from = {
      locaId = 185,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1014.0300292969,
          y = -485.51901245117,
          z = 20.00819969177
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51968)) end,
      important = true
    },
    to = {
      locaId = 192,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -2618.3601074219,
          y = 2266.7900390625,
          z = 12.88000011444
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51968)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 143,
    from = {
      locaId = 183,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1014.0300292969,
          y = -485.51901245117,
          z = 20.00819969177
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51088)) end,
      important = true
    },
    to = {
      locaId = 193,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = 2128.919921875,
          y = 192.17999267578,
          z = 0.21999999881
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(51088)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 144,
    from = {
      locaId = 196,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1142.9499511719,
          y = -515.96600341797,
          z = 17.53300094604
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(120)) end,
      important = true
    },
    to = {
      locaId = 197,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -7096,
          y = 1302.6999511719,
          z = -93.30000305176
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 145,
    from = {
      locaId = 198,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -7086.5698242188,
          y = 1299.6800537109,
          z = -93.4049987793
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(120)) end,
      important = true
    },
    to = {
      locaId = 199,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1143.5999755859,
          y = -525.59997558594,
          z = 17.5
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 153,
    from = {
      locaId = 204,
      flags = 16,
      loc = {
        mapId = 1,
        pos = {
          x = -8153.3598632812,
          y = -4808.2202148438,
          z = 36.55699920654
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 154,
    from = {
      locaId = 203,
      flags = 16,
      loc = {
        mapId = 1,
        pos = {
          x = 1412.8800048828,
          y = -4487.490234375,
          z = -2.66358995438
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 207,
      flags = 16,
      loc = {
        mapId = 1,
        pos = {
          x = -8164.7998046875,
          y = -4768.5,
          z = 34.29999923706
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 155,
    from = {
      locaId = 205,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -8984.7998046875,
          y = 963.0009765625,
          z = 68.68389892578
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 207,
      flags = 16,
      loc = {
        mapId = 1,
        pos = {
          x = -8164.7998046875,
          y = -4768.5,
          z = 34.29999923706
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 156,
    from = {
      locaId = 208,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -8153.6098632812,
          y = -4816.7797851562,
          z = 35.78089904785
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 157,
    from = {
      locaId = 209,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8645.5400390625,
          y = 1308.25,
          z = 5.23483991623
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 211,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 8177.5600585938,
          y = 1002.6599731445,
          z = 6.66929006577
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 158,
    from = {
      locaId = 210,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 8177.5600585938,
          y = 1002.6599731445,
          z = 6.66929006577
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 160,
    from = {
      locaId = 213,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 2070.5122070312,
          y = 289.15798950195,
          z = 97.03157806396
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 161,
    from = {
      locaId = 215,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 2063.2448730469,
          y = 364.23959350586,
          z = 82.50442504883
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 216,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 1950.8000488281,
          y = -6174.2299804688,
          z = 24.30380058289
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 162,
    from = {
      locaId = 214,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 2059.9340820312,
          y = 235.90972900391,
          z = 99.76524353027
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 217,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -12396.400390625,
          y = 217.47999572754,
          z = 1.69035005569
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 165,
    from = {
      locaId = 219,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9095.5556640625,
          y = 896.703125,
          z = 68.04355621338
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    to = {
      locaId = 220,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.1899414062,
          y = 1542.4699707031,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 166,
    from = {
      locaId = 218,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1466.1800537109,
          y = -4519.1801757812,
          z = 20.28490066528
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 221,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.1899414062,
          y = 1542.4699707031,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 167,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 219,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9095.5556640625,
          y = 896.703125,
          z = 68.04355621338
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 168,
    from = {
      locaId = 222,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3561) or FarstriderLibData.Util.CanUseSpell(10059))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3561
        },
        {
          type = "spell",
          data = 10059
        }
      },
      important = true
    },
    to = {
      locaId = 246,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9041,
          y = 917.65997314453,
          z = 66.69000244141
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3561) or FarstriderLibData.Util.CanUseSpell(10059))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3561
        },
        {
          type = "spell",
          data = 10059
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(3561) or FarstriderLibData.Util.CanUseSpell(10059))) end
  },
  {
    id = 169,
    from = {
      locaId = 223,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3562) or FarstriderLibData.Util.CanUseSpell(11416))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3562
        },
        {
          type = "spell",
          data = 11416
        }
      },
      important = true
    },
    to = {
      locaId = 247,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4613.7099609375,
          y = -915.28997802734,
          z = 501.05999755859
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3562) or FarstriderLibData.Util.CanUseSpell(11416))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3562
        },
        {
          type = "spell",
          data = 11416
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(3562) or FarstriderLibData.Util.CanUseSpell(11416))) end
  },
  {
    id = 170,
    from = {
      locaId = 224,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3565) or FarstriderLibData.Util.CanUseSpell(11419))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3565
        },
        {
          type = "spell",
          data = 11419
        }
      },
      important = true
    },
    to = {
      locaId = 248,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 7415.1098632812,
          y = 46.24000167847,
          z = 2.75999999046
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3565) or FarstriderLibData.Util.CanUseSpell(11419))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3565
        },
        {
          type = "spell",
          data = 11419
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(3565) or FarstriderLibData.Util.CanUseSpell(11419))) end
  },
  {
    id = 171,
    from = {
      locaId = 225,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(32271) or FarstriderLibData.Util.CanUseSpell(32266))) end,
      actionOptions = {
        {
          type = "spell",
          data = 32271
        },
        {
          type = "spell",
          data = 32266
        }
      },
      important = true
    },
    to = {
      locaId = 249,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -4031.2399902344,
          y = -11569.599609375,
          z = -138.30000305176
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(32271) or FarstriderLibData.Util.CanUseSpell(32266))) end,
      actionOptions = {
        {
          type = "spell",
          data = 32271
        },
        {
          type = "spell",
          data = 32266
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(32271) or FarstriderLibData.Util.CanUseSpell(32266))) end
  },
  {
    id = 172,
    from = {
      locaId = 226,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(49359) or FarstriderLibData.Util.CanUseSpell(49360))) end,
      actionOptions = {
        {
          type = "spell",
          data = 49359
        },
        {
          type = "spell",
          data = 49360
        }
      },
      important = true
    },
    to = {
      locaId = 250,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -3748.1101074219,
          y = -4440.2099609375,
          z = 30.56999969482
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(49359) or FarstriderLibData.Util.CanUseSpell(49360))) end,
      actionOptions = {
        {
          type = "spell",
          data = 49359
        },
        {
          type = "spell",
          data = 49360
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(49359) or FarstriderLibData.Util.CanUseSpell(49360))) end
  },
  {
    id = 173,
    from = {
      locaId = 227,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3567) or FarstriderLibData.Util.CanUseSpell(11417))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3567
        },
        {
          type = "spell",
          data = 11417
        }
      },
      important = true
    },
    to = {
      locaId = 260,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30669975281
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3567) or FarstriderLibData.Util.CanUseSpell(11417))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3567
        },
        {
          type = "spell",
          data = 11417
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(3567) or FarstriderLibData.Util.CanUseSpell(11417))) end
  },
  {
    id = 174,
    from = {
      locaId = 228,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3563) or FarstriderLibData.Util.CanUseSpell(11418))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3563
        },
        {
          type = "spell",
          data = 11418
        }
      },
      important = true
    },
    to = {
      locaId = 261,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 1947.2600097656,
          y = -98.15000152588,
          z = 41.14670181274
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3563) or FarstriderLibData.Util.CanUseSpell(11418))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3563
        },
        {
          type = "spell",
          data = 11418
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(3563) or FarstriderLibData.Util.CanUseSpell(11418))) end
  },
  {
    id = 175,
    from = {
      locaId = 229,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3566) or FarstriderLibData.Util.CanUseSpell(11420))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3566
        },
        {
          type = "spell",
          data = 11420
        }
      },
      important = true
    },
    to = {
      locaId = 262,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -967.38000488281,
          y = 284.82000732422,
          z = 110.76999664307
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(3566) or FarstriderLibData.Util.CanUseSpell(11420))) end,
      actionOptions = {
        {
          type = "spell",
          data = 3566
        },
        {
          type = "spell",
          data = 11420
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(3566) or FarstriderLibData.Util.CanUseSpell(11420))) end
  },
  {
    id = 176,
    from = {
      locaId = 230,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(32272) or FarstriderLibData.Util.CanUseSpell(32267))) end,
      actionOptions = {
        {
          type = "spell",
          data = 32272
        },
        {
          type = "spell",
          data = 32267
        }
      },
      important = true
    },
    to = {
      locaId = 263,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 9998.4599609375,
          y = -7106.5498046875,
          z = 47.70589828491
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 110,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(32272) or FarstriderLibData.Util.CanUseSpell(32267))) end,
      actionOptions = {
        {
          type = "spell",
          data = 32272
        },
        {
          type = "spell",
          data = 32267
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(32272) or FarstriderLibData.Util.CanUseSpell(32267))) end
  },
  {
    id = 177,
    from = {
      locaId = 231,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(49358) or FarstriderLibData.Util.CanUseSpell(49361))) end,
      actionOptions = {
        {
          type = "spell",
          data = 49358
        },
        {
          type = "spell",
          data = 49361
        }
      },
      important = true
    },
    to = {
      locaId = 264,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -10469,
          y = -3331.5400390625,
          z = 25.46999931335
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(49358) or FarstriderLibData.Util.CanUseSpell(49361))) end,
      actionOptions = {
        {
          type = "spell",
          data = 49358
        },
        {
          type = "spell",
          data = 49361
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(49358) or FarstriderLibData.Util.CanUseSpell(49361))) end
  },
  {
    id = 178,
    from = {
      locaId = 232,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(33690) or FarstriderLibData.Util.CanUseSpell(33691))) end,
      actionOptions = {
        {
          type = "spell",
          data = 33690
        },
        {
          type = "spell",
          data = 33691
        }
      },
      important = true
    },
    to = {
      locaId = 251,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1824.3199462891,
          y = 5417.2299804688,
          z = -12.43000030518
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(33690) or FarstriderLibData.Util.CanUseSpell(33691))) end,
      actionOptions = {
        {
          type = "spell",
          data = 33690
        },
        {
          type = "spell",
          data = 33691
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(33690) or FarstriderLibData.Util.CanUseSpell(33691))) end
  },
  {
    id = 179,
    from = {
      locaId = 233,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(35715) or FarstriderLibData.Util.CanUseSpell(35717))) end,
      actionOptions = {
        {
          type = "spell",
          data = 35715
        },
        {
          type = "spell",
          data = 35717
        }
      },
      important = true
    },
    to = {
      locaId = 265,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1902.4899902344,
          y = 5442.8598632812,
          z = -12.43000030518
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(35715) or FarstriderLibData.Util.CanUseSpell(35717))) end,
      actionOptions = {
        {
          type = "spell",
          data = 35715
        },
        {
          type = "spell",
          data = 35717
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(35715) or FarstriderLibData.Util.CanUseSpell(35717))) end
  },
  {
    id = 180,
    from = {
      locaId = 234,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(53140) or FarstriderLibData.Util.CanUseSpell(53142))) end,
      actionOptions = {
        {
          type = "spell",
          data = 53140
        },
        {
          type = "spell",
          data = 53142
        }
      },
      important = true
    },
    to = {
      locaId = 252,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 5807.75,
          y = 588.34997558594,
          z = 660.94000244141
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(53140) or FarstriderLibData.Util.CanUseSpell(53142))) end,
      actionOptions = {
        {
          type = "spell",
          data = 53140
        },
        {
          type = "spell",
          data = 53142
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(53140) or FarstriderLibData.Util.CanUseSpell(53142))) end
  },
  {
    id = 181,
    from = {
      locaId = 235,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(88342) or FarstriderLibData.Util.CanUseSpell(88345))) end,
      actionOptions = {
        {
          type = "spell",
          data = 88342
        },
        {
          type = "spell",
          data = 88345
        }
      },
      important = true
    },
    to = {
      locaId = 253,
      flags = 0,
      loc = {
        mapId = 732,
        pos = {
          x = -369.20999145508,
          y = 1058.7299804688,
          z = 21.77000045776
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(88342) or FarstriderLibData.Util.CanUseSpell(88345))) end,
      actionOptions = {
        {
          type = "spell",
          data = 88342
        },
        {
          type = "spell",
          data = 88345
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(88342) or FarstriderLibData.Util.CanUseSpell(88345))) end
  },
  {
    id = 182,
    from = {
      locaId = 236,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(88344) or FarstriderLibData.Util.CanUseSpell(88346))) end,
      actionOptions = {
        {
          type = "spell",
          data = 88344
        },
        {
          type = "spell",
          data = 88346
        }
      },
      important = true
    },
    to = {
      locaId = 266,
      flags = 0,
      loc = {
        mapId = 732,
        pos = {
          x = -603.71997070313,
          y = 1387.6199951172,
          z = 21.53840065002
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(88344) or FarstriderLibData.Util.CanUseSpell(88346))) end,
      actionOptions = {
        {
          type = "spell",
          data = 88344
        },
        {
          type = "spell",
          data = 88346
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(88344) or FarstriderLibData.Util.CanUseSpell(88346))) end
  },
  {
    id = 183,
    from = {
      locaId = 237,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(120145) or FarstriderLibData.Util.CanUseSpell(120146))) end,
      actionOptions = {
        {
          type = "spell",
          data = 120145
        },
        {
          type = "spell",
          data = 120146
        }
      },
      important = true
    },
    to = {
      locaId = 254,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 303.2200012207,
          y = 347.20999145508,
          z = 125.5299987793
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(120145) or FarstriderLibData.Util.CanUseSpell(120146))) end,
      actionOptions = {
        {
          type = "spell",
          data = 120145
        },
        {
          type = "spell",
          data = 120146
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(120145) or FarstriderLibData.Util.CanUseSpell(120146))) end
  },
  {
    id = 184,
    from = {
      locaId = 238,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(132621) or FarstriderLibData.Util.CanUseSpell(132620))) end,
      actionOptions = {
        {
          type = "spell",
          data = 132621
        },
        {
          type = "spell",
          data = 132620
        }
      },
      important = true
    },
    to = {
      locaId = 255,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = 917.64001464844,
          y = 294.88000488281,
          z = 506.09399414063
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(132621) or FarstriderLibData.Util.CanUseSpell(132620))) end,
      actionOptions = {
        {
          type = "spell",
          data = 132621
        },
        {
          type = "spell",
          data = 132620
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(132621) or FarstriderLibData.Util.CanUseSpell(132620))) end
  },
  {
    id = 185,
    from = {
      locaId = 239,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(132627) or FarstriderLibData.Util.CanUseSpell(132626))) end,
      actionOptions = {
        {
          type = "spell",
          data = 132627
        },
        {
          type = "spell",
          data = 132626
        }
      },
      important = true
    },
    to = {
      locaId = 267,
      flags = 0,
      loc = {
        mapId = 870,
        pos = {
          x = 1579.6500244141,
          y = 897.84002685547,
          z = 473.60000610352
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(132627) or FarstriderLibData.Util.CanUseSpell(132626))) end,
      actionOptions = {
        {
          type = "spell",
          data = 132627
        },
        {
          type = "spell",
          data = 132626
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(132627) or FarstriderLibData.Util.CanUseSpell(132626))) end
  },
  {
    id = 186,
    from = {
      locaId = 240,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(176248) or FarstriderLibData.Util.CanUseSpell(176246))) end,
      actionOptions = {
        {
          type = "spell",
          data = 176248
        },
        {
          type = "spell",
          data = 176246
        }
      },
      important = true
    },
    to = {
      locaId = 256,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 3744.330078125,
          y = -4055.8798828125,
          z = 46.54999923706
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(176248) or FarstriderLibData.Util.CanUseSpell(176246))) end,
      actionOptions = {
        {
          type = "spell",
          data = 176248
        },
        {
          type = "spell",
          data = 176246
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(176248) or FarstriderLibData.Util.CanUseSpell(176246))) end
  },
  {
    id = 187,
    from = {
      locaId = 241,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(176242) or FarstriderLibData.Util.CanUseSpell(176244))) end,
      actionOptions = {
        {
          type = "spell",
          data = 176242
        },
        {
          type = "spell",
          data = 176244
        }
      },
      important = true
    },
    to = {
      locaId = 268,
      flags = 0,
      loc = {
        mapId = 1116,
        pos = {
          x = 5267.7700195312,
          y = -4060.2600097656,
          z = 20.96999931335
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(176242) or FarstriderLibData.Util.CanUseSpell(176244))) end,
      actionOptions = {
        {
          type = "spell",
          data = 176242
        },
        {
          type = "spell",
          data = 176244
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(176242) or FarstriderLibData.Util.CanUseSpell(176244))) end
  },
  {
    id = 188,
    from = {
      locaId = 242,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return (FarstriderLibData.Util.CanUseSpell(193759)) end,
      actionOptions = {
        {
          type = "spell",
          data = 193759
        }
      },
      important = true
    },
    to = {
      locaId = 257,
      flags = 0,
      loc = {
        mapId = 1513,
        pos = {
          x = -935.16998291016,
          y = 4706.3999023438,
          z = 928.61700439453
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (FarstriderLibData.Util.CanUseSpell(193759)) end,
      actionOptions = {
        {
          type = "spell",
          data = 193759
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return (FarstriderLibData.Util.CanUseSpell(193759)) end
  },
  {
    id = 189,
    from = {
      locaId = 243,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(224869) or FarstriderLibData.Util.CanUseSpell(224871))) end,
      actionOptions = {
        {
          type = "spell",
          data = 224869
        },
        {
          type = "spell",
          data = 224871
        }
      },
      important = true
    },
    to = {
      locaId = 258,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -828.71997070313,
          y = 4371.7797851562,
          z = 738.63702392578
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(224869) or FarstriderLibData.Util.CanUseSpell(224871))) end,
      actionOptions = {
        {
          type = "spell",
          data = 224869
        },
        {
          type = "spell",
          data = 224871
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(224869) or FarstriderLibData.Util.CanUseSpell(224871))) end
  },
  {
    id = 190,
    from = {
      locaId = 244,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(281403) or FarstriderLibData.Util.CanUseSpell(281400))) end,
      actionOptions = {
        {
          type = "spell",
          data = 281403
        },
        {
          type = "spell",
          data = 281400
        }
      },
      important = true
    },
    to = {
      locaId = 259,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 1137.3599853516,
          y = -538.59997558594,
          z = 17.53000068665
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(281403) or FarstriderLibData.Util.CanUseSpell(281400))) end,
      actionOptions = {
        {
          type = "spell",
          data = 281403
        },
        {
          type = "spell",
          data = 281400
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(281403) or FarstriderLibData.Util.CanUseSpell(281400))) end
  },
  {
    id = 191,
    from = {
      locaId = 245,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(281404) or FarstriderLibData.Util.CanUseSpell(281402))) end,
      actionOptions = {
        {
          type = "spell",
          data = 281404
        },
        {
          type = "spell",
          data = 281402
        }
      },
      important = true
    },
    to = {
      locaId = 269,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1129.1899414062,
          y = 774.15002441406,
          z = 433.32501220703
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(281404) or FarstriderLibData.Util.CanUseSpell(281402))) end,
      actionOptions = {
        {
          type = "spell",
          data = 281404
        },
        {
          type = "spell",
          data = 281402
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(281404) or FarstriderLibData.Util.CanUseSpell(281402))) end
  },
  {
    id = 192,
    from = {
      locaId = 270,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2239990234,
          y = 1300.2066650391,
          z = 5446.1938476562
        }
      },
      type = 1,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 271,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = 4608.9301757812,
          y = 6793.3798828125,
          z = 4867.6499023438
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 193,
    from = {
      locaId = 272,
      flags = 4,
      loc = {
        mapId = 2222,
        pos = {
          x = 4565.6899414062,
          y = 6895.490234375,
          z = 4868.8598632812
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 273,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2700195312,
          y = 1541.9499511719,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 194,
    from = {
      locaId = 273,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2700195312,
          y = 1541.9499511719,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 274,
      flags = 18,
      loc = {
        mapId = 2222,
        pos = {
          x = -3391.2700195312,
          y = 5462.7797851562,
          z = 4275.7700195312
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = true
  },
  {
    id = 195,
    from = {
      locaId = 273,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2700195312,
          y = 1541.9499511719,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 275,
      flags = 18,
      loc = {
        mapId = 2222,
        pos = {
          x = 2579.4699707031,
          y = -2517.6499023438,
          z = 3307.5200195312
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = true
  },
  {
    id = 196,
    from = {
      locaId = 276,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = 4644.16015625,
          y = 6672.3500976562,
          z = 4840.5200195312
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 279,
      flags = 0,
      loc = {
        mapId = 2453,
        pos = {
          x = 1646.3100585938,
          y = 2337.5600585938,
          z = 380.95999145508
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 197,
    from = {
      locaId = 277,
      flags = 0,
      loc = {
        mapId = 2453,
        pos = {
          x = 1646.3100585938,
          y = 2337.5600585938,
          z = 380.95999145508
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 278,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = 4644.16015625,
          y = 6672.3500976562,
          z = 4840.5200195312
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 198,
    from = {
      locaId = 281,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = -1808.8800048828,
          y = 1537.9399414062,
          z = 5274.75
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") and (C_QuestLog.IsQuestFlaggedCompleted(60151)) end,
      important = true
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") and (C_QuestLog.IsQuestFlaggedCompleted(60151)) end
  },
  {
    id = 200,
    from = {
      locaId = 284,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = -1858.6700439453,
          y = 1538.3100585938,
          z = 5274.75
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(60151)) end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(60151)) end
  },
  {
    id = 201,
    from = {
      locaId = 287,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(344587) or FarstriderLibData.Util.CanUseSpell(344597))) end,
      actionOptions = {
        {
          type = "spell",
          data = 344587
        },
        {
          type = "spell",
          data = 344597
        }
      },
      important = true
    },
    to = {
      locaId = 288,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2099609375,
          y = 1542.2700195312,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(344587) or FarstriderLibData.Util.CanUseSpell(344597))) end,
      actionOptions = {
        {
          type = "spell",
          data = 344587
        },
        {
          type = "spell",
          data = 344597
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(344587) or FarstriderLibData.Util.CanUseSpell(344597))) end
  },
  {
    id = 202,
    from = {
      locaId = 273,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2700195312,
          y = 1541.9499511719,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 290,
      flags = 18,
      loc = {
        mapId = 2222,
        pos = {
          x = -6608.8500976562,
          y = 682.81201171875,
          z = 5620.2202148438
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = true
  },
  {
    id = 203,
    from = {
      locaId = 273,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1834.2700195312,
          y = 1541.9499511719,
          z = 5274.16015625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 289,
      flags = 18,
      loc = {
        mapId = 2222,
        pos = {
          x = -2983.8500976562,
          y = -4501.5600585938,
          z = 6549.509765625
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = true
  },
  {
    id = 205,
    from = {
      locaId = 293,
      flags = 4,
      loc = {
        mapId = 2222,
        pos = {
          x = 3267.2700195312,
          y = 5760.5600585938,
          z = 4939.080078125
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 294,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1716.75,
          y = 1402.6800537109,
          z = 5450.740234375
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 206,
    from = {
      locaId = 295,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = -1716.75,
          y = 1402.6800537109,
          z = 5450.740234375
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 296,
      flags = 16,
      loc = {
        mapId = 2222,
        pos = {
          x = 3267.2700195312,
          y = 5760.5600585938,
          z = 4939.080078125
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 207,
    from = {
      locaId = 297,
      flags = 4,
      loc = {
        mapId = 2222,
        pos = {
          x = -1723.0100097656,
          y = 1282.8800048828,
          z = 5451.990234375
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 298,
      flags = 0,
      loc = {
        mapId = 2374,
        pos = {
          x = -4357.6801757812,
          y = 800.40002441406,
          z = -40.99000167847
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 208,
    from = {
      locaId = 299,
      flags = 0,
      loc = {
        mapId = 2374,
        pos = {
          x = -4357.6801757812,
          y = 800.40002441406,
          z = -40.99000167847
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 300,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = -1723.0100097656,
          y = 1282.8800048828,
          z = 5451.990234375
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 210,
    from = {
      locaId = 304,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 1821.1999511719,
          y = 317.39898681641,
          z = 70.81479644775
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(52758)) end,
      important = true
    },
    to = {
      locaId = 216,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 1950.8000488281,
          y = -6174.2299804688,
          z = 24.30380058289
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 211,
    from = {
      locaId = 302,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 1820.7299804688,
          y = 344.56399536133,
          z = 70.81079864502
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(52758)) end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 212,
    from = {
      locaId = 303,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 1790.5899658203,
          y = 344.55899047852,
          z = 70.81420135498
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") and (C_QuestLog.IsQuestFlaggedCompleted(52758)) end,
      important = true
    },
    to = {
      locaId = 217,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -12396.400390625,
          y = 217.47999572754,
          z = 1.69035005569
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 213,
    from = {
      locaId = 305,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8645.2099609375,
          y = 1330.5699462891,
          z = 5.53677988052
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 306,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 3735.75,
          y = -1901.3800048828,
          z = 5.88091993332
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 214,
    from = {
      locaId = 308,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1343.6600341797,
          y = -4921.9799804688,
          z = 61.71440124512
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 307,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 3885.169921875,
          y = -1859.1400146484,
          z = 5.43444013596
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 215,
    from = {
      locaId = 309,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1473.5300292969,
          y = -4499.3798828125,
          z = 19.81940078735
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 310,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 275.70199584961,
          y = -1025.9899902344,
          z = 870.63098144531
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 216,
    from = {
      locaId = 312,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9077.9599609375,
          y = 873.26397705078,
          z = 68.18419647217
        }
      },
      type = 1,
      unknown1 = 10,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 311,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 247.35299682617,
          y = -1064.7199707031,
          z = 870.84802246094
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 217,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 312,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9077.9599609375,
          y = 873.26397705078,
          z = 68.18419647217
        }
      },
      type = 1,
      unknown1 = 10,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 218,
    from = {
      locaId = 314,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9077.9599609375,
          y = 873.26397705078,
          z = 68.18419647217
        }
      },
      type = 1,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 219,
    from = {
      locaId = 313,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 247.35299682617,
          y = -1064.7199707031,
          z = 870.84802246094
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 314,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9077.9599609375,
          y = 873.26397705078,
          z = 68.18419647217
        }
      },
      type = 1,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 220,
    from = {
      locaId = 315,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 3735.75,
          y = -1901.3800048828,
          z = 5.88091993332
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 316,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -8645.2099609375,
          y = 1330.5699462891,
          z = 5.53677988052
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 221,
    from = {
      locaId = 319,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 275.70199584961,
          y = -1025.9899902344,
          z = 870.63098144531
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 318,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1473.5300292969,
          y = -4499.3798828125,
          z = 19.81940078735
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 222,
    from = {
      locaId = 321,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 3885.169921875,
          y = -1859.1400146484,
          z = 5.43444013596
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 320,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1343.6600341797,
          y = -4921.9799804688,
          z = 61.71440124512
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 223,
    from = {
      locaId = 322,
      flags = 0,
      loc = {
        mapId = 2454,
        pos = {
          x = -52.87710189819,
          y = 787.31701660156,
          z = 75.26039886475
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 323,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -16.96750068665,
          y = 31.36289978027,
          z = 175.22200012207
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 224,
    from = {
      locaId = 324,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -16.96750068665,
          y = 31.36289978027,
          z = 175.22200012207
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 325,
      flags = 0,
      loc = {
        mapId = 2454,
        pos = {
          x = -52.87710189819,
          y = 787.31701660156,
          z = 75.26039886475
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 225,
    from = {
      locaId = 326,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(395277) or FarstriderLibData.Util.CanUseSpell(395289))) end,
      actionOptions = {
        {
          type = "spell",
          data = 395277
        },
        {
          type = "spell",
          data = 395289
        }
      },
      important = true
    },
    to = {
      locaId = 327,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 266.70001220703,
          y = -1048.1600341797,
          z = 871.10998535156
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(395277) or FarstriderLibData.Util.CanUseSpell(395289))) end,
      actionOptions = {
        {
          type = "spell",
          data = 395277
        },
        {
          type = "spell",
          data = 395289
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(395277) or FarstriderLibData.Util.CanUseSpell(395289))) end
  },
  {
    id = 226,
    from = {
      locaId = 328,
      flags = 0,
      loc = {
        mapId = 2454,
        pos = {
          x = -2026.7900390625,
          y = 3436.5700683594,
          z = 274.95999145508
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 329,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -2638.0100097656,
          y = 3432.6201171875,
          z = 445.78399658203
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 227,
    from = {
      locaId = 330,
      flags = 0,
      loc = {
        mapId = 2454,
        pos = {
          x = -1544.2600097656,
          y = 3538.0200195312,
          z = 222.3869934082
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 331,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1567.0899658203,
          y = 4131.83984375,
          z = 393.0299987793
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 228,
    from = {
      locaId = 332,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1567.0899658203,
          y = 4131.83984375,
          z = 393.0299987793
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 333,
      flags = 0,
      loc = {
        mapId = 2454,
        pos = {
          x = -1544.2600097656,
          y = 3538.0200195312,
          z = 222.3869934082
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 229,
    from = {
      locaId = 334,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -2638.0100097656,
          y = 3432.6201171875,
          z = 445.78399658203
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 335,
      flags = 0,
      loc = {
        mapId = 2454,
        pos = {
          x = -2026.7900390625,
          y = 3436.5700683594,
          z = 274.95999145508
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 230,
    from = {
      locaId = 336,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -966.87701416016,
          y = 4604.5,
          z = 735.29602050781
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    to = {
      locaId = 337,
      flags = 16,
      loc = {
        mapId = 0,
        pos = {
          x = 2376.0600585938,
          y = -5320.2797851562,
          z = 54.97399902344
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end
  },
  {
    id = 231,
    from = {
      locaId = 339,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 2376.0600585938,
          y = -5320.2797851562,
          z = 54.97399902344
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    to = {
      locaId = 338,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -966.87701416016,
          y = 4604.5,
          z = 735.29602050781
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end
  },
  {
    id = 232,
    from = {
      locaId = 342,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 2376.0600585938,
          y = -5320.2797851562,
          z = 54.97399902344
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    to = {
      locaId = 343,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -657.9580078125,
          y = 4363.8500976562,
          z = 748.57702636719
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end
  },
  {
    id = 233,
    from = {
      locaId = 340,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -657.9580078125,
          y = 4363.8500976562,
          z = 748.57702636719
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    to = {
      locaId = 341,
      flags = 16,
      loc = {
        mapId = 0,
        pos = {
          x = 2376.0600585938,
          y = -5320.2797851562,
          z = 54.97399902344
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (select(2, UnitClassBase("player")) == 2) and (C_QuestLog.IsQuestFlaggedCompleted(38566)) end
  },
  {
    id = 234,
    from = {
      locaId = 344,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1222.2014160156,
          y = 5429.4086914062,
          z = 41.27019119263
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 347,
      flags = 0,
      loc = {
        mapId = 2548,
        pos = {
          x = -1222.4271240234,
          y = 5429.212890625,
          z = 41.2702293396
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 235,
    from = {
      locaId = 346,
      flags = 0,
      loc = {
        mapId = 2548,
        pos = {
          x = -1222.4566650391,
          y = 5429.3149414062,
          z = 41.27027130127
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 345,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1222.21875,
          y = 5429.3818359375,
          z = 41.27021789551
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 239,
    from = {
      locaId = 353,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 1976.2900390625,
          y = -6096.2700195312,
          z = 67.15950012207
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 352,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1805,
          y = 327,
          z = 70.5
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 240,
    from = {
      locaId = 354,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -12396.400390625,
          y = 217.47999572754,
          z = 1.69035005569
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 352,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1805,
          y = 327,
          z = 70.5
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 241,
    from = {
      locaId = 355,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1820.7299804688,
          y = 344.56399536133,
          z = 70.81079864502
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 101,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30640029907
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 242,
    from = {
      locaId = 356,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1821.1999511719,
          y = 317.39898681641,
          z = 70.81479644775
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 216,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 1950.8000488281,
          y = -6174.2299804688,
          z = 24.30380058289
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 243,
    from = {
      locaId = 357,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1790.5899658203,
          y = 344.55899047852,
          z = 70.81420135498
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 217,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -12396.400390625,
          y = 217.47999572754,
          z = 1.69035005569
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 246,
    from = {
      locaId = 360,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 33.89440155029,
          y = -990.71099853516,
          z = 837.71997070313
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsOnQuest(78329) or C_QuestLog.IsOnQuest(78981))) end,
      important = true
    },
    to = {
      locaId = 362,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9134,
          y = 334.51300048828,
          z = 92.83470153809
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(78329)) end
  },
  {
    id = 250,
    from = {
      locaId = 367,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 9868.0302734375,
          y = 2494.5100097656,
          z = 1315.8699951172
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsOnQuest(78329) or C_QuestLog.IsOnQuest(78981))) end,
      important = true
    },
    to = {
      locaId = 362,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9134,
          y = 334.51300048828,
          z = 92.83470153809
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(78329)) end
  },
  {
    id = 251,
    from = {
      locaId = 368,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -3970.1101074219,
          y = -11860.200195312,
          z = 0.53827899694
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsOnQuest(78329) or C_QuestLog.IsOnQuest(78981))) end,
      important = true
    },
    to = {
      locaId = 362,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9134,
          y = 334.51300048828,
          z = 92.83470153809
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(78329)) end
  },
  {
    id = 252,
    from = {
      locaId = 366,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -4922.2700195312,
          y = -979.75598144531,
          z = 501.46899414063
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsOnQuest(78329) or C_QuestLog.IsOnQuest(78981))) end,
      important = true
    },
    to = {
      locaId = 362,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9134,
          y = 334.51300048828,
          z = 92.83470153809
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(78329)) end
  },
  {
    id = 253,
    from = {
      locaId = 369,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = 92.02069854736,
          y = -1112.5100097656,
          z = 887.66802978516
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 399,
      flags = 0,
      loc = {
        mapId = 2548,
        pos = {
          x = -1721.0100097656,
          y = 7107.6298828125,
          z = 197.71000671387
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 254,
    from = {
      locaId = 370,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1934.4300537109,
          y = 6852.1801757812,
          z = 183.27699279785
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 371,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9126.1298828125,
          y = 971.78997802734,
          z = 73.59230041504
        }
      },
      type = 2,
      unknown1 = 30,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 255,
    from = {
      locaId = 372,
      flags = 64,
      loc = {
        mapId = 0,
        pos = {
          x = -9126.1298828125,
          y = 971.78997802734,
          z = 73.59230041504
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 373,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1934.4300537109,
          y = 6852.1801757812,
          z = 183.27699279785
        }
      },
      type = 2,
      unknown1 = 30,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 256,
    from = {
      locaId = 374,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1960.3800048828,
          y = 6853.9301757812,
          z = 187.00100708008
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 375,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 7416.259765625,
          y = -454.78500366211,
          z = 0.31614199281
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 257,
    from = {
      locaId = 376,
      flags = 4,
      loc = {
        mapId = 1,
        pos = {
          x = 7416.259765625,
          y = -454.78500366211,
          z = 0.31614199281
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 377,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1805,
          y = 327,
          z = 70.5
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 258,
    from = {
      locaId = 378,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1968.9200439453,
          y = 6855.009765625,
          z = 187.00100708008
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 379,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 5552.3901367188,
          y = -3580.4399414062,
          z = 1567.9399414062
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 259,
    from = {
      locaId = 380,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 5552.3901367188,
          y = -3580.4399414062,
          z = 1567.9399414062
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 381,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1968.9200439453,
          y = 6855.009765625,
          z = 187.00100708008
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 260,
    from = {
      locaId = 383,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = 2325.5700683594,
          y = 6583.8999023438,
          z = 147.27699279785
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 384,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -1940.6099853516,
          y = 6875.1201171875,
          z = 183.03199768066
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 262,
    from = {
      locaId = 382,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -676.29901123047,
          y = 7022.5498046875,
          z = 14.54609966278
        }
      },
      type = 1,
      unknown1 = 30,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 386,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -4347.169921875,
          y = 2320.580078125,
          z = 11.30350017548
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 263,
    from = {
      locaId = 387,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -4347.169921875,
          y = 2320.580078125,
          z = 11.30350017548
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 388,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -676.29901123047,
          y = 7022.5498046875,
          z = 14.54609966278
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 264,
    from = {
      locaId = 389,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2918.8100585938,
          y = -2334.5300292969,
          z = 265.98699951172
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 391,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30669975281
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 265,
    from = {
      locaId = 390,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2981.669921875,
          y = -2397.5600585938,
          z = 265.98699951172
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 394,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9041.6103515625,
          y = 917.32000732422,
          z = 66.68699645996
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 266,
    from = {
      locaId = 392,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1427.6099853516,
          y = -4524.990234375,
          z = 20.34379959106
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 393,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2915.5700683594,
          y = -2400.3601074219,
          z = 265.85900878906
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 267,
    from = {
      locaId = 395,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9061.099609375,
          y = 886.67901611328,
          z = 68.43589782715
        }
      },
      type = 1,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 396,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2915.5700683594,
          y = -2400.3601074219,
          z = 265.85900878906
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 268,
    from = {
      locaId = 397,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(446540) or FarstriderLibData.Util.CanUseSpell(446534))) end,
      actionOptions = {
        {
          type = "spell",
          data = 446540
        },
        {
          type = "spell",
          data = 446534
        }
      },
      important = true
    },
    to = {
      locaId = 398,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2915.6799316406,
          y = -2400.330078125,
          z = 265.85800170898
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((FarstriderLibData.Util.CanUseSpell(446540) or FarstriderLibData.Util.CanUseSpell(446534))) end,
      actionOptions = {
        {
          type = "spell",
          data = 446540
        },
        {
          type = "spell",
          data = 446534
        }
      },
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return ((FarstriderLibData.Util.CanUseSpell(446540) or FarstriderLibData.Util.CanUseSpell(446534))) end
  },
  {
    id = 269,
    from = {
      locaId = 400,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2467.0900878906,
          y = -2396.3200683594,
          z = 408.56201171875
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14795,
      important = false
    },
    to = {
      locaId = 401,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2462.75,
          y = -2322.8798828125,
          z = 833.94598388672
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14795,
      important = true
    },
    bidirectional = false,
    cost = 21,
    skipOptimized = false
  },
  {
    id = 270,
    from = {
      locaId = 402,
      flags = 50,
      loc = {
        mapId = 2552,
        pos = {
          x = 2463.25,
          y = -2324.1398925781,
          z = -297.43399047852
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14717,
      important = false
    },
    to = {
      locaId = 403,
      flags = 50,
      loc = {
        mapId = 2552,
        pos = {
          x = 2470.9699707031,
          y = -2334.0300292969,
          z = -722.19201660156
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14717,
      important = true
    },
    bidirectional = false,
    cost = 27,
    skipOptimized = false
  },
  {
    id = 271,
    from = {
      locaId = 404,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = -4036.2399902344,
          y = -3376.4299316406,
          z = 37.65319824219
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    to = {
      locaId = 405,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -884.33001708984,
          y = 4484.75,
          z = 580.4580078125
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 272,
    from = {
      locaId = 406,
      flags = 0,
      loc = {
        mapId = 571,
        pos = {
          x = 3632.580078125,
          y = 271.99499511719,
          z = 52.26319885254
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    to = {
      locaId = 407,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -893.01898193359,
          y = 4506.6098632812,
          z = 580.4580078125
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 273,
    from = {
      locaId = 409,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -7104.8198242188,
          y = -1254.4799804688,
          z = 273.77600097656
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    to = {
      locaId = 408,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -884.33001708984,
          y = 4484.75,
          z = 580.4580078125
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = true,
    cost = 600,
    skipOptimized = false,
    condition = function() return (UnitLevel("player") >= GetCorrectedLevel(255)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end
  },
  {
    id = 276,
    from = {
      locaId = 414,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2678.580078125,
          y = -2291,
          z = 362.71798706055
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14795,
      important = false
    },
    to = {
      locaId = 415,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2606.2800292969,
          y = -2152.8601074219,
          z = 345.61999511719
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14838,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 277,
    from = {
      locaId = 416,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2606.2800292969,
          y = -2152.8601074219,
          z = 345.61999511719
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14838,
      important = false
    },
    to = {
      locaId = 417,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2678.580078125,
          y = -2291,
          z = 362.71798706055
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14795,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 278,
    from = {
      locaId = 418,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 1608.0699462891,
          y = -1760.7800292969,
          z = -382.83801269531
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14838,
      important = false
    },
    to = {
      locaId = 419,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 1607.8900146484,
          y = -1769.3100585938,
          z = -388.02499389648
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14752,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 279,
    from = {
      locaId = 420,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 353.59698486328,
          y = 886.375,
          z = -462.62399291992
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14838,
      important = false
    },
    to = {
      locaId = 421,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = -358.9289855957,
          y = 554.74401855469,
          z = -995.48699951172
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14752,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 280,
    from = {
      locaId = 422,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 1607.9300537109,
          y = -1770.2700195312,
          z = -388.50100708008
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14752,
      important = false
    },
    to = {
      locaId = 423,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 1608.0699462891,
          y = -1760.7800292969,
          z = -382.83801269531
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14838,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 281,
    from = {
      locaId = 425,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = -364.93701171875,
          y = 553.03601074219,
          z = -995.56896972656
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14752,
      important = false
    },
    to = {
      locaId = 424,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 317.42599487305,
          y = 798.458984375,
          z = -478.77801513672
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14838,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 282,
    from = {
      locaId = 428,
      flags = 0,
      loc = {
        mapId = 2706,
        pos = {
          x = 3.20050001144,
          y = 1062.3199462891,
          z = 12.26760005951
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 429,
      flags = 0,
      loc = {
        mapId = 2601,
        pos = {
          x = 308.29998779297,
          y = -4900.1899414062,
          z = -6.47384977341
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 283,
    from = {
      locaId = 426,
      flags = 0,
      loc = {
        mapId = 2601,
        pos = {
          x = 309.75399780273,
          y = -4913.2900390625,
          z = -5.00101995468
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 427,
      flags = 0,
      loc = {
        mapId = 2706,
        pos = {
          x = 0.31000000238,
          y = 1055.8199462891,
          z = 11.11999988556
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 284,
    from = {
      locaId = 430,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1669.4300537109,
          y = 3804.9499511719,
          z = 36.76879882813
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 431,
      flags = 0,
      loc = {
        mapId = 2706,
        pos = {
          x = -1.0955799818,
          y = 1032.0899658203,
          z = 10.26099967957
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 289,
    from = {
      locaId = 403,
      flags = 50,
      loc = {
        mapId = 2552,
        pos = {
          x = 2470.9699707031,
          y = -2334.0300292969,
          z = -722.19201660156
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14717,
      important = true
    },
    to = {
      locaId = 439,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2466.9799804688,
          y = -2395,
          z = 408.57299804688
        }
      },
      type = 0,
      unknown1 = 0,
      uiMapHint = 14795,
      important = true
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 290,
    from = {
      locaId = 440,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 549.61700439453,
          y = -2421.7900390625,
          z = -671.03302001953
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14795,
      important = false
    },
    to = {
      locaId = 441,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 508.78698730469,
          y = -2335.6201171875,
          z = -807.42602539063
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14752,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 291,
    from = {
      locaId = 442,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 508.78698730469,
          y = -2335.6201171875,
          z = -807.42602539063
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14752,
      important = false
    },
    to = {
      locaId = 443,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 549.61700439453,
          y = -2421.7900390625,
          z = -671.03302001953
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14795,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 292,
    from = {
      locaId = 444,
      flags = 18,
      loc = {
        mapId = 2552,
        pos = {
          x = 2569.1799316406,
          y = -2869.4699707031,
          z = 198.80099487305
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14717,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(84022) or C_QuestLog.IsQuestFlaggedCompleted(79573))) end,
      important = true
    },
    to = {
      locaId = 445,
      flags = 18,
      loc = {
        mapId = 2601,
        pos = {
          x = -368.85998535156,
          y = -1473.8299560547,
          z = -1094.5300292969
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14752,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(84022) or C_QuestLog.IsQuestFlaggedCompleted(79573))) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(84022) or C_QuestLog.IsQuestFlaggedCompleted(79573))) end
  },
  {
    id = 293,
    from = {
      locaId = 447,
      flags = 18,
      loc = {
        mapId = 2601,
        pos = {
          x = -363.48498535156,
          y = -1478.6700439453,
          z = -1094.5799560547
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 14752,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(84022) or C_QuestLog.IsQuestFlaggedCompleted(79573))) end,
      important = true
    },
    to = {
      locaId = 446,
      flags = 18,
      loc = {
        mapId = 2552,
        pos = {
          x = 2571.2700195312,
          y = -2869.3100585938,
          z = 198.79699707031
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14717,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(84022) or C_QuestLog.IsQuestFlaggedCompleted(79573))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(84022) or C_QuestLog.IsQuestFlaggedCompleted(79573))) end
  },
  {
    id = 294,
    from = {
      locaId = 401,
      flags = 50,
      loc = {
        mapId = 2601,
        pos = {
          x = 2462.75,
          y = -2322.8798828125,
          z = 833.94598388672
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 14795,
      important = true
    },
    to = {
      locaId = 448,
      flags = 50,
      loc = {
        mapId = 2552,
        pos = {
          x = 2462.3100585938,
          y = -2323.9299316406,
          z = -290.00100708008
        }
      },
      type = 0,
      unknown1 = 0,
      uiMapHint = 14717,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 295,
    from = {
      locaId = 449,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -849.13299560547,
          y = 4473.8598632812,
          z = 588.84899902344
        }
      },
      type = 1,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 450,
      flags = 0,
      loc = {
        mapId = 2731,
        pos = {
          x = 2317.4599609375,
          y = -1440.1199951172,
          z = 2034.1899414062
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 296,
    from = {
      locaId = 451,
      flags = 0,
      loc = {
        mapId = 2706,
        pos = {
          x = -16.5751991272,
          y = 1028.8000488281,
          z = 12.22990036011
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 452,
      flags = 0,
      loc = {
        mapId = 1642,
        pos = {
          x = -1684.2900390625,
          y = 3814.8200683594,
          z = 36.91680145264
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 297,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 395,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9061.099609375,
          y = 886.67901611328,
          z = 68.43589782715
        }
      },
      type = 1,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 298,
    from = {
      locaId = 394,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9041.6103515625,
          y = 917.32000732422,
          z = 66.68699645996
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 302,
    from = {
      locaId = 455,
      flags = 0,
      loc = {
        mapId = 2127,
        pos = {
          x = 1970.921875,
          y = 5.05902767181,
          z = 38.59056472778
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 456,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 3213.0100097656,
          y = -3073.3601074219,
          z = 343.79299926758
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 303,
    from = {
      locaId = 457,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 3225.7399902344,
          y = -3073.5200195312,
          z = 342.68701171875
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 458,
      flags = 0,
      loc = {
        mapId = 2127,
        pos = {
          x = 1973.5642089844,
          y = 6.64236116409,
          z = 38.52370071411
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 304,
    from = {
      locaId = 459,
      flags = 0,
      loc = {
        mapId = 2127,
        pos = {
          x = 2121.7744140625,
          y = 50.44618225098,
          z = 2.63098597527
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 460,
      flags = 0,
      loc = {
        mapId = 2601,
        pos = {
          x = 2375.3200683594,
          y = -2678.2199707031,
          z = 397.12701416016
        }
      },
      type = 1,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 305,
    from = {
      locaId = 461,
      flags = 0,
      loc = {
        mapId = 2601,
        pos = {
          x = 2375.3200683594,
          y = -2678.2199707031,
          z = 397.12701416016
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 462,
      flags = 0,
      loc = {
        mapId = 2127,
        pos = {
          x = 2121.7744140625,
          y = 50.44618225098,
          z = 2.63098597527
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 307,
    from = {
      locaId = 464,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = -1646.8000488281,
          y = -461.97198486328,
          z = 545.89398193359
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 466,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = 4718.8901367188,
          y = 7637.3198242188,
          z = 4771.83984375
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 308,
    from = {
      locaId = 467,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = 4714.080078125,
          y = 7636.4702148438,
          z = 4772.5698242188
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 468,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = -1638.5699462891,
          y = -463.14001464844,
          z = 545.89001464844
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 309,
    from = {
      locaId = 469,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = -1657.8199462891,
          y = -501.57998657227,
          z = 549.74700927734
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 470,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2969.6298828125,
          y = -2384.7600097656,
          z = 265.98699951172
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 310,
    from = {
      locaId = 471,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2981.7299804688,
          y = -2379.7600097656,
          z = 266.10998535156
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 472,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = -1640.2299804688,
          y = -494.23001098633,
          z = 549.64001464844
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 311,
    from = {
      locaId = 473,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2593.2900390625,
          y = -2635.1000976562,
          z = 182.91700744629
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 474,
      flags = 0,
      loc = {
        mapId = 2706,
        pos = {
          x = -38.04999923706,
          y = 850.01000976563,
          z = 0.1400000006
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 312,
    from = {
      locaId = 475,
      flags = 0,
      loc = {
        mapId = 2706,
        pos = {
          x = -41.45560073853,
          y = 845.69598388672,
          z = 0.68680101633
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 476,
      flags = 0,
      loc = {
        mapId = 2552,
        pos = {
          x = 2589.3898925781,
          y = -2631.8999023438,
          z = 182.33999633789
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 313,
    from = {
      locaId = 482,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = 1348.9399414062,
          y = -1040.9799804688,
          z = -97.10050201416
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 483,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1427.2299804688,
          y = 6345.8100585938,
          z = 39.15129852295
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 314,
    from = {
      locaId = 484,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1462.6899414062,
          y = 6339.08984375,
          z = 37.24039840698
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 485,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = -188.22999572754,
          y = 1253.5699462891,
          z = 259.7200012207
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(88661)) end
  },
  {
    id = 315,
    from = {
      locaId = 486,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = -1462.6899414062,
          y = 6339.08984375,
          z = 37.24039840698
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 487,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = 1301.5899658203,
          y = -1053.0500488281,
          z = -100.98000335693
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(88659)) end
  },
  {
    id = 316,
    from = {
      locaId = 479,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = 1331.5799560547,
          y = -1045.7099609375,
          z = -97.10389709473
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 488,
      flags = 0,
      loc = {
        mapId = 1643,
        pos = {
          x = 2522.2700195312,
          y = -761.94000244141,
          z = 38.38000106812
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 317,
    from = {
      locaId = 481,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = 1321.75,
          y = -1017.3099975586,
          z = -97.22010040283
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 489,
      flags = 0,
      loc = {
        mapId = 2444,
        pos = {
          x = -3850.7399902344,
          y = 3433.669921875,
          z = 170.32000732422
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 318,
    from = {
      locaId = 477,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = 1339.0100097656,
          y = -1011.7899780273,
          z = -97.21959686279
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 490,
      flags = 0,
      loc = {
        mapId = 2601,
        pos = {
          x = -1407.7099609375,
          y = -2821.4099121094,
          z = -1180.3199462891
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 319,
    from = {
      locaId = 480,
      flags = 0,
      loc = {
        mapId = 2738,
        pos = {
          x = 1352.3900146484,
          y = -1023.4600219727,
          z = -97.16069793701
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 491,
      flags = 0,
      loc = {
        mapId = 2222,
        pos = {
          x = 2767.2800292969,
          y = -3742.5700683594,
          z = 3293.4799804688
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 335,
    from = {
      locaId = 502,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -869.96002197266,
          y = 4503.0200195312,
          z = 580.4580078125
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 503,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -11123.299804688,
          y = -2014.4399414062,
          z = 47.09000015259
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false
  },
  {
    id = 336,
    from = {
      locaId = 504,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -897.72601318359,
          y = 4548.3798828125,
          z = 744.51300048828
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 505,
      flags = 16,
      loc = {
        mapId = 1512,
        pos = {
          x = 1232.9599609375,
          y = 1344.1999511719,
          z = 185.08099365234
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 337,
    from = {
      locaId = 510,
      flags = 0,
      loc = {
        mapId = 1512,
        pos = {
          x = 1232.9599609375,
          y = 1344.1999511719,
          z = 185.08099365234
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    to = {
      locaId = 511,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -680.28497314453,
          y = 4356.1000976562,
          z = 748.57598876953
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 338,
    from = {
      locaId = 508,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -680.28497314453,
          y = 4356.1000976562,
          z = 748.57598876953
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    to = {
      locaId = 509,
      flags = 16,
      loc = {
        mapId = 1512,
        pos = {
          x = 1232.9599609375,
          y = 1344.1999511719,
          z = 185.08099365234
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 339,
    from = {
      locaId = 506,
      flags = 0,
      loc = {
        mapId = 1512,
        pos = {
          x = 1232.9599609375,
          y = 1344.1999511719,
          z = 185.08099365234
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    to = {
      locaId = 507,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -897.72601318359,
          y = 4548.3798828125,
          z = 744.51300048828
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 341,
    from = {
      locaId = 514,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -853.76098632813,
          y = 4261.9501953125,
          z = 746.28100585938
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 515,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 389.98001098633,
          y = 1417.0999755859,
          z = 769.59997558594
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 342,
    from = {
      locaId = 516,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 505.08200073242,
          y = 1472.0300292969,
          z = 765.79699707031
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 518,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = -2637.0900878906,
          y = 8703.8203125,
          z = -70.81890106201
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = true,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 343,
    from = {
      locaId = 516,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 505.08200073242,
          y = 1472.0300292969,
          z = 765.79699707031
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 517,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 4731.2998046875,
          y = 9863.23046875,
          z = 64.29070281982
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = true,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 344,
    from = {
      locaId = 518,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = -2637.0900878906,
          y = 8703.8203125,
          z = -70.81890106201
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 517,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 4731.2998046875,
          y = 9863.23046875,
          z = 64.29070281982
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 345,
    from = {
      locaId = 516,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 505.08200073242,
          y = 1472.0300292969,
          z = 765.79699707031
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 519,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 985.81896972656,
          y = 1711.8900146484,
          z = 517.12902832031
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 346,
    from = {
      locaId = 520,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 985.81896972656,
          y = 1711.8900146484,
          z = 517.12902832031
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 516,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 505.08200073242,
          y = 1472.0300292969,
          z = 765.79699707031
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 347,
    from = {
      locaId = 515,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 389.98001098633,
          y = 1417.0999755859,
          z = 769.59997558594
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 516,
      flags = 0,
      loc = {
        mapId = 1669,
        pos = {
          x = 505.08200073242,
          y = 1472.0300292969,
          z = 765.79699707031
        }
      },
      type = 0,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 348,
    from = {
      locaId = 521,
      flags = 16,
      loc = {
        mapId = 1469,
        pos = {
          x = 1010.1900024414,
          y = 1118.5100097656,
          z = 33.43569946289
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 64) end,
      important = true
    },
    to = {
      locaId = 522,
      flags = 16,
      loc = {
        mapId = 646,
        pos = {
          x = 2336.9599609375,
          y = 176.58000183106,
          z = 180.05999755859
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 64) end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (select(2, UnitClassBase("player")) == 64) end
  },
  {
    id = 349,
    from = {
      locaId = 523,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -847.12799072266,
          y = 4321.1401367188,
          z = 744.82202148438
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 541,
      flags = 16,
      loc = {
        mapId = 1469,
        pos = {
          x = 1002.2700195312,
          y = 1093.9799804688,
          z = 15.84189987183
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false
  },
  {
    id = 350,
    from = {
      locaId = 525,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1463.6999511719,
          y = -4479.8999023438,
          z = 20.00370025635
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 526,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8296.3095703125,
          y = -4616.6298828125,
          z = 18.66670036316
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 351,
    from = {
      locaId = 496,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8552.400390625,
          y = -4800,
          z = 45.8643989563
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 527,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1445.2099609375,
          y = -4499.5600585938,
          z = 18.30669975281
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 352,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 528,
      flags = 86,
      loc = {
        mapId = 0,
        pos = {
          x = -9096.6201171875,
          y = 877.23199462891,
          z = 68.13980102539
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 353,
    from = {
      locaId = 497,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8565.8798828125,
          y = -4812.3598632812,
          z = 45.86610031128
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 530,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = -9041.6103515625,
          y = 917.32000732422,
          z = 66.68699645996
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 354,
    from = {
      locaId = 528,
      flags = 86,
      loc = {
        mapId = 0,
        pos = {
          x = -9096.6201171875,
          y = 877.23199462891,
          z = 68.13980102539
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 529,
      flags = 20,
      loc = {
        mapId = 0,
        pos = {
          x = 8547.419921875,
          y = -4818.4399414062,
          z = 45.54690170288
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 15969,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = false
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 355,
    from = {
      locaId = 531,
      flags = 0,
      loc = {
        mapId = 1514,
        pos = {
          x = 768.81597900391,
          y = 3579.7299804688,
          z = 140.8869934082
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(12103)) end,
      important = true
    },
    to = {
      locaId = 532,
      flags = 0,
      loc = {
        mapId = 1220,
        pos = {
          x = -838.30999755859,
          y = 4317.4599609375,
          z = 744.79998779297
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(12103)) end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(12103)) end
  },
  {
    id = 358,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 535,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9076.490234375,
          y = 906.85601806641,
          z = 68.26239776611
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 359,
    from = {
      locaId = 535,
      flags = 68,
      loc = {
        mapId = 0,
        pos = {
          x = -9076.490234375,
          y = 906.85601806641,
          z = 68.26239776611
        }
      },
      type = 1,
      unknown1 = 10,
      uiMapHint = 10523,
      important = true
    },
    to = {
      locaId = 536,
      flags = 0,
      loc = {
        mapId = 2735,
        pos = {
          x = 3796.830078125,
          y = -157.16999816895,
          z = 192.5
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
  },
  {
    id = 360,
    from = {
      locaId = 538,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1448.6500244141,
          y = -4529.6801757812,
          z = 19.0468006134
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 537,
      flags = 0,
      loc = {
        mapId = 2736,
        pos = {
          x = 2074.0100097656,
          y = 184.83399963379,
          z = 175.96800231934
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  },
  {
    id = 361,
    from = {
      locaId = 8,
      flags = 84,
      loc = {
        mapId = 0,
        pos = {
          x = -9004.4443359375,
          y = 870.625,
          z = 64.86025238037
        }
      },
      type = 0,
      unknown1 = 30,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    to = {
      locaId = 528,
      flags = 86,
      loc = {
        mapId = 0,
        pos = {
          x = -9096.6201171875,
          y = 877.23199462891,
          z = 68.13980102539
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 10523,
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 5,
    skipOptimized = false
  },
  {
    id = 362,
    from = {
      locaId = 539,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -962.55603027344,
          y = 4067.2199707031,
          z = 648.18298339844
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_UnitAuras.GetPlayerAuraBySpellID(203211) ~= nil) end,
      important = false
    },
    to = {
      locaId = 540,
      flags = 16,
      loc = {
        mapId = 1519,
        pos = {
          x = 1474.1700439453,
          y = 1411.4599609375,
          z = 243.39999389648
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_UnitAuras.GetPlayerAuraBySpellID(203211) ~= nil) end,
      important = false
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (C_UnitAuras.GetPlayerAuraBySpellID(203211) ~= nil) end
  },
  {
    id = 364,
    from = {
      locaId = 543,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -841.49798583984,
          y = 4254.7900390625,
          z = 746.28100585938
        }
      },
      type = 1,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 544,
      flags = 16,
      loc = {
        mapId = 1479,
        pos = {
          x = 1028.6400146484,
          y = 7225.2299804688,
          z = 100.18000030518
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false
  },
  {
    id = 365,
    from = {
      locaId = 545,
      flags = 16,
      loc = {
        mapId = 1479,
        pos = {
          x = 1101.3800048828,
          y = 7223.7998046875,
          z = 89.88289642334
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 1) end,
      important = false
    },
    to = {
      locaId = 546,
      flags = 16,
      loc = {
        mapId = 1220,
        pos = {
          x = -835.44000244141,
          y = 4276.8198242188,
          z = 746.25
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (select(2, UnitClassBase("player")) == 1) end,
      important = false
    },
    bidirectional = false,
    cost = 5,
    skipOptimized = false,
    condition = function() return (select(2, UnitClassBase("player")) == 1) end
  },
  {
    id = 366,
    from = {
      locaId = 547,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8500.5400390625,
          y = -4372.3999023438,
          z = -6.72634983063
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 548,
      flags = 0,
      loc = {
        mapId = 2694,
        pos = {
          x = -266.76000976563,
          y = -444.85000610352,
          z = 934.08697509766
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 367,
    from = {
      locaId = 494,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8536.5,
          y = -4325.6298828125,
          z = 21.7091999054
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(86549) or C_QuestLog.IsQuestFlaggedCompleted(92423))) end,
      important = true
    },
    to = {
      locaId = 495,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 1551.4399414062,
          y = 1325.1899414062,
          z = 34.17539978027
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 368,
    from = {
      locaId = 549,
      flags = 0,
      loc = {
        mapId = 2694,
        pos = {
          x = -274.0710144043,
          y = -462.61599731445,
          z = 934.15301513672
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 550,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8485.76953125,
          y = -4361.6801757812,
          z = -7.40000009537
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 369,
    from = {
      locaId = 551,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 1543.3299560547,
          y = 1345.8900146484,
          z = 39.91070175171
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 552,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8554.2197265625,
          y = -4325.5600585938,
          z = 21.69000053406
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(86549) or C_QuestLog.IsQuestFlaggedCompleted(92423))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 370,
    from = {
      locaId = 554,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 3475.8000488281,
          y = -4463.2900390625,
          z = 137.57899475098
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 23,
      important = true
    },
    to = {
      locaId = 555,
      flags = 0,
      loc = {
        mapId = 95,
        pos = {
          x = 0.522194,
          y = 0.974291,
          z = 0
        },
        isUI = true
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 371,
    from = {
      locaId = 556,
      flags = 0,
      loc = {
        mapId = 95,
        pos = {
          x = 0.522194,
          y = 0.974291,
          z = 0
        },
        isUI = true
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 557,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 3468.419921875,
          y = -4479.6000976562,
          z = 137.32899475098
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 23,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 372,
    from = {
      locaId = 561,
      flags = 0,
      loc = {
        mapId = 2694,
        pos = {
          x = -285.5119934082,
          y = -434.51000976563,
          z = 934.04602050781
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 560,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 895.82000732422,
          y = -448.89001464844,
          z = -124.0240020752
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 373,
    from = {
      locaId = 558,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 882.46899414063,
          y = -456.63800048828,
          z = -123.43499755859
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 559,
      flags = 0,
      loc = {
        mapId = 2694,
        pos = {
          x = -266.76000976563,
          y = -444.85000610352,
          z = 934.08697509766
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 374,
    from = {
      locaId = 562,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 889.74499511719,
          y = -441.31399536133,
          z = -123.80999755859
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 552,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8554.2197265625,
          y = -4325.5600585938,
          z = 21.69000053406
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(86549) or C_QuestLog.IsQuestFlaggedCompleted(92423))) end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 376,
    from = {
      locaId = 566,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      actionOptions = {
        {
          type = "housing"
        }
      },
      important = false
    },
    to = {
      locaId = 567,
      flags = 0,
      loc = {
        mapId = 2735,
        pos = {
          x = 3796.830078125,
          y = -157.16999816895,
          z = 192.5
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return C_Housing and FarstriderLibData.HousingData end
  },
  {
    id = 377,
    from = {
      locaId = 568,
      flags = 8,
      dynLoc = function() return FarstriderLibData.Util.GetPlayerLocation() end,
      type = 1,
      unknown1 = 0,
      actionOptions = {
        {
          type = "housing"
        }
      },
      important = false
    },
    to = {
      locaId = 569,
      flags = 0,
      loc = {
        mapId = 2736,
        pos = {
          x = 2074.0100097656,
          y = 184.83399963379,
          z = 175.96800231934
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 1,
    skipOptimized = false,
    condition = function() return C_Housing and FarstriderLibData.HousingData end
  },
  {
    id = 378,
    from = {
      locaId = 494,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8536.5,
          y = -4325.6298828125,
          z = 21.7091999054
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return ((C_QuestLog.IsQuestFlaggedCompleted(86549) or C_QuestLog.IsQuestFlaggedCompleted(92423))) end,
      important = true
    },
    to = {
      locaId = 563,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 896.10400390625,
          y = -449.28900146484,
          z = -124.0240020752
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 383,
    from = {
      locaId = 578,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 7218.7700195312,
          y = -4106.7099609375,
          z = 105.43800354004
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 579,
      flags = 0,
      loc = {
        mapId = 2694,
        pos = {
          x = -180.49000549316,
          y = -2153.2199707031,
          z = 1176.6999511719
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 384,
    from = {
      locaId = 581,
      flags = 0,
      loc = {
        mapId = 2694,
        pos = {
          x = -241.53500366211,
          y = -2167.8400878906,
          z = 1175.0500488281
        }
      },
      type = 1,
      unknown1 = 0,
      important = true
    },
    to = {
      locaId = 580,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 7221.25,
          y = -4115.1899414062,
          z = 102.94999694824
        }
      },
      type = 2,
      unknown1 = 0,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 385,
    from = {
      locaId = 582,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 5120.2001953125,
          y = -10630.299804688,
          z = 125.26999664307
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 16365,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    to = {
      locaId = 583,
      flags = 0,
      loc = {
        mapId = 2916,
        pos = {
          x = 4487.0297851562,
          y = -10995,
          z = 0
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 16365,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 386,
    from = {
      locaId = 584,
      flags = 0,
      loc = {
        mapId = 2916,
        pos = {
          x = 4487.0297851562,
          y = -10995,
          z = 0
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 16535,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = false
    },
    to = {
      locaId = 585,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 5120.2001953125,
          y = -10630.299804688,
          z = 125.26999664307
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 16535,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 387,
    from = {
      locaId = 586,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 6255.6499023438,
          y = -10456.200195312,
          z = 68.2479019165
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 16365,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    to = {
      locaId = 587,
      flags = 0,
      loc = {
        mapId = 2916,
        pos = {
          x = 5381.4702148438,
          y = -11081.900390625,
          z = 42.93030166626
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 16365,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 388,
    from = {
      locaId = 588,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 4979.5,
          y = -10299.900390625,
          z = 218.12100219727
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 16365,
      important = true
    },
    to = {
      locaId = 589,
      flags = 0,
      loc = {
        mapId = 2916,
        pos = {
          x = 4636.9399414062,
          y = -9664.580078125,
          z = -11.73429965973
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 16365,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 389,
    from = {
      locaId = 590,
      flags = 0,
      loc = {
        mapId = 2916,
        pos = {
          x = 5381.4702148438,
          y = -11081.900390625,
          z = 42.93030166626
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 16535,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = false
    },
    to = {
      locaId = 591,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 6255.6499023438,
          y = -10456.200195312,
          z = 68.2479019165
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 16535,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 391,
    from = {
      locaId = 592,
      flags = 0,
      loc = {
        mapId = 2916,
        pos = {
          x = 4636.9399414062,
          y = -9664.580078125,
          z = -11.73429965973
        }
      },
      type = 1,
      unknown1 = 0,
      uiMapHint = 16535,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = false
    },
    to = {
      locaId = 593,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 4979.5,
          y = -10299.900390625,
          z = 218.12100219727
        }
      },
      type = 2,
      unknown1 = 0,
      uiMapHint = 16535,
      condition = function() return (UnitLevel("player") >= GetCorrectedLevel(1)) and (UnitLevel("player") <= GetCorrectedLevel(255)) end,
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  },
  {
    id = 392,
    from = {
      locaId = 594,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 820.03302001953,
          y = -426.62899780273,
          z = -114.42600250244
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsOnQuest(96052)) end,
      important = false
    },
    to = {
      locaId = 595,
      flags = 0,
      loc = {
        mapId = 3047,
        pos = {
          x = -3849.0300292969,
          y = 435.92199707031,
          z = 15.32089996338
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(96052)) end
  },
  {
    id = 393,
    from = {
      locaId = 596,
      flags = 0,
      loc = {
        mapId = 3047,
        pos = {
          x = -3849.0300292969,
          y = 435.92199707031,
          z = 15.32089996338
        }
      },
      type = 1,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 597,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 820.03302001953,
          y = -426.62899780273,
          z = -114.42600250244
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 394,
    from = {
      locaId = 598,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 820.03302001953,
          y = -426.62899780273,
          z = -114.42600250244
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsOnQuest(96051)) end,
      important = false
    },
    to = {
      locaId = 599,
      flags = 0,
      loc = {
        mapId = 3075,
        pos = {
          x = -2178.2399902344,
          y = -1759,
          z = 44.07030105591
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsOnQuest(96051)) end
  },
  {
    id = 395,
    from = {
      locaId = 600,
      flags = 0,
      loc = {
        mapId = 3075,
        pos = {
          x = -2178.2399902344,
          y = -1759,
          z = 44.07030105591
        }
      },
      type = 1,
      unknown1 = 0,
      important = false
    },
    to = {
      locaId = 601,
      flags = 0,
      loc = {
        mapId = 2771,
        pos = {
          x = 820.03302001953,
          y = -426.62899780273,
          z = -114.42600250244
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false
  },
  {
    id = 396,
    from = {
      locaId = 602,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8874.51953125,
          y = -4677.8999023438,
          z = 76.77439880371
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96053)) end,
      important = false
    },
    to = {
      locaId = 595,
      flags = 0,
      loc = {
        mapId = 3047,
        pos = {
          x = -3849.0300292969,
          y = 435.92199707031,
          z = 15.32089996338
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96053)) end
  },
  {
    id = 397,
    from = {
      locaId = 603,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8874.51953125,
          y = -4677.8999023438,
          z = 76.77439880371
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96054)) end,
      important = false
    },
    to = {
      locaId = 599,
      flags = 0,
      loc = {
        mapId = 3075,
        pos = {
          x = -2178.2399902344,
          y = -1759,
          z = 44.07030105591
        }
      },
      type = 2,
      unknown1 = 0,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96054)) end
  },
  {
    id = 401,
    from = {
      locaId = 612,
      flags = 0,
      loc = {
        mapId = 3047,
        pos = {
          x = -3849.0300292969,
          y = 435.92199707031,
          z = 15.32089996338
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96053)) end,
      important = false
    },
    to = {
      locaId = 613,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8874.51953125,
          y = -4677.8999023438,
          z = 76.77439880371
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96053)) end,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96053)) end
  },
  {
    id = 402,
    from = {
      locaId = 610,
      flags = 0,
      loc = {
        mapId = 3075,
        pos = {
          x = -2178.2399902344,
          y = -1759,
          z = 44.07030105591
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96054)) end,
      important = false
    },
    to = {
      locaId = 611,
      flags = 0,
      loc = {
        mapId = 0,
        pos = {
          x = 8874.51953125,
          y = -4677.8999023438,
          z = 76.77439880371
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96054)) end,
      important = false
    },
    bidirectional = false,
    cost = 0,
    skipOptimized = false,
    condition = function() return (C_QuestLog.IsQuestFlaggedCompleted(96054)) end
  },
  {
    id = 238,
    from = {
      locaId = 351,
      flags = 0,
      loc = {
        mapId = 1,
        pos = {
          x = 1842.1899414062,
          y = -4389.0400390625,
          z = 135.23300170898
        }
      },
      type = 1,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = true
    },
    to = {
      locaId = 352,
      flags = 0,
      loc = {
        mapId = 2532,
        pos = {
          x = 1805,
          y = 327,
          z = 70.5
        }
      },
      type = 2,
      unknown1 = 0,
      condition = function() return (UnitFactionGroup("player") == "Horde") end,
      important = false
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Horde") end
  }
}

FarstriderLibData.Waypoints = waypoints
