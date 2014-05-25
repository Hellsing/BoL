if myHero.charName ~= "Brand" then return end

local version = 1.07
local AUTOUPDATE = true
local SCRIPT_NAME = "Brand"

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


local ablazebuffname = "brandablaze"

local MainCombo = {ItemManager:GetItem("DFG"):GetId(), _AA, _Q, _W, _E, _R, _PASIVE, _IGNITE}
local BounceCombo = {ItemManager:GetItem("DFG"):GetId(), _AA, _Q, _W, _E, _R, _R, _R, _PASIVE, _IGNITE}
local RAOERANGE = 450

--Spell data
local Ranges = {[_Q] = 1100, [_W] = 900, [_E] = 625, [_R] = 750}
local Delays = {[_Q] = 0.25, [_W] = 1}
local Widths = {[_Q] = 60, [_W] = 240}
local Speeds = {[_Q] = 1600}


local LastQTime = 0
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
	E.VP = VP
	Q:SetSkillshot(VP, SKILLSHOT_LINEAR, Widths[_Q], Delays[_Q], Speeds[_Q], true)
	W:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], math.huge, false)
	W:SetAOE(true, W.width, 0)

	DLib:RegisterDamageSource(_Q, _MAGIC, 40, 40, _MAGIC, _AP, 0.65, function() return (player:CanUseSpell(_Q) == READY) end)
	DLib:RegisterDamageSource(_W, _MAGIC, 30, 45, _MAGIC, _AP, 0.60, function() return (player:CanUseSpell(_W) == READY) end, function(target) return IsAblazed(target) and (player.ap * 0.15 + myHero:GetSpellData(_W).level * 15) or 0 end)
	DLib:RegisterDamageSource(_E, _MAGIC, 35, 35, _MAGIC, _AP, 0.55, function() return (player:CanUseSpell(_E) == READY) end)
	DLib:RegisterDamageSource(_R, _MAGIC, 50, 100, _MAGIC, _AP, 0.5, function() return (player:CanUseSpell(_R) == READY) end)
	DLib:RegisterDamageSource(_PASIVE, _MAGIC, 0, 0, _MAGIC, _AP, 0, nil, function(target) return 0.08 * target.maxHealth end)

	Menu = scriptConfig("Brand", "Brand")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Use Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))

	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 1, { "No", "Freeze", "LaneClear", "Both" })	
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 4, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("Ultimate", "R")
		Menu.R:addSubMenu("Don't use R on", "Targets")
		for i, enemy in ipairs(GetEnemyHeroes()) do
			Menu.R.Targets:addParam(enemy.charName,  enemy.charName, SCRIPT_PARAM_ONOFF, false)
		end
		Menu.R:addParam("Ablazed", "Only use R if the target is ablazed or killable", SCRIPT_PARAM_ONOFF, true)
		Menu.R:addParam("AutoR", "Auto R if it will hit: ", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
		Menu.R:addParam("CastR", "Force ultimate cast", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))

	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("AutoQ", "Auto Q on gapclosing targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoQ2", "Auto Q on stunned targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("AutoW", "Auto W on stunned targets", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("Drawings", "Drawings")
	--[[Spell ranges]]
	for spell, range in pairs(Ranges) do
		DManager:CreateCircle(myHero, range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(spell).." Range", true, true, true)
	end
	--[[Predicted damage on healthbars]]
	DLib:AddToMenu(Menu.Drawings, MainCombo)

	EnemyMinions = minionManager(MINION_ENEMY, Ranges[_Q], myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, Ranges[_Q], myHero, MINION_SORT_MAXHEALTH_DEC)

end

function IsAblazed(target)
	return HasBuff(target, "brandablaze")
end

function Combo()
	local Qtarget = STS:GetTarget(Ranges[_Q])
	local Wtarget = STS:GetTarget(Ranges[_W])
	local Etarget = STS:GetTarget(Ranges[_E])
	local Rtarget = STS:GetTarget(Ranges[_R])
	local status
	SOWi:DisableAttacks()

	if Wtarget and DLib:IsKillable(Wtarget, MainCombo) then
		ItemManager:CastOffensiveItems(Wtarget)
	end

	if Qtarget and Q:IsReady() and Menu.Combo.UseQ and (IsAblazed(Qtarget) or not Menu.Misc.Ablazed or DLib:IsKillable(Qtarget, {_Q, _W})) and (not Etarget or not E:IsReady() or not Menu.Combo.UseE) and (not Wtarget or not W:IsReady() or not Menu.Combo.UseW) then
		status = Q:Cast(Qtarget)
	end

	if Wtarget and W:IsReady() and Menu.Combo.UseW and (not Etarget or not E:IsReady() or not Menu.Combo.UseE) then
		if not status or status == SPELLSTATE_COLLISION then
			W:Cast(Wtarget)
		end
	end

	if Etarget and E:IsReady() and Menu.Combo.UseE then
		E:Cast(Etarget)
	end

	local IgniteTarget = STS:GetTarget(600)
	if IgniteTarget and DLib:IsKillable(Rtarget, MainCombo) and _IGNITE and  GetInventorySlotItem(_IGNITE) then
		CastSpell(GetInventorySlotItem(_IGNITE), IgniteTarget)
	end
		if not Q:IsReady() and not W:IsReady() and not E:IsReady() and not R:IsReady() then
			SOWi:EnableAttacks()
		end

	if R:IsReady() and Menu.Combo.UseR then
		if Rtarget and not Menu.R.Targets[Rtarget.charName] then

			EnemyMinions:update()
			local targets = MergeTables(EnemyMinions.objects, GetEnemyHeroes())
			ablazedtargets = SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t) and GetDistanceSqr(t, Rtarget) < RAOERANGE * RAOERANGE and IsAblazed(t) end)
			targets = SelectUnits(targets, function(t) return ValidTarget(t) and GetDistanceSqr(t, Rtarget) < RAOERANGE * RAOERANGE end)

			if ((#targets == 2) or (IsAblazed(Rtarget) and DLib:IsKillable(Rtarget, BounceCombo))) then
				if E:IsReady() and GetDistanceSqr(Rtarget) <= Ranges[_E] * Ranges[_E] then
					E:Cast(Rtarget)
				elseif not E:IsReady() and IsAblazed(Rtarget) then
					R:Cast(Rtarget)
				end
			end

			if (not Q:IsReady() or status == SPELLSTATE_COLLISION or status == nil) and DLib:IsKillable(Rtarget, MainCombo) then
				if E:IsReady() and GetDistanceSqr(Rtarget) <= Ranges[_E] * Ranges[_E] then
					E:Cast(Rtarget)
				else
					R:Cast(Rtarget)
				end
			end
		end
	end
end

function Harass()
	if Menu.Harass.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	local Qtarget = STS:GetTarget(Ranges[_Q])
	local Wtarget = STS:GetTarget(Ranges[_W])
	local Etarget = STS:GetTarget(Ranges[_E])

	if Qtarget and Q:IsReady() and Menu.Harass.UseQ and (IsAblazed(Qtarget) or not Menu.Misc.Ablazed) and (not Etarget or not E:IsReady() or not Menu.Harass.UseE) then
		Q:Cast(Qtarget)
	end

	if Wtarget and W:IsReady() and Menu.Harass.UseW then
		W:Cast(Wtarget)
	end

	if Etarget and E:IsReady() and Menu.Harass.UseE then
		E:Cast(Etarget)
	end
end

function Farm()
	if Menu.Farm.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	EnemyMinions:update()

	local UseQ = Menu.Farm.LaneClear and (Menu.Farm.UseQ >= 3) or (Menu.Farm.UseQ == 2)
	local UseW = Menu.Farm.LaneClear and (Menu.Farm.UseW >= 3) or (Menu.Farm.UseW == 2)
	local UseE = Menu.Farm.LaneClear and (Menu.Farm.UseE >= 3) or (Menu.Farm.UseE == 2)

	local minion = EnemyMinions.objects[1]
	if minion then
		if UseQ then
			Q:Cast(minion)
		end

		if UseW then
			local CasterMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) end)
			CasterMinions = GetPredictedPositionsTable(VP, CasterMinions, Delays[_W], Widths[_W], Ranges[_W], math.huge, myHero, false)

			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_W], Widths[_W], CasterMinions)
			if BestHit > 2 then
				CastSpell(_W, BestPos.x, BestPos.z)
				do return end
			end

			local AllMinions = SelectUnits(EnemyMinions.objects, function(t) return ValidTarget(t) end)
			AllMinions = GetPredictedPositionsTable(VP, AllMinions, Delays[_W], Widths[_W], Ranges[_W], math.huge, myHero, false)

			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_W], Widths[_W], AllMinions)
			if BestHit > 2 then
				CastSpell(_W, BestPos.x, BestPos.z)
				do return end
			end
		end

		if UseE then
			if Menu.Farm.LaneClear then
				for i, minion in ipairs(EnemyMinions.objects) do
					if GetDistance(minion) < Ranges[_E] and IsAblazed(minion) then
						E:Cast(minion)
					end
				end
				if DLib:IsKillable(minion, {_E}) then
					E:Cast(minion)
				end
			else
				if not HOWi:InRange(minion) and DLib:IsKillable(minion, {_E}) then
					E:Cast(minion)
				end
			end 
		end
	end
