if (APR.Faction == "Horde") then
    APR.RouteQuestStepList["467-EversongWoodsBloodElf"] = {
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
        { Fillers = { [37439] = { 1 } },        Done = { 8327 },                     SpellButton = { ["37439-1"] = 28730 }, Coord = { y = 10302.4, x = -6228.9 } },
        { PickUp = { 8334 },                    Coord = { y = 10302.4, x = -6228.9 } },
        {
            Qpart = { [37439] = { 1 } },
            Fillers = { [37440] = { 1 } },
            SpellButton = { ["37439-1"] = 28730 },
            Range = 48.9,
            Coord = { y = 10333.5, x = -6270.3 }
        },
        { Fillers = { [37440] = { 1 } }, Done = { 37439 },              Coord = { y = 10419.2, x = -6317.7 } },
        { Qpart = { [37443] = { 3 } },   Fillers = { [37440] = { 1 } }, Range = 0.75,                        Coord = { y = 10224.7, x = -6343 } },
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
        { Coord = { y = 9984.6, x = -6477.7 },  Done = { 9705 } },
        { PickUp = { 8350 },                    Coord = { y = 9984.6, x = -6477.7 } },
        { Coord = { y = 9477.1, x = -6858.2 },  Done = { 8350 } },
        { ZoneDoneSave = 1 }
    }
end
