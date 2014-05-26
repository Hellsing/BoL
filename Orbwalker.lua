local version = 1.03
local AUTOUPDATE = true
local SCRIPT_NAME = "Orbwalker"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
    require("SourceLib")
else
    DOWNLOADING_SOURCELIB = true
    DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
     SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/Hellsing/BoL/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/Hellsing/BoL/master/version/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local _TOMOUSE, _TOTARGET, _EMPOWER = 100, 101, 201

local MySpells = {}

local Spells =
{
    ["MissFortune"] = {
        [_Q] = {name = "Double Up", spellType = _TOTARGET, range = 650},
        [_W] = {name = "Impure shots", spellType = _EMPOWER, range = -1}
    },

    ["Sivir"] = {
        [_Q] = {name = "Boomerang blade", skillshot = true, spellType = SKILLSHOT_LINEAR, range = 1175, width = 90, speed = 1350, delay = 0.25, collision = false},
        [_W] = {name = "Ricochet", spellType = _EMPOWER, range = -1}
    },

    ["Jax"] = {
        [_Q] = {name = "Leap Strike", spellType = _TOTARGET, range = 700},
        [_W] = {name = "Empower", spellType = _EMPOWER, range = -1},
        [_E] = {name = "Counter Strike", spellType = _EMPOWER, range = -1},
        [_R] = {name = "Grandmaster's Might", spellType = _EMPOWER, range = -1},
    },

    ["Tristana"] = {
        [_Q] = {name = "Rapid Fire", spellType = _EMPOWER, range = -1},
        [_E] = {name = "Explosive Shot", spellType = _TOTARGET, range = -1},
    },

    ["Teemo"] = {
        [_Q] = {name = "Blinding dart", spellType = _TOTARGET, range = 680}
    },

    ["Taric"] = {
        [_E] = {name = "Dazzle", spellType = _TOTARGET, range = 625}
    },

    ["Lucian"] = {
        [_Q] = {name = "Piercing Light", spellType = _TOTARGET, range = 550},
        [_W] = {name = "Mistic Shot", skillshot = true, spellType = SKILLSHOT_LINEAR, range = 1000, width = 55, speed = 1600, delay = 0.25, collision = false},
    },

    ["Khazix"] = {
        [_Q] = {name = "Taste Their Fear", spellType = _TOTARGET, range = -1},
        [_W] = {name = "Void Spikes", skillshot = true, spellType = SKILLSHOT_LINEAR, range = 1025, width = 70, speed = 1700, delay = 0.25, collision = true},
        [_E] = {name = "Leap", skillshot = true, spellType = SKILLSHOT_CIRCULAR, range = function() return myHero:GetSpellData(_E).range end, width = 100, speed = 1000, delay = 0.25, AOE = true},
    },

    ["Vayne"] = {
        [_Q] = {name = "Tumble", spellType = _TOMOUSE, range = -1}
    },

    ["Zed"] = {
        [_Q] = {name = "Razor Shuriken", skillshot = true, spellType = SKILLSHOT_CONE, range = 925, width = 50, speed = 1700, delay = 0.25, AOE = true, collision = false},
        [_E] = {name = "Shadow Slash", spellType = SKILLSHOT_CIRCULAR, range = 290, width = 1, speed = math.huge, delay = 0.25, AOE = false, collision = false},
    },

    ["Graves"] = {
        [_Q] = {name = "Buckshot", skillshot = true, spellType = SKILLSHOT_CONE, range = 700, width = 15.32 * math.pi / 180, speed = 902, delay = 0.25, AOE = true, collision = false},
        [_W] = {name = "Smoke screen", spellType = SKILLSHOT_CIRCULAR, range = 900, width = 250, speed = 1650, delay = 0.25, AOE = true, collision = false},
        [_E] = {name = "Quckdraw", spellType = _TOMOUSE, range = -1},
    },

    ["Ezreal"] = {
        [_Q] = {name = "Mistic Shot", skillshot = true, spellType = SKILLSHOT_LINEAR, range = 1200, width = 60, speed = 2000, delay = 0.25, collision = true},
        [_W] = {name = "Essence Flux", skillshot = true, spellType = SKILLSHOT_LINEAR, range = 1050, width = 80, speed = 1600, delay = 0.25, AOE = true},
    },

    ["Ashe"] = {
        [_W] = {name = "Volley", skillshot = true, spellType = SKILLSHOT_CONE, range = 1050, width = 57.5 * math.pi / 180, speed = 1600, delay = 0.25, AOE = true, collision = false},
    },
}

function OnLoad()
    DelayAction(DelayedLoad, 1)
end

