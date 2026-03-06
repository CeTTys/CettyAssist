local _, addon = ...

addon.profiles = {
    -- Example profile: Retribution Paladin (spec ID 70).
    ret_paladin = {
        id = "ret_paladin",
        name = "Retribution Paladin",
        specID = 70,
        spells = {
            templarsVerdict = 85256,
            divineStorm = 53385,
            wakeOfAshes = 255937,
            hammerOfWrath = 24275,
            bladeOfJustice = 184575,
            judgment = 20271,
            crusaderStrike = 35395,
            consecration = 26573,
            executionSentence = 343527,
            finalVerdictBuff = 383328,
        },
        rules = {
            {
                spell = "wakeOfAshes",
                when = function(s, p)
                    return s:Usable(p.spells.wakeOfAshes) and s.holyPower <= (s.maxHolyPower - 3)
                end,
            },
            {
                spell = "executionSentence",
                when = function(s, p)
                    return s:Usable(p.spells.executionSentence)
                        and s.holyPower >= 3
                        and s.targetExists
                end,
            },
            {
                spell = "hammerOfWrath",
                when = function(s, p)
                    return s:Usable(p.spells.hammerOfWrath)
                        and s.targetExists
                end,
            },
            {
                spell = "templarsVerdict",
                when = function(s, p)
                    return s:Usable(p.spells.templarsVerdict)
                        and s.holyPower >= 5
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "bladeOfJustice",
                when = function(s, p)
                    return s:Usable(p.spells.bladeOfJustice)
                        and s.targetExists
                end,
            },
            {
                spell = "judgment",
                when = function(s, p)
                    return s:Usable(p.spells.judgment)
                        and s.targetExists
                end,
            },
            {
                spell = "crusaderStrike",
                when = function(s, p)
                    local charges = s:Charges(p.spells.crusaderStrike)
                    return s:Usable(p.spells.crusaderStrike)
                        and s.targetExists
                        and s.inMeleeRange
                        and charges >= 1
                end,
            },
            {
                spell = "templarsVerdict",
                when = function(s, p)
                    return s:Usable(p.spells.templarsVerdict)
                        and s.holyPower >= 3
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "consecration",
                when = function(s, p)
                    return s:Usable(p.spells.consecration)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
        },
    },
    enh_shaman = {
        id = "enh_shaman",
        name = "Enhancement Shaman",
        specID = 263,
        spells = {
            stormstrike = 17364,
            lavaLash = 60103,
            lightningBolt = 188196,
            crashLightning = 187874,
            primordialWave = 375982,
            feralSpirit = 51533,
            flameShock = 188389,
            sundering = 197214,
            maelstromWeaponBuff = 344179,
        },
        rules = {
            {
                spell = "primordialWave",
                when = function(s, p)
                    return s:Usable(p.spells.primordialWave)
                        and s.targetExists
                end,
            },
            {
                spell = "feralSpirit",
                when = function(s, p)
                    return s:Usable(p.spells.feralSpirit)
                        and s.targetExists
                end,
            },
            {
                spell = "flameShock",
                when = function(s, p)
                    local hasFlameShock, fsRemains = s:TargetDebuff(p.spells.flameShock)
                    return s:Usable(p.spells.flameShock)
                        and s.targetExists
                        and (not hasFlameShock or fsRemains < 5)
                end,
            },
            {
                spell = "lightningBolt",
                when = function(s, p)
                    local mwStacks = s:PlayerBuffStacks(p.spells.maelstromWeaponBuff)
                    return s:Usable(p.spells.lightningBolt)
                        and s.targetExists
                        and mwStacks >= 10
                end,
            },
            {
                spell = "stormstrike",
                when = function(s, p)
                    return s:Usable(p.spells.stormstrike)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "sundering",
                when = function(s, p)
                    return s:Usable(p.spells.sundering)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "lavaLash",
                when = function(s, p)
                    return s:Usable(p.spells.lavaLash)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "crashLightning",
                when = function(s, p)
                    return s:Usable(p.spells.crashLightning)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "lightningBolt",
                when = function(s, p)
                    local mwStacks = s:PlayerBuffStacks(p.spells.maelstromWeaponBuff)
                    return s:Usable(p.spells.lightningBolt)
                        and s.targetExists
                        and mwStacks >= 5
                end,
            },
        },
    },
    balance_druid = {
        id = "balance_druid",
        name = "Balance Druid",
        specID = 102,
        spells = {
            moonfire = 8921,
            sunfire = 93402,
            starsurge = 78674,
            starfall = 191034,
            wrath = 190984,
            starfire = 194153,
            furyOfElune = 202770,
            warriorOfElune = 202425,
        },
        rules = {
            {
                spell = "moonfire",
                when = function(s, p)
                    local hasMoonfire, moonfireRemains = s:TargetDebuff(p.spells.moonfire)
                    return s:Usable(p.spells.moonfire)
                        and s.targetExists
                        and (not hasMoonfire or moonfireRemains < 5)
                end,
            },
            {
                spell = "sunfire",
                when = function(s, p)
                    local hasSunfire, sunfireRemains = s:TargetDebuff(p.spells.sunfire)
                    return s:Usable(p.spells.sunfire)
                        and s.targetExists
                        and (not hasSunfire or sunfireRemains < 5)
                end,
            },
            {
                spell = "furyOfElune",
                when = function(s, p)
                    return s:Usable(p.spells.furyOfElune)
                        and s.targetExists
                end,
            },
            {
                spell = "starsurge",
                when = function(s, p)
                    return s:Usable(p.spells.starsurge)
                        and s.targetExists
                        and s.astralPower >= 90
                end,
            },
            {
                spell = "warriorOfElune",
                when = function(s, p)
                    return s:Usable(p.spells.warriorOfElune)
                        and s.targetExists
                end,
            },
            {
                spell = "starsurge",
                when = function(s, p)
                    return s:Usable(p.spells.starsurge)
                        and s.targetExists
                        and s.astralPower >= 50
                end,
            },
            {
                spell = "wrath",
                when = function(s, p)
                    return s:Usable(p.spells.wrath)
                        and s.targetExists
                end,
            },
            {
                spell = "starfire",
                when = function(s, p)
                    return s:Usable(p.spells.starfire)
                        and s.targetExists
                end,
            },
        },
    },
    feral_druid = {
        id = "feral_druid",
        name = "Feral Druid",
        specID = 103,
        spells = {
            rake = 1822,
            rip = 1079,
            ferociousBite = 22568,
            shred = 5221,
            thrash = 106830,
            tigersFury = 5217,
            berserk = 106951,
            brutalSlash = 202028,
        },
        rules = {
            {
                spell = "tigersFury",
                when = function(s, p)
                    return s:Usable(p.spells.tigersFury)
                        and s.targetExists
                        and s.energy <= 40
                end,
            },
            {
                spell = "berserk",
                when = function(s, p)
                    return s:Usable(p.spells.berserk)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "rake",
                when = function(s, p)
                    local hasRake, rakeRemains = s:TargetDebuff(p.spells.rake)
                    return s:Usable(p.spells.rake)
                        and s.targetExists
                        and s.inMeleeRange
                        and (not hasRake or rakeRemains < 4)
                end,
            },
            {
                spell = "thrash",
                when = function(s, p)
                    local hasThrash, thrashRemains = s:TargetDebuff(p.spells.thrash)
                    return s:Usable(p.spells.thrash)
                        and s.targetExists
                        and s.inMeleeRange
                        and (not hasThrash or thrashRemains < 4)
                end,
            },
            {
                spell = "rip",
                when = function(s, p)
                    local hasRip, ripRemains = s:TargetDebuff(p.spells.rip)
                    return s:Usable(p.spells.rip)
                        and s.targetExists
                        and s.inMeleeRange
                        and s.comboPoints >= 5
                        and (not hasRip or ripRemains < 5)
                end,
            },
            {
                spell = "ferociousBite",
                when = function(s, p)
                    return s:Usable(p.spells.ferociousBite)
                        and s.targetExists
                        and s.inMeleeRange
                        and s.comboPoints >= 5
                end,
            },
            {
                spell = "brutalSlash",
                when = function(s, p)
                    return s:Usable(p.spells.brutalSlash)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
            {
                spell = "shred",
                when = function(s, p)
                    return s:Usable(p.spells.shred)
                        and s.targetExists
                        and s.inMeleeRange
                end,
            },
        },
    },
}