end

function JungleFarm()
	JungleMinions:update()

	local UseQ = Menu.Farm.UseQ
	local UseW = Menu.Farm.UseW
	local UseE = Menu.Farm.UseE
	local minion = JungleMinions.objects[1]
	if minion then
		if UseQ and (not W:IsReady() or not UseW) then
			Q:Cast(minion)
		end
		if UseW then
			local BestPos, BestHit = GetBestCircularFarmPosition(Ranges[_W], Widths[_W], JungleMinions.objects)
			CastSpell(_W, BestPos.x, BestPos.z)
		end
		if UseE and (not W:IsReady() or not UseW) then
			E:Cast(minion)
		end
	end
end

function OnTick()
	SOWi:EnableAttacks()

	if Menu.R.CastR then
		local Rtarget = STS:GetTarget(Ranges[_R])
		R:Cast(Rtarget)
	end

	if Menu.Combo.Enabled then
		Combo()
	elseif Menu.Harass.Enabled then
		Harass()
	end

	if Menu.Farm.Freeze or Menu.Farm.LaneClear then
		Farm()
	end

	if Menu.JungleFarm.Enabled then
		JungleFarm()
	end

	--[[Misc options]]
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and GetDistanceSqr(enemy) <= (Ranges[_Q]*Ranges[_Q]) then

			if Menu.Misc.AutoQ2 then
				local Result = E:CastIfImmobile(enemy)
				if Result ~= SPELLSTATE_TRIGGERED then
					Q:CastIfImmobile(enemy)
				end
			end

			if Menu.Misc.AutoQ then
				local Result = E:CastIfDashing(enemy)
				if Result ~= SPELLSTATE_TRIGGERED then
					Q:CastIfDashing(enemy)
				end
			end

			if Menu.Misc.AutoW and GetDistanceSqr(enemy) <= (Ranges[_W] + Widths[_W])^2 then
				W:CastIfImmobile(enemy)
			end
		end
	end

	--[[Auto R]]
	if Menu.R.AutoR ~= 1 then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and GetDistanceSqr(enemy) <= Ranges[_R] * Ranges[_R] then
				local targets = SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t) and GetDistanceSqr(t, enemy) < RAOERANGE * RAOERANGE end)
				if #targets > (Menu.R.AutoR -1) and not Menu.R.Targets[enemy.charName] then
					R:Cast(enemy)
				end
			end
		end
	end
end
