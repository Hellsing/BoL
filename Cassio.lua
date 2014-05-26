if myHero.charName ~= "Cassiopeia" then return end

local version = 2.06
local AUTOUPDATE = true
local SCRIPT_NAME = "Cassio"

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

local MainCombo = {_Q, _Q, _W, _E, _E, _R, _IGNITE}

--Spell Data
local Ranges = {[_Q] = 850, [_W] = 850, [_E] = 700, [_R] = 825}
local Widths = {[_Q] = 75, [_W] = 106, [_R] = 80 * math.pi / 180}
local Delays = {[_Q] = 0.6, [_W] = 0.5, [_R] = 0.3}
local Speeds = {[_Q] = math.huge, [_W] = 2500, [_R] = math.huge}

function OnLoad()
	VP = VPrediction()
	SOWi = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	DManager = DrawManager()
	
	Q = Spell(_Q, Ranges[_Q])
	W = Spell(_W, Ranges[_W])
	E = Spell(_E, Ranges[_E])
	R = Spell(_R, Ranges[_R])

	Q:SetSkillshot(VP, SKILLSHOT_LINEAR, Widths[_Q], Delays[_Q], Speeds[_Q], false)
	W:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], Speeds[_R], false)
	R:SetSkillshot(VP, SKILLSHOT_CONE, Widths[_R], Delays[_R], Speeds[_R], false)

	Q:SetAOE(true)
	W:SetAOE(true)
	R:SetAOE(true, R.width, 0)

	DLib:RegisterDamageSource(_Q, _MAGIC, 35, 40, _MAGIC, _AP, 0.8)
	DLib:RegisterDamageSource(_W, _MAGIC, 15, 10, _MAGIC, _AP, 0.15, function() return (player:CanUseSpell(_W) == READY) end)
	DLib:RegisterDamageSource(_E, _MAGIC, 35, 35, _MAGIC, _AP, 0.55)
	DLib:RegisterDamageSource(_R, _MAGIC, 75, 125, _MAGIC, _AP, 0.6, function() return (player:CanUseSpell(_R) == READY) end)

	Menu = scriptConfig("Cassiopeia", "Cassiopeia")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q in combo", SCRIPT_PARAM_ONOFF , true)
		Menu.Combo:addParam("UseW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E on poisoned targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseEP", "Use E using packets", SCRIPT_PARAM_ONOFF, false)
		Menu.Combo:addParam("UseR", "Use R if enemy killable", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseIgnite", "Use ignite if the target is killable", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Harass using Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseW", "Harass using W", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseE", "Harass using E on poisoned", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("Enabled", "Harass! (hold)", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Harass:addParam("Enabled2", "Harass! (toggle)", SCRIPT_PARAM_ONKEYTOGGLE, false,   string.byte("Y"))

	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 4, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("Enabled", "Farm jungle!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("Ultimate", "Ultimate")
		Menu.Ultimate:addParam("Auto",  "Auto ultimate if ", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
		Menu.Ultimate:addParam("AutoAim", "Cast ultimate!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))

	Menu:addSubMenu("Drawings", "Drawings")
	--Spell ranges
	for spell, range in pairs(Ranges) do
		DManager:CreateCircle(myHero, range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(spell).." Range", true, true, true)
	end
	DManager:CreateCircle(myHero, SOWi:MyRange(), 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "AA Range", true, true, true)
	--Predicted damage on healthbars
	DLib:AddToMenu(Menu.Drawings, MainCombo)

	EnemyMinions = minionManager(MINION_ENEMY, Ranges[_W], myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, Ranges[_W], myHero, MINION_SORT_MAXHEALTH_DEC)

	TickLimiter(AutoR, 15)
end

function isPoisoned(target)
	for i = 1, target.buffCount do
		local tBuff = target:getBuff(i)
		if BuffIsValid(tBuff) and tBuff.name:find("poison") and (tBuff.endT - (math.min(GetDistance(myHero.visionPos, target.visionPos), 700)/1900 + 0.25 + GetLatency()/2000) - GetGameTimer() > 0) then
			return true
		end
	end

	return false
end

function AutoE()
	if not E:IsReady() then return end
	for n = 1, 5 do
		local target = STS:GetTarget(Ranges[_E], n)
		if target and isPoisoned(target) then
			return E:Cast(target)
		end
	end
end

function UseSpells(UseQ, UseW, UseE, UseR)
	--Q
	if UseQ then
		local Qtarget = STS:GetTarget(Ranges[_Q] + Widths[_Q], n)
		if Qtarget then
			Q:Cast(Qtarget)
		end
	end

	--W
	if UseW then
		Wtarget = STS:GetTarget(Ranges[_W] + Widths[_W], n)
		if Wtarget then
			W:Cast(Wtarget)
		end
	end

	--E
	if UseE then
		E.packetCast = Menu.Combo.UseEP
		AutoE()
	end

	--R
	if UseR then
		local Rtarget = STS:GetTarget(Ranges[_R])
		if Rtarget and DLib:IsKillable(Rtarget, MainCombo) then
			R:SetAOE(true, R.width, CountObjectsNearPos(Vector(Rtarget), 500, 500, SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t) end)))
			R:Cast(Rtarget)
			R:SetAOE(true)
		end
	end
end

function SetAttacks()
	SOWi:DisableAttacks()
	if not Q:IsReady() and not W:IsReady() and not E:IsReady() then
		SOWi:EnableAttacks()
	end
end

function Combo()
	if Menu.Combo.UseIgnite and _IGNITE then
		local Ignitetarget = STS:GetTarget(600)
		if Ignitetarget and DLib:IsKillable(Ignitetarget, MainCombo) then
			CastSpell(_IGNITE, Ignitetarget)
		end
	end

	UseSpells(Menu.Combo.UseQ, Menu.Combo.UseW, Menu.Combo.UseE, Menu.Combo.UseR)
	SetAttacks()
end

function Harass()
	VP.ShotAtMaxRange = true
	UseSpells(Menu.Harass.UseQ, Menu.Harass.UseW, Menu.Harass.UseE, false)
	VP.ShotAtMaxRange = false
end

function Farm()
	EnemyMinions:update()
	local UseQ = Menu.Farm.LaneClear and (Menu.Farm.UseQ >= 3) or (Menu.Farm.UseQ == 2)
	local UseW = Menu.Farm.LaneClear and (Menu.Farm.UseW >= 3) or (Menu.Farm.UseW == 2)
	local UseE = Menu.Farm.LaneClear and (Menu.Farm.UseE >= 3) or (Menu.Farm.UseE == 2)

	if UseQ then
		if Menu.Farm.Freeze then
			for i, minion in ipairs(EnemyMinions.objects) do
				if VP:GetPredictedHealth(minion, Delays[_Q] + 0.25) - 50 < 0 then
					CastSpell(_Q, minion.visionPos.x, minion.visionPos.z)
					break
				end
			end
		end
		if Menu.Farm.LaneClear then
			local AllMinions = SelectUnits(EnemyMinions.objects, function(t) return ValidTarget(t) end)
			AllMinions = GetPredictedPositionsTable(VP, AllMinions, Delays[_Q], Widths[_Q], Ranges[_Q] + Widths[_Q], math.huge, myHero, false)
			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_Q] + Widths[_Q], Widths[_Q], AllMinions)

			if BestPos then
				CastSpell(_Q, BestPos.x, BestPos.z)
			end
		end
	end

	if UseW then
		local CasterMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) end)
		CasterMinions = GetPredictedPositionsTable(VP, CasterMinions, Delays[_W], Widths[_W], Ranges[_W], Speeds[_W], myHero, false)

		local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_W], Widths[_W]*1.5, CasterMinions)
		if BestHit > 2 then
			CastSpell(_W, BestPos.x, BestPos.z)
			do return end
		end
	end

	if UseE then
		local PoisonedMinions = SelectUnits(EnemyMinions.objects, function(t) return ValidTarget(t) and isPoisoned(t) end)
		for i, minion in ipairs(PoisonedMinions) do
			local time = 0.25 + 1900 / GetDistance(minion.visionPos, myHero.visionPos) + 0.1
			if VP:GetPredictedHealth(minion, time) - DLib:CalcSpellDamage(minion, _E) < 0 then
				CastSpell(_E, minion)
				break
			end
		end
	end
