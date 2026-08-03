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
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
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
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
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
        mapId = 530,
        pos = {
          x = 12803.700195312,
          y = -6907.3798828125,
          z = 41.11640167236
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
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = true,
    cost = 0,
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
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 10,
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
      condition = function() return (UnitFactionGroup("player") == "Alliance") end,
      important = true
    },
    bidirectional = false,
    cost = 10,
    skipOptimized = false,
    condition = function() return (UnitFactionGroup("player") == "Alliance") end
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
      important = true
    },
    to = {
      locaId = 555,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 6123.2299804688,
          y = -7006.5698242188,
          z = 138.50799560547
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
    id = 371,
    from = {
      locaId = 556,
      flags = 0,
      loc = {
        mapId = 530,
        pos = {
          x = 6109.8500976562,
          y = -6997.080078125,
          z = 137.48199462891
        }
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
      important = true
    },
    bidirectional = false,
    cost = 30,
    skipOptimized = false
  }
}

FarstriderLibData.Waypoints = waypoints
