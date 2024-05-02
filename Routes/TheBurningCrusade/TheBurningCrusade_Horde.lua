if APR.Faction == "Horde" then
    APR.RouteQuestStepList["467-BloodElf-intro"] = {
        { PickUp = { 8325 },                    Coord = { y = 10352.2, x = -6359 } },
        { Qpart = { [8325] = { 1 } },           Range = 66.61,                       Coord = { y = 10382.1, x = -6203.1 } },
        { Coord = { y = 10352.6, x = -6359.5 }, Done = { 8325 } },
        { PickUp = { 8326 },                    Coord = { y = 10352.6, x = -6359.5 } },
        { Range = 16.4,                         Waypoint = 8326,                     Coord = { y = 10388.5, x = -6385.3 } },
        { Qpart = { [8326] = { 1 } },           Range = 45.33,                       Coord = { x = -6462.2, y = 10453.6 } },
        { Coord = { y = 10352.5, x = -6359.9 }, Done = { 8326 } },
        { PickUp = { 8327 },                    Coord = { y = 10352.5, x = -6359.9 } },
        { PickUp = { 37442, 37443 },            Coord = { y = 10377.2, x = -6405.9 } },
        { PickUp = { 37440 },                   Coord = { y = 10414, x = -6372.3 } },
        { PickUp = { 37439 },                   Coord = { y = 10420.2, x = -6317.9 } },
        {
            Fillers = { [37439] = { 1 } },
            Done = { 8327 },
            SpellButton = { ["37439-1"] = 28730 },
            Coord = { y = 10302.4, x = -6228.9 }
        },
        { PickUp = { 8334 },             Coord = { y = 10302.4, x = -6228.9 } },
        {
            Qpart = { [37439] = { 1 } },
            Fillers = { [37440] = { 1 } },
            SpellButton = { ["37439-1"] = 28730 },
            Range = 48.9,
            Coord = { y = 10333.5, x = -6270.3 }
        },
        { Fillers = { [37440] = { 1 } }, Done = { 37439 },                    Coord = { y = 10419.2, x = -6317.7 } },
        { Qpart = { [37443] = { 3 } },   Fillers = { [37440] = { 1 } },       Range = 0.75,                        Coord = { y = 10224.7, x = -6343 } },
        {
            Qpart = { [37443] = { 1 } },
            Fillers = { [37440] = { 1 }, [8334] = { 1, 2 } },
            Range = 0.69,
            Coord = { y = 10093.2, x = -6217.2 }
        },
        { Qpart = { [37443] = { 2 } },          Fillers = { [8334] = { 1, 2 } },     Range = 0.69,                        Coord = { y = 10295.2, x = -6029.9 } },
        { Qpart = { [37442] = { 1 } },          Fillers = { [8334] = { 1, 2 } },     Range = 0.69,                        Coord = { y = 10404.7, x = -5946.7 } },
        { Qpart = { [8334] = { 1, 2 } },        Range = 44.84,                       Coord = { y = 10309.6, x = -6009.7 } },
        { Qpart = { [37440] = { 1 } },          Range = 45.26,                       Coord = { y = 10336.1, x = -6156.5 } },
        { Coord = { y = 10302.9, x = -6229.4 }, Done = { 8334 } },
        { PickUp = { 8335 },                    Coord = { y = 10302.9, x = -6228.8 } },
        { Range = 16.57,                        Waypoint = 37442,                    Coord = { y = 10353.2, x = -6386.9 } },
        { Coord = { y = 10377.4, x = -6405.8 }, Done = { 37442, 37443 } },
        { Coord = { y = 10414.4, x = -6371.8 }, Done = { 37440 } },
        { Range = 11.29,                        Waypoint = 8335,                     Coord = { y = 10206.7, x = -6096.3 } },
        {
            Qpart = { [8335] = { 1, 3, 2 } },
            RaidIcon = 15367,
            ExtraLineText = "UPTOP",
            Range = 0.75,
            Coord = { y = 10151.4, x = -6005.5 }
        },
        {
            Coord = { y = 10140.6, x = -6003.8 },
            DropQuest = 8338,
            DroppableQuest = { Text = "Tainted Arcane Wraith", MobId = 15298, Qid = 8338 }
        },
        { Coord = { y = 10302.7, x = -6228.8 }, Done = { 8335 } },
        { PickUp = { 8347 },                    Coord = { y = 10302.7, x = -6228.8 } },
        { Coord = { y = 10420.2, x = -6318.2 }, Done = { 8338 } },
        { Coord = { y = 9984.5, x = -6477.9 },  Done = { 8347 } },
        { PickUp = { 9704 },                    Coord = { y = 9984.5, x = -6477.9 } },
        { Coord = { y = 9871.6, x = -6557.4 },  Done = { 9704 } },
        { PickUp = { 9705 },                    Coord = { y = 9871.6, x = -6557.4 } },
        { Done = { 9705 },                      Coord = { y = 9984.6, x = -6477.7 } },
        { PickUp = { 8350 },                    Coord = { y = 9984.6, x = -6477.7 } },
        { Done = { 8350 },                      Coord = { y = 9477.1, x = -6858.2 } },
        { Waypoint = 1,                         Coord = { y = 9473.5, x = -6844.6000976562 },         Range = 5,                                   Zone = 94 },
        { Waypoint = 1,                         Coord = { y = 9490.400390625, x = -6838.8002929688 }, Range = 5,                                   Zone = 94 },
        { PickUp = { 8463 },                    Coord = { y = 9530.900390625, x = -6859.8002929688 }, Zone = 94 },
        { PickUp = { 8468 },                    Coord = { y = 9522.900390625, x = -6858.5 },          Zone = 94 },
        { PickUp = { 8472 },                    Zone = 94,                                            Coord = { y = 9520.5, x = -6814.8999023438 } },
        {
            Qpart = { [8468] = { 1 } },
            Zone = 94,
            Fillers = { [8472] = { 1 }, [8463] = { 1 } },
            Range = 30,
            Coord = { y = 9803.5, x = -6706.7001953125 }
        },
        {
            Zone = 94,
            Qpart = { [8472] = { 1 }, [8463] = { 1 } },
            Range = 69,
            Coord = { y = 9705.6005859375, x = -6784.8999023438 }
        },
        { Done = { 8472 },   Zone = 94,                                            Coord = { y = 9522.5, x = -6811.8999023438 } },
        { PickUp = { 8895 }, Coord = { y = 9522.5, x = -6811.8999023438 },         Zone = 94 },
        { Done = { 8463 },   Coord = { y = 9529.900390625, x = -6857.2001953125 }, Zone = 94 },
        { PickUp = { 9352 }, Coord = { y = 9529.900390625, x = -6857.2001953125 }, Zone = 94 },
        { Done = { 8468 },   Coord = { y = 9513.400390625, x = -6841.3999023438 }, Zone = 94 },
        { Waypoint = 9352,   Zone = 94,                                            Range = 5,                                   Coord = { y = 9467.5, x = -6781.2001953125 } },
        { PickUp = { 8475 }, RaidIcon = 15654,                                     Zone = 94,                                   Coord = { y = 9374.2001953125, x = -6964.1000976562 } },
        {
            Qpart = { [8475] = { 1 } },
            Zone = 94,
            RaidIcon = 15416,
            Range = 30,
            Coord = { y = 9262.900390625, x = -6970.7001953125 }
        },
        { Zone = 94,         RaidIcon = 15405, Done = { 8475 },                                      Coord = { y = 9373.1005859375, x = -6967 } },
        { Done = { 8895 },   Zone = 94,        Coord = { y = 9296.7001953125, x = -6687.1000976562 } },
        { PickUp = { 9119 }, Zone = 94,        Coord = { y = 9296.7001953125, x = -6687.1000976562 } },
        { Waypoint = 9119,   Zone = 94,        Range = 5,                                            Coord = { y = 9227.7001953125, x = -6554.2001953125 } },
        { Zone = 94,         Waypoint = 9119,  RaidIcon = 15401,                                     Range = 5,                                            Coord = { y = 9185, x = -6422.1000976562 } },
        { Done = { 9119 },   Zone = 94,        Coord = { y = 9156.1005859375, x = -6297 } },
        { PickUp = { 8486 }, RaidIcon = 15648, Zone = 94,                                            Coord = { y = 9156.1005859375, x = -6297 } },
        {
            Qpart = { [9352] = { 1 } },
            Zone = 94,
            Fillers = { [8486] = { 1, 2 } },
            Range = 30,
            Coord = { y = 9060.6005859375, x = -6171.6000976562 }
        },
        { PickUp = { 8482 },     Zone = 94,                                             Coord = { y = 9060.6005859375, x = -6171.6000976562 } },
        {
            Qpart = { [8486] = { 1, 2 } },
            Zone = 94,
            RaidIcon = 15401,
            Range = 30,
            Coord = { y = 9068.6005859375, x = -6209.2001953125 }
        },
        { Done = { 8486, 9352 }, Coord = { y = 9153, x = -6293.1000976562 },            Zone = 94 },
        { Waypoint = 8482,       Coord = { y = 9177, x = -6367.2001953125 },            Range = 5,                                            Zone = 94 },
        { Waypoint = 8482,       Coord = { y = 9182.7001953125, x = -6418.8002929688 }, Range = 5,                                            Zone = 94 },
        { Waypoint = 8482,       Coord = { y = 9159.7998046875, x = -6473 },            Range = 5,                                            Zone = 94 },
        {
            Zone = 94,
            Waypoint = 8482,
            RaidIcon = 16210,
            Range = 5,
            Coord = { y = 8968.1005859375, x = -6678.3002929688 }
        },
        {
            PickUp = { 9144, 9254, 9395 },
            RaidIcon = 15397,
            Coord = { y = 8719.400390625, x = -6657.7001953125 },
            Zone = 94
        },
        { PickUp = { 9358 },                                     RaidIcon = 16261,                                      Coord = { y = 8702.400390625, x = -6640.2001953125 },  Zone = 94 },
        { PickUp = { 9130 },                                     Coord = { y = 8694.2001953125, x = -6639.3999023438 }, Zone = 94 },
        { Done = { 9130 },                                       Coord = { y = 8743.7998046875, x = -6654.1000976562 }, Zone = 94 },
        { PickUp = { 9133 },                                     RaidIcon = 15942,                                      Coord = { y = 8743.7998046875, x = -6654.1000976562 }, Zone = 94 },
        { Done = { 9358 },                                       Coord = { y = 8685.7001953125, x = -6797.6000976562 }, Zone = 94 },
        { PickUp = { 9252 },                                     RaidIcon = 15658,                                      Coord = { y = 8685.7001953125, x = -6797.6000976562 }, Zone = 94 },
        { Fillers = { [9252] = { 1 } },                          Done = { 9254 },                                       Coord = { y = 8710.7001953125, x = -7161 },            Zone = 94 },
        { PickUp = { 8487 },                                     Coord = { y = 8709.900390625, x = -7160.3999023438 },  Zone = 94 },
        { Qpart = { [9252] = { 1 }, [8487] = { 1 } },            RaidIcon = 15402,                                      Range = 60,                                            Zone = 94 },
        { Coord = { y = 8708.7001953125, x = -7159.6000976562 }, RaidIcon = 15402,                                      Done = { 8487 },                                       Zone = 94 },
        { PickUp = { 8488 },                                     Coord = { y = 8708.7001953125, x = -7159.6000976562 }, Zone = 94 },
        {
            GossipOptionIDs = { 46851 },
            Qpart = { [8488] = { 1 } },
            Zone = 94,
            RaidIcon = 15402,
            Range = 30,
            Coord = { y = 8711.1005859375, x = -7161.2001953125 }
        },
        { Qpart = { [8488] = { 2 } }, Zone = 94,                                             RaidIcon = 15402, Range = 30, Coord = { y = 8747, x = -7134.7001953125 } },
        { Done = { 8488 },            Coord = { y = 8710.7001953125, x = -7160.2001953125 }, Zone = 94 },
        { PickUp = { 9255 },          Coord = { y = 8710.7001953125, x = -7160.2001953125 }, Zone = 94 },
        {
            Qpart = { [9252] = { 2 } },
            Zone = 94,
            RaidIcon = 15942,
            Range = 30,
            Coord = { y = 8461.2998046875, x = -6991.7001953125 }
        },
        { Done = { 9252 },   Zone = 94,        Coord = { y = 8683.2998046875, x = -6798.5 } },
        { PickUp = { 9253 }, RaidIcon = 16210, Zone = 94,                                            Coord = { y = 8683.2998046875, x = -6798.5 } },
        { Done = { 9255 },   Zone = 94,        Coord = { y = 8719.1005859375, x = -6658.2001953125 } },
        { Zone = 94,         RaidIcon = 15403, GetFP = 625,                                          Coord = { y = 8743.6005859375, x = -6657.3999023438 } },
        { Done = { 8482 },   Zone = 94,        Coord = { y = 9531, x = -6857.8999023438 } },
        { Zone = 94,         Grind = 10 },
        { PickUp = { 8483 }, Zone = 94,        Coord = { y = 9530.2001953125, x = -6858.3002929688 } },
        {
            UseFlightPath = 8483,
            ETA = 15,
            Zone = 94,
            NodeID = 82,
            Coord = { y = 9447.2998046875, x = -6780.6000976562 }
        },
        { Waypoint = 8483, Coord = { y = 9376.7001953125, x = -7263.2001953125 }, Range = 5, Zone = 94 },
        { Waypoint = 8483, Coord = { y = 9417.2998046875, x = -7275 },            Range = 5, Zone = 94 },
        { Waypoint = 8483, Coord = { y = 9421.7001953125, x = -7256.3999023438 }, Range = 5, Zone = 94 },
        { Waypoint = 8483, Coord = { y = 9458, x = -7256.3002929688 },            Range = 5, Zone = 110 },
        { Waypoint = 8483, Coord = { y = 9465.7001953125, x = -7277.8999023438 }, Range = 5, Zone = 110 },
        { Waypoint = 8483, Coord = { y = 9531.7998046875, x = -7242.8999023438 }, Range = 5, Zone = 110 },
        { Waypoint = 8483, Coord = { y = 9555.900390625, x = -7228.5 },           Range = 5, Zone = 110 },
        { Waypoint = 8483, Coord = { y = 9568.7001953125, x = -7195.3999023438 }, Range = 5, Zone = 110 },
        { Done = { 9133 }, Coord = { y = 9580.2998046875, x = -7054.8002929688 }, Zone = 110 },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9677.2001953125, x = -7210.8999023438 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9699.2998046875, x = -7219.6000976562 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9679.1005859375, x = -7234.8002929688 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9678.1005859375, x = -7291 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9698.6005859375, x = -7301.5 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9678, x = -7317.5 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9733.400390625, x = -7319.8002929688 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9844.1005859375, x = -7265.3999023438 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9872.7001953125, x = -7231.3002929688 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9891.5, x = -7231.2001953125 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9892.2998046875, x = -7175.5 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9957, x = -7095.8999023438 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 9981.2998046875, x = -7093.3002929688 }
        },
        {
            Zone = 110,
            Waypoint = 9134,
            ExtraLineText = "USE_ORGRIMMAR_PORTAL",
            Range = 5,
            Coord = { y = 10003.400390625, x = -7110.1000976562 }
        },
        { Waypoint = 8483,       Coord = { y = 1437.9000244141, x = -4433.3002929688 }, Range = 5, Zone = 85 },
        { Waypoint = 8483,       Coord = { y = 1489.4000244141, x = -4417.1000976562 }, Range = 5, Zone = 85 },
        { Waypoint = 8483,       Coord = { y = 1546.8000488281, x = -4376.8002929688 }, Range = 5, Zone = 85 },
        { Waypoint = 8483,       Coord = { y = 1615.2000732422, x = -4282.6000976562 }, Range = 5, Zone = 85 },
        { Waypoint = 8483,       Coord = { y = 1639.4000244141, x = -4270 },            Range = 5, Zone = 85 },
        { Waypoint = 8483,       Coord = { y = 1606.2000732422, x = -4265.6000976562 }, Range = 5, Zone = 85 },
        { Waypoint = 8483,       Coord = { y = 1589.5, x = -4215.1000976562 },          Range = 5, Zone = 85 },
        { LeaveQuests = { 9144 } },
        { ZoneDoneSave = 1 }
    }
end