end

function JungleFarm()
	JungleMinions:update()
	local UseQ = Menu.JungleFarm.UseQ
	local UseW = Menu.JungleFarm.UseW
	local UseE = Menu.JungleFarm.UseE
	local minion = JungleMinions.objects[1]
	
	if UseQ and ValidTarget(minion) then
		Q:Cast(minion)
	end

	if UseW and ValidTarget(minion) then
		W:Cast(minion)
	end

	if UseE then
		local PoisonedMinions = SelectUnits(JungleMinions.objects, function(t) return ValidTarget(t) and isPoisoned(t) end)
		if #PoisonedMinions > 0 then
			CastSpell(_E, PoisonedMinions[1])
		end
	end
end

function OnTick()
	SOWi:EnableAttacks()

	if Menu.Combo.Enabled then
		Combo()
	elseif Menu.Harass.Enabled or Menu.Harass.Enabled2 then
		Harass()
	end

	if Menu.Farm.LaneClear or Menu.Farm.Freeze then
		Farm()
	end

	if Menu.JungleFarm.Enabled then
		JungleFarm()
	end


	--R aim
	if Menu.Ultimate.AutoAim then
		local Rtarget = STS:GetTarget(Ranges[_R])
		R:Cast(Rtarget)
	end
end

function AutoR()
	if Menu.Ultimate.Auto ~= 1 then
		local Rtarget = STS:GetTarget(Ranges[_R])
		R:SetAOE(true, R.width, Menu.Ultimate.Auto - 1)
		R:Cast(Rtarget)
		R:SetAOE(true)
	end
end