function CastSpells(target, mode)
    for id, spell in pairs(Spells[myHero.charName]) do
        if Menu["Spells"..myHero.charName]["id"..id].Enabled and Menu["Spells"..myHero.charName]["id"..id]["Mode"..mode] and Menu["Spells"..myHero.charName]["id"..id][tostring(string.gsub(target.type, "_", ""))] then
            local range = spell.range == -1 and SOWi:MyRange() or spell.range
            if type(range) == "function" then
                range = range(target)
            end
            MySpells[id]:SetRange(range)

            if spell.spellType == _TOMOUSE and GetDistanceSqr(target) < MySpells[id].rangeSqr then
                CastSpell(id, mousePos.x, mousePos.z)
            elseif spell.spellType == _TOTARGET and GetDistanceSqr(target) < MySpells[id].rangeSqr then
                CastSpell(id, target)
            elseif spell.spellType == _EMPOWER and GetDistanceSqr(target) < MySpells[id].rangeSqr then
                CastSpell(id)
            elseif GetDistanceSqr(target) < MySpells[id].rangeSqr then
                MySpells[id]:Cast(target)
            end
        end
    end
end

function AfterAttack(target, mode)
    if target and target.type and Spells[myHero.charName] and ValidTarget(target) then
        CastSpells(target, mode)
    end
end

function DelayedLoad()
    if not _G.SOWLoaded then
        DManager = DrawManager()
        VP = VPrediction(true)
        STS = SimpleTS(STS_LESS_CAST_PHYSICAL)
        SOWi = SOW(VP, STS)

        --Load the spells:
        if Spells[myHero.charName]  then
            for id, spell in pairs(Spells[myHero.charName]) do
                local range = spell.range == -1 and SOWi:MyRange() or spell.range
                if type(range) == "function" then
                    range = range(target)
                end
                MySpells[id] = Spell(id, range)

                if spell.skillshot then
                    MySpells[id]:SetSkillshot(VP, spell.spellType, spell.width, spell.delay, spell.speed, spell.collision)
                end

                if spell.AOE then
                    MySpells[id]:SetAOE(true)
                end
            end
        end
        Menu = scriptConfig("Simple Orbwalker", "Simple Orbwalker")
        Menu:addSubMenu("Target selector", "STS")
        STS:AddToMenu(Menu.STS)
        
        if Spells[myHero.charName] then
            Menu:addSubMenu("Spells", "Spells"..myHero.charName)
            for id, spell in pairs(Spells[myHero.charName]) do
                Menu["Spells"..myHero.charName]:addSubMenu(SpellToString(id).." - "..spell.name, "id"..id)
                Menu["Spells"..myHero.charName]["id"..id]:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, false)

                Menu["Spells"..myHero.charName]["id"..id]:addParam("Mode3", "Enabled in Last Hit mode", SCRIPT_PARAM_ONOFF, true)
                Menu["Spells"..myHero.charName]["id"..id]:addParam("Mode2", "Enabled in Lane Clear mode", SCRIPT_PARAM_ONOFF, true)
                Menu["Spells"..myHero.charName]["id"..id]:addParam("Mode1", "Enabled in Mixed mode", SCRIPT_PARAM_ONOFF, true)
                Menu["Spells"..myHero.charName]["id"..id]:addParam("Mode0", "Enabled in CarryMe mode", SCRIPT_PARAM_ONOFF, true)

                Menu["Spells"..myHero.charName]["id"..id]:addParam(tostring(string.gsub(myHero.type, "_", "")), "Use against champions", SCRIPT_PARAM_ONOFF, true)
                Menu["Spells"..myHero.charName]["id"..id]:addParam(tostring(string.gsub("obj_AI_Minion", "_", "")), "Use against minions", SCRIPT_PARAM_ONOFF, true)
            end
        end
        Menu:addSubMenu("Drawing", "Drawing")

        AArangeCircle = DManager:CreateCircle(myHero, SOWi:MyRange()+50, 1, {255, 255, 255, 255})
        AArangeCircle:AddToMenu(Menu.Drawing, "Auto Attack range", true, true, true)

        SOWi:LoadToMenu(Menu)
        SOWi:RegisterAfterAttackCallback(AfterAttack)
    end
end

function OnTick()
    if SOWi and AArangeCircle then
        AArangeCircle.radius = SOWi:MyRange() + 50
    end

    if SOWi and not SOWi:GetTarget() and Spells[myHero.charName] then
        for id, spell in pairs(Spells[myHero.charName]) do
            local range = spell.range == -1 and SOWi:MyRange() or spell.range
            if type(range) == "function" then
                range = range(target)
            end
            local target = STS:GetTarget(range)
            if target then
                CastSpells(target, SOWi.mode)
            end
        end
    end
end
