if (APR.Faction == "Alliance") then
    APR.RouteQuestStepList["97-AmmenVale"] = {
        { PickUp = { 9279 },                           Coord = { y = -3961.4, x = -13926.8 } },
        { Done = { 9279 },                             Coord = { y = -4038.9, x = -13773.2 } },
        { PickUp = { 9280 },                           Coord = { y = -4038.2, x = -13773.2 } },
        { Qpart = { [9280] = { 1 } },                  Range = 66.34,                        Coord = { y = -3943.5, x = -13694.5 } },
        { Done = { 9280 },                             Coord = { y = -4038.9, x = -13773.2 } },
        { PickUp = { 9409 },                           Coord = { y = -4039, x = -13773.3 } },
        { Done = { 9409 },                             Coord = { y = -4119.2, x = -13760.8 } },
        { PickUp = { 9283 },                           Coord = { y = -4116.9, x = -13761 } },
        { PickUp = { 9371 },                           Coord = { y = -4039.2, x = -13773.5 } },
        { Done = { 9371 },                             Coord = { y = -4056.2, x = -13720.8 } },
        { PickUp = { 10302 },                          Coord = { y = -4056.2, x = -13720.8 } },
        { Qpart = { [10302] = { 1 }, [9283] = { 1 } }, Range = 84,                           Coord = { y = -3995.7, x = -13624.8 } },
        { Done = { 10302 },                            Coord = { y = -4056.7, x = -13721 } },
        { PickUp = { 9293, 9799 },                     Coord = { y = -4057.5, x = -13720 } },
        { Done = { 9283 },                             Coord = { y = -4114.3, x = -13761.5 } },
        { PickUp = { 37445, 37444 },                   Coord = { y = -4189.9, x = -13734.8 } },
        { Qpart = { [9799] = { 1 }, [9293] = { 1 } },  Range = 60.33,                        Coord = { y = -4159.5, x = -13491.5 } },
        {
            Waypoint = 37445,
            Fillers = { [37444] = { 1 }, [37445] = { 1 } },
            Button = { ["37444-1"] = 22962 },
            Range = 15.97,
            Coord = { y = -4458.9, x = -13875.7 }
        },
        {
            Qpart = { [37445] = { 1 }, [37444] = { 1 } },
            Button = { ["37444-1"] = 22962 },
            Range = 62.89,
            Coord = { y = -4597.5, x = -13977.8 }
        },
        { Done = { 37445, 37444 },     Coord = { y = -4188.4, x = -13734 } },
        { PickUp = { 9309 },           Coord = { y = -4193.4, x = -13735.8 } },
        { Done = { 9293, 9799 },       Coord = { y = -4057, x = -13720.8 } },
        { PickUp = { 9294 },           Coord = { y = -4056.7, x = -13721 } },
        { Qpart = { [9294] = { 1 } },  Button = { ["9294-1"] = 22955 },      Range = 0.69,                         Coord = { y = -4385.9, x = -13635 } },
        { Done = { 9309 },             Coord = { y = -4445.5, x = -13430.5 } },
        { PickUp = { 10303 },          Coord = { y = -4444.9, x = -13430.8 } },
        { Qpart = { [10303] = { 1 } }, Range = 48.51,                        Coord = { y = -4519.8, x = -13361 } },
        { Done = { 10303 },            Coord = { y = -4444.3, x = -13430.8 } },
        { PickUp = { 9311 },           Coord = { y = -4444.3, x = -13430.8 } },
        { Qpart = { [9311] = { 1 } },  Range = 0.69,                         Coord = { y = -4578.4, x = -13319.8 } },
        {
            DroppableQuest = { Text = "Surveyor Candress", Qid = 9798, MobId = 16522 },
            DropQuest = 9798,
            Coord = { y = -4576.4, x = -13318.5 }
        },
        { Done = { 9798, 9311 }, Coord = { y = -4194.5, x = -13735.5 } },
        { PickUp = { 9312 },     Coord = { y = -4194.3, x = -13735.2 } },
        { Done = { 9312 },       Coord = { y = -4185.3, x = -13734.3 } },
        { PickUp = { 9313 },     Coord = { y = -4185.3, x = -13734.3 } },
        { Done = { 9294 },       Coord = { y = -4056.7, x = -13721.7 } },
        { PickUp = { 9314 },     Coord = { y = -4260.5, x = -13125 } },
        { ZoneDoneSave = 1 }
    }
end
