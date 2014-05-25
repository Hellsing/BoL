if myHero.charName ~= "Syndra" then return end

local version = 1.06
local AUTOUPDATE = true
local SCRIPT_NAME = "Syndra"

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

local MainCombo = {ItemManager:GetItem("DFG"):GetId(), _Q, _W, _E, _R, _R, _R, _IGNITE}
local _QE = 1337

--SpellData
local Ranges = {[_Q] = 790,       [_W] = 925,  [_E] = 700,       [_R] = 675}
local Widths = {[_Q] = 125,       [_W] = 125,  [_E] = 45 * 0.5,  [_R] = 1,    [_QE] = 60}
local Delays = {[_Q] = 0.6,       [_W] = 0.25, [_E] = 0.25,      [_R] = 0.25, [_QE] = 1800} ---_QE delay updates in function of _E delay + Speed and the distance to the ball
local Speeds = {[_Q] = math.huge, [_W] = 1450, [_E] = 2500,      [_R] = 1,    [_QE] = 1600}

local pets = {"annietibbers", "shacobox", "malzaharvoidling", "heimertyellow", "heimertblue", "yorickdecayedghoul"}

local Balls = {}
local BallDuration = 6.9

local QERange = (Ranges[_Q] + 500)

local QECombo = 0
local WECombo = 0
local EQCombo = 0

local DontUseRTime = 0
local UseRTime = 0

function OnLoad()
	VP = VPrediction()
	SOWi = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	DManager = DrawManager()

	Q = Spell(_Q, Ranges[_Q], true)
	Q:TrackCasting("SyndraQ")
	Q:RegisterCastCallback(OnCastQ)

	W = Spell(_W, Ranges[_W])
	W:TrackCasting("SyndraW")
	W:RegisterCastCallback(function() end)

	W2 = Spell(_W, Ranges[_W]) 
	W2:TrackCasting("syndraw2")
	W2:RegisterCastCallback(OnCastW)

	E = Spell(_E, Ranges[_E])
	E:TrackCasting({"SyndraE", "syndrae5"})
	E:RegisterCastCallback(OnCastE)

	EQ = Spell(_E, Ranges[_E])
	R = Spell(_R, Ranges[_R], true)

	Q:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_Q], Delays[_Q], Speeds[_Q], false)
	W:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], Speeds[_W], false)
	W2:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], Speeds[_W], false)
	E:SetSkillshot(VP, SKILLSHOT_CONE, Widths[_E], Delays[_E], Speeds[_E], false) --E
	EQ:SetSkillshot(VP, SKILLSHOT_LINEAR, 70, Delays[_E], Speeds[_E], false) --EQ

	Q:SetAOE(true)
	W:SetAOE(true)

	DLib:RegisterDamageSource(_Q, _MAGIC, 30, 40, _MAGIC, _AP, 0.60, function() return (player:CanUseSpell(_Q) == READY) end)--Without the 15% increase at rank 5
	DLib:RegisterDamageSource(_W, _MAGIC, 40, 40, _MAGIC, _AP, 0.70, function() return (player:CanUseSpell(_W) == READY) end)
	DLib:RegisterDamageSource(_E, _MAGIC, 25, 45, _MAGIC, _AP, 0.4, function() return (player:CanUseSpell(_E) == READY) end)--70 / 115 / 160 / 205 / 250 (+ 40% AP)
	DLib:RegisterDamageSource(_R, _MAGIC, 45, 45, _MAGIC, _AP, 0.2, function() return (player:CanUseSpell(_R) == READY) end)--1 sphere

	Menu = scriptConfig("Syndra", "Syndra")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseEQ", "Use EQ", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Use Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseEQ", "Use EQ", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.Harass:addParam("Enabled2", "Harass (toggle)!", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))

	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 1, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("ManaCheck2", "Don't farm if mana < % (freeze)", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("ManaCheck", "Don't farm if mana < % (laneclear)", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("EQ combo settings", "EQ")
		Menu.EQ:addParam("Order",  "Combo mode", SCRIPT_PARAM_LIST, 1, {"E -> Q" , "Q - > E"})
		Menu.EQ:addParam("Range", "Place Q at range:", SCRIPT_PARAM_SLICE, Q.range, 0, Q.range)

	Menu:addSubMenu("Ultimate", "R")
		Menu.R:addSubMenu("Don't use R on", "Targets")
		for i, enemy in ipairs(GetEnemyHeroes()) do
			Menu.R.Targets:addParam(enemy.hash,  enemy.charName, SCRIPT_PARAM_ONOFF, false)
		end
		Menu.R:addParam("CastR", "Force ultimate cast", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))
		Menu.R:addParam("DontUseR", "Don't use R in the next 10 seconds", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))

	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("WPet",  "Auto grab pets using W", SCRIPT_PARAM_ONOFF, true)

		Menu.Misc:addSubMenu("Auto-Interrupt", "Interrupt")
			Interrupter(Menu.Misc.Interrupt, OnInterruptSpell)

		Menu.Misc:addSubMenu("Anti-Gapclosers", "AG")
			AntiGapcloser(Menu.Misc.AG, OnGapclose)

		Menu.Misc:addParam("MEQ", "Manual E+Q Combo", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("T"))

	Menu:addSubMenu("Drawings", "Drawings")
		DManager:CreateCircle(myHero, SOWi:MyRange() + 50, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "AA Range", true, true, true)
		--[[Spell ranges]]
		for spell, range in pairs(Ranges) do
			DManager:CreateCircle(myHero, range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(spell).." Range", true, true, true)
		end
		DManager:CreateCircle(myHero, QERange, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "Q+E Range", true, true, true)
		
		
	--[[Predicted damage on healthbars]]
	DLib:AddToMenu(Menu.Drawings, MainCombo)

	EnemyMinions = minionManager(MINION_ENEMY, W.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, QERange, myHero, MINION_SORT_MAXHEALTH_DEC)
	PosiblePets = minionManager(MINION_OTHER, W.range, myHero, MINION_SORT_MAXHEALTH_DEC)
end

------------------------------------------------------------------------------------------------------------------------------------------------------------v
------------------------------------------------------------------------------------------------------------------------------------------------------------v
------------------------------------------------------------------------------------------------------------------------------------------------------------v

--Change the combo table depending on the active balls count.
function GetCombo()
	local result = {}
	for i, spell in ipairs(MainCombo) do
		table.insert(result, spell)
	end
	for i = 1, #GetValidBalls() do
		table.insert(result, _R)
	end
	return result
end

--Track the balls :p
function GetValidBalls(all)
	local result = {}
	for i, ball in ipairs(Balls) do
		if (ball.added or ball.startT <= os.clock()) and Balls[i].endT >= os.clock() and ball.object.valid then
			if not WObject or ball.object.networkID ~= WObject.networkID then
				table.insert(result, ball)
			end
		end
	end
	return result
end

function AddBall(obj)
	for i = #Balls, 1, -1 do
		if not Balls[i].added and GetDistanceSqr(Balls[i].object, obj) < 50*50 then
			Balls[i].added = true
			Balls[i].object = obj
			do return end
		end
	end

	--R balls
	local BallInfo = {
							 added = true, 
							 object = obj,
							 startT = os.clock(),
							 endT = os.clock() + BallDuration - GetLatency()/2000
					}
	table.insert(Balls, BallInfo)						
end

function OnCreateObj(obj)
	if obj and obj.valid then
		if GetDistanceSqr(obj) < Q.rangeSqr * 2 then
			if obj.name:find("Seed") then
				DelayAction(AddBall, 0, {obj})
			end
		end
	end
end

function OnDeleteObj(obj)
	if obj.name:find("Syndra_") and (obj.name:find("_Q_idle.troy") or obj.name:find("_Q_Lv5_idle.troy")) then
		for i = #Balls, 1, -1 do
			if Balls[i].object and Balls[i].object.valid and GetDistanceSqr(Balls[i].object, obj) < 50 * 50 then
				table.remove(Balls, i)
				break
			end
		end
	end
end

--Remove the non-active balls to save memory
function BTOnTick()
	for i = #Balls, 1, -1 do
		if Balls[i].endT <= os.clock() then
			table.remove(Balls, i)
		end
	end
end

function BTOnDraw()--For testings
	local activeballs = GetValidBalls()
	for i, ball in ipairs(activeballs) do
		DrawCircle(ball.object.x, myHero.y, ball.object.z, 100, ARGB(255,255,255,255))
	end
end

function IsPet(name) 
	return table.contains(pets, name:lower())
end

function IsPetDangerous(name)
	return (name:lower() == "annietibbers") or (name:lower() == "heimertblue")
end

function AutoGrabPets()
	if W:IsReady() and W.status == 0 then
		local pet = GetPet(true)
		if pet then
			W:Cast(pet.x, pet.z)
		end
	end
end

function GetPet(dangerous)
	PosiblePets:update()
	--Priorize Enemy Pet's
	for i, object in ipairs(PosiblePets.objects) do
		if object and object.valid and object.team ~= myHero.team and IsPet(object.charName) and (not dangerous or IsPetDangerous(object.charName)) then
			return object
		end
	end
end

function GetWValidBall(OnlyBalls)
	local all = GetValidBalls()
	local inrange = {}

	local Pet = GetPet(true)
	if Pet then
		return {object = Pet}
	end

	--Get the balls in W range
	for i, ball in ipairs(all) do
		if GetDistanceSqr(ball.object, myHero.visionPos) <= W.rangeSqr then
			table.insert(inrange, ball)
		end
	end

	local minEnd = math.huge
	local minBall

	--Get the ball that will expire earlier
	for i, ball in ipairs(inrange) do
		if ball.endT < minEnd then
			minBall = ball
			minEnd = ball.endT
		end
	end

	if minBall then
		return minBall
	end
	if OnlyBalls then 
		return 
	end

	Pet = GetPet()
	if Pet then
		return {object = Pet}
	end

	EnemyMinions:update()
	JungleMinions:update()
	PosiblePets:update()
	local t = MergeTables(MergeTables(EnemyMinions.objects, JungleMinions.objects), PosiblePets.objects)
	SelectUnits(t, function(t) return ValidTarget(t) and GetDistanceSqr(myHero.visionPos, t) < W.rangeSqr end)
	if t[1] then
		return {object = t[1]}
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function OnInterruptSpell(unit, spell)
	if GetDistanceSqr(unit.visionPos, myHero.visionPos) < E.rangeSqr and E:IsReady() then
		
		if Q:IsReady() then
			StartEQCombo(unit, false)
		else
			E:Cast(unit.visionPos.x, unit.visionPos.z)
		end

	elseif GetDistanceSqr(unit.visionPos,  myHero.visionPos) < QERange * QERange and Q:IsReady() and E:IsReady() then
		StartEQCombo(unit)
	end 
end

function OnGapclose(unit, data)
	if E:IsReady() and GetDistanceSqr(unit) < E.rangeSqr * 4 then
		Qdistance = 300
		StartEQCombo(unit, true)
	end
end

function OnRecvPacket(p)
	if p.header == 112 then
		p.pos = 1
		local NetworkID = p:DecodeF()
		local Active = p:Decode1()

		if NetworkID and Active == 1 then
			if not WObject then
				for i, ball in ipairs(Balls) do
					if ball.networkID == NetworkID then
						Balls[i].endT = os.clock() + BallDuration - GetLatency()/2000
					end
				end
			end
			WObject = objManager:GetObjectByNetworkId(NetworkID)
		else
			WObject = nil
		end
	end
end

function OnCastQ(spell)
	local BallInfo = {
						added = false, 
						object = {valid = true, x = spell.endPos.x, y = myHero.y, z = spell.endPos.z},
						startT = os.clock() + math.max(0, 0.25 - GetDistance(myHero.visionPos, spell.endPos)/1500) - GetLatency()/2000,
						endT = os.clock() + BallDuration + 1 - GetLatency()/2000
					 }

	table.insert(Balls, BallInfo)

	if os.clock() - QECombo < 1.5 then
		CastSpell(_E, spell.endPos.x, spell.endPos.z)
		QECombo = 0
	end
	Qdistance = nil
	EQTarget = nil
	EQCombo = 0
end

function OnCastW(spell)
	if os.clock() - WECombo < 1.5 then
		CastSpell(_E, spell.endPos.x, spell.endPos.z)
		WECombo = 0
	end
end

function OnCastE(spell)
	if os.clock() - EQCombo < 1.5 and EQTarget then
		for i = 0, 0.5, 0.05 do--Kappa
			DelayAction(function(t) Cast2Q(t) end, i, {EQTarget})
		end
	end
end

function StartEQCombo(unit, Qfirst)
	if (Menu.EQ.Order == 1 or Qfirst == false) and Qfirst ~= true then
		EQCombo = os.clock()
		EQTarget = unit
		E:Cast(unit.visionPos.x, unit.visionPos.z)
	else 
		QECombo = os.clock()
		Cast2Q(unit)
	end
end

function Cast2Q(target)
	if not Q:IsReady() then return end
	if GetDistanceSqr(target) > Q.rangeSqr then
		EQ.delay = Q.delay
		local spos = Vector(myHero.visionPos) + Menu.EQ.Range * (Vector(target) - Vector(myHero.visionPos)):normalized()
		EQ:SetSource(spos)

		local QEtargetPos, Hitchance, Position = EQ:GetPrediction(target)
		local pos = Vector(myHero.visionPos) + Menu.EQ.Range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
		Q:Cast(pos.x, pos.z)
	else
		if Qdistance then
			local pos = Vector(myHero.visionPos) + Qdistance * (Vector(target) - Vector(myHero.visionPos)):normalized()
			Q:Cast(pos.x, pos.z)
		else
			Q:Cast(target)
		end
	end
end

function UseSpells(UseQ, UseW, UseE, UseEQ, UseR)
	local Qtarget = STS:GetTarget(W.range)
	local QEtarget = STS:GetTarget(QERange)
	local Rtarget = STS:GetTarget(R.range)
	local DFGUsed = false

	if (os.clock() - DontUseRTime < 10) then
		UseR = false
	end

	if UseW then
		if Qtarget and W.status == 1 and (os.clock() - Q:GetLastCastTime() > 0.25) and (os.clock() - E:GetLastCastTime() > 0.25) then
			if WObject.charName == nil or WObject.charName:lower() ~= "heimertblue" then --Don't throw the giant tower :D
				W:Cast(Qtarget)
			end
		elseif Qtarget and W.status == 0 and (os.clock() - E:GetLastCastTime() > 0.7) and (os.clock() - Q:GetLastCastTime() > 0.7) then
			local validball = GetWValidBall()
			if validball then
				W:Cast(validball.object.x, validball.object.z)
			end
		end

		if not Qtarget and QEtarget and E:IsReady() and W.status == 1 and (WObject and WObject.name and WObject.name:find("Seed")) then
			--Update the EQ speed and the range
			EQ.delay = Q.range / E.speed + E.delay 
			local QEtargetPos, Hitchance, Position = EQ:GetPrediction(QEtarget)
			local pos = Vector(myHero.visionPos) + Q.range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
			if GetDistance(QEtargetPos, pos) <= (-0.6 * Q.range + 966) then
				WECombo = os.clock()
				W:Cast(pos.x, pos.z)
			end
		end
	end

	if UseQ then
		if Qtarget and os.clock() - W:GetLastCastTime() > 0.25 and os.clock() - E:GetLastCastTime() > 0.25 then
			VP.ShotAtMaxRange = true
			Q:Cast(Qtarget)
			VP.ShotAtMaxRange = false
		end
	end

	if UseEQ then
		if not Qtarget and QEtarget and E:IsReady() and Q:IsReady() then--E + Q at max range
			--Update the EQ speed and the range
			EQ.delay = Q.range / E.speed 
			local tmp, Hitchance, QEtargetPos = EQ:GetPrediction(QEtarget)
			local pos = Vector(myHero.visionPos) + Q.range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
			if GetDistance(QEtargetPos, pos) <= (-0.6 * Q.range + 966) then
				StartEQCombo(QEtarget)
			end
		end
	end

	if UseE then
		--Check to stun people with E
		local validballs = GetValidBalls()
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				local tmp1, tmp2, enemyPos = VP:GetPredictedPos(enemy, 0.25, QESpeed, myHero.visionPos, false)
				if enemyPos and enemyPos.z then
					for i, ball in ipairs(validballs) do
						if GetDistanceSqr(ball.object, myHero.visionPos) < Q.rangeSqr then
							local Delay = E.delay + GetDistance(myHero.visionPos, ball.object) / E.speed
							local QESpeed = Speeds[_QE]
							local EP = Vector(ball.object) +  (100+(-0.6 * GetDistance(ball.object, myHero.visionPos) + 966)) * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
							local SP = Vector(ball.object) - 100 * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
							local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(SP, EP, enemyPos)
							if isOnSegment and GetDistanceSqr(pointLine, enemyPos) <= (Widths[_QE] + VP:GetHitBox(enemy))^2 then
								CastSpell(_E, ball.object.x, ball.object.z)
							end
						end
					end
				end
			end
		end
	end

	if Rtarget and UseR then
		if DLib:IsKillable(Qtarget, GetCombo()) or (os.clock() - UseRTime < 10) then
			ItemManager:CastOffensiveItems(Rtarget)
			
			DFG = ItemManager:GetItem("DFG"):GetSlot()
			if DFG and myHero:CanUseSpell(DFG) == READY then
				DFGUsed = true
			end
		end

		if _IGNITE and GetDistanceSqr(Qtarget.visionPos, myHero.visionPos) < 600 * 600 and (DLib:IsKillable(Rtarget, GetCombo())  or (os.clock() - UseRTime < 10)) then
			CastSpell(_IGNITE, Rtarget)
		end
	end

	if UseR and not Q:IsReady() and R:IsReady() and not DFGUsed then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and (not Menu.R.Targets[enemy.hash] or (os.clock() - UseRTime < 10)) and GetDistanceSqr(enemy.visionPos, myHero.visionPos) < R.rangeSqr then
				if DLib:IsKillable(enemy, GetCombo())  or (os.clock() - UseRTime < 10) then
					if not DLib:IsKillable(enemy, {_Q, _E, _W})  or (os.clock() - UseRTime < 10) then
						R:Cast(enemy)
					end
				end
			end
		end
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Farm()
	if (Menu.Farm.ManaCheck > (myHero.mana / myHero.maxMana) * 100 and Menu.Farm.LaneClear) or (Menu.Farm.ManaCheck2 > (myHero.mana / myHero.maxMana) * 100 and Menu.Farm.Freeze) then return end
	EnemyMinions:update()
	local UseQ = Menu.Farm.LaneClear and (Menu.Farm.UseQ >= 3) or (Menu.Farm.UseQ == 2 or Menu.Farm.UseQ == 4)
	local UseW = Menu.Farm.LaneClear and (Menu.Farm.UseW >= 3) or (Menu.Farm.UseW == 2 or Menu.Farm.UseW == 4)
	local UseE = Menu.Farm.LaneClear and (Menu.Farm.UseE >= 3) or (Menu.Farm.UseE == 2 or Menu.Farm.UseE == 4)
	
	local CasterMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) and GetDistanceSqr(t) < W.rangeSqr end)
	local MeleeMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("basic") or t.charName:lower():find("cannon")) and ValidTarget(t) and GetDistanceSqr(t) < W.rangeSqr end)
	
	if UseW then
		if W.status == 0 then
			if #MeleeMinions > 1 then
				W:Cast(MeleeMinions[1].x, MeleeMinions[1].z)
			elseif #CasterMinions > 1 then
				W:Cast(CasterMinions[1].x, CasterMinions[1].z)
			end
		else
			local BestPos1, BestHit1 = GetBestCircularFarmPosition(Ranges[_W], Widths[_W]*1.1, CasterMinions)
			local BestPos2, BestHit2 = GetBestCircularFarmPosition(Ranges[_W], Widths[_W]*1.1, MeleeMinions)

			if BestHit1 > 2 or (BestPos1 and #CasterMinions <= 2) then
				W:Cast(BestPos1.x, BestPos1.z)
			elseif BestHit2 > 2 or (BestPos2 and #MeleeMinions <= 2) then
				W:Cast(BestPos2.x, BestPos2.z)
			end

		end
	end

	if UseQ and ( not UseW or W.status == 0 ) then
		CasterMinions = GetPredictedPositionsTable(VP, CasterMinions, Delays[_Q], Widths[_Q], Ranges[_Q] + Widths[_Q], math.huge, myHero, false)
		MeleeMinions = GetPredictedPositionsTable(VP, MeleeMinions, Delays[_Q], Widths[_Q], Ranges[_Q] + Widths[_Q], math.huge, myHero, false)

		local BestPos1, BestHit1 = GetBestCircularFarmPosition(Ranges[_Q] + Widths[_Q], Widths[_Q], CasterMinions)
		local BestPos2, BestHit2 = GetBestCircularFarmPosition(Ranges[_Q] + Widths[_Q], Widths[_Q], MeleeMinions)

		if BestPos1 and BestHit1 > 1 then
			CastSpell(_Q, BestPos1.x, BestPos1.z)
		elseif BestPos2 and BestHit2 > 1 then
			CastSpell(_Q, BestPos2.x, BestPos2.z)
		end
	end

	if UseE and (not Q:IsReady() or not UseQ) then
		local AllMinions = SelectUnits(EnemyMinions.objects, function(t) return ValidTarget(t) and GetDistanceSqr(t) < E.rangeSqr end)
		local BestPos, BestHit = GetBestCircularFarmPosition(E.range, Widths[_Q], AllMinions)
		if BestHit > 4 then
			E:Cast(BestPos.x, BestPos.z)
		else
			local validballs = GetValidBalls()
			local maxcount = 0
			local maxpos

			for i, ball in ipairs(validballs) do
				if GetDistanceSqr(ball.object, myHero.visionPos) < Q.rangeSqr then
					local Count = 0
					for i, minion in ipairs(AllMinions) do
						local EP = Vector(ball.object) +  (100+(-0.6 * GetDistance(ball.object, myHero.visionPos) + 966)) * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
						local SP = Vector(myHero.visionPos)
						local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(SP, EP, minion)
						if isOnSegment and GetDistanceSqr(pointLine, enemyPos) < Widths[_QE] * Widths[_QE] then
							Count = Count + 1
						end
					end
					if Count > maxcount then
						maxcount = Count
						maxpos = Vector(ball.object)
					end
				end
			end
			if maxcount > 2 then
				E:Cast(maxpos.x, maxpos.z)
			end
		end
	end
end

function JungleFarm()
	JungleMinions:update()
	local UseQ = Menu.JungleFarm.UseQ
	local UseW = Menu.JungleFarm.UseW
	local UseE = Menu.JungleFarm.UseE
	local WUsed = false
	local CloseMinions = SelectUnits(JungleMinions.objects, function(t) return GetDistanceSqr(t) <= W.rangeSqr and ValidTarget(t) end)
	local AllMinions = SelectUnits(JungleMinions.objects, function(t) return ValidTarget(t) end)

	local CloseMinion = CloseMinions[1]
	local FarMinion = AllMinions[1]

	

	if ValidTarget(CloseMinion) then
		local selectedTarget = GetTarget()

		if selectedTarget and selectedTarget.type == CloseMinion.type then
			DrawJungleStealingIndicator = true
			SOWi:DisableAttacks()
			if ValidTarget(selectedTarget) and DLib:IsKillable(selectedTarget, {_Q, _W}) and GetDistanceSqr(myHero.visionPos, selectedTarget) <= W.rangeSqr and W:IsReady() then
				if W.status == 0 then
					W:Cast(selectedTarget.x, selectedTarget.z)
				end
			end
		else
			if UseW then
				if W.status == 0 then
					local validball = GetWValidBall(true)
					if validball and validball.added then
						W:Cast(validball.object.x, validball.object.z)
						WUsed = true
					end
				else
					if WObject.name and WObject.name:find("Seed") then
						W:Cast(CloseMinion)
						WUsed = true
					else
						W:Cast(myHero.x, myHero.z)
						WUsed = true
					end
				end
			end

			if UseQ then
				Q:Cast(CloseMinion)
			end

			if UseE and os.clock() - Q:GetLastCastTime() > 1 then
				E:Cast(CloseMinion)
			end
		end
	elseif ValidTarget(FarMinion) and GetDistanceSqr(FarMinion) <= (Q.range + 588)^2 and GetDistanceSqr(FarMinion) > Q.rangeSqr and DLib:IsKillable(FarMinion, {_E}) then
		if Q:IsReady() and E:IsReady() then
			local QPos = Vector(myHero.visionPos) + Q.range * (Vector(FarMinion) - Vector(myHero)):normalized()
			Q:Cast(QPos.x, QPos.z)
			QECombo = os.clock()
		end
	end

	if W.status == 1 and not WUsed then
		if (not WObject.name or not WObject.name:find("Seed")) and WObject.type == 'obj_AI_Minion' then
			W:Cast(myHero.x, myHero.z)
		end
	end
end

function UpdateSpellData()
	if E.width ~= 2 * Widths[_E] and E:GetLevel() == 5 then
		E.width = 2 * Widths[_E]
	end
	
	if R.range ~= (Ranges[_R] + 75) and R:GetLevel() == 5 then
		R:SetRange(Ranges[_R] + 75)
	end

	W.status = WObject and 1 or 0
end

function Combo()
	SOWi:DisableAttacks()
	if not Q:IsReady() and not W:IsReady() and not E:IsReady() then
		SOWi:EnableAttacks()
	end
	UseSpells(Menu.Combo.UseQ, Menu.Combo.UseW, Menu.Combo.UseE, Menu.Combo.UseEQ, Menu.Combo.UseR)
end

function Harass()
	if Menu.Harass.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	UseSpells(Menu.Harass.UseQ, Menu.Harass.UseW, Menu.Harass.UseE, Menu.Harass.UseEQ, false)
end

function OnTick()
	DrawJungleStealingIndicator = false
	BTOnTick()
	SOWi:EnableAttacks()
	DLib.combo = GetCombo()
	UpdateSpellData()--update the spells data
	DrawEQIndicators = false
	
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

	if Menu.R.UseR then
		local Rtarget = STS:GetTarget(R.range)
		if Rtarget then
			R:Cast(Rtarget)
		end
	end

	if Menu.Misc.WPet then
		AutoGrabPets()
	end

	if Menu.R.DontUseR then
		DontUseRTime = os.clock()
		UseRTime = 0
	end

	if Menu.R.CastR then
		UseRTime = os.clock()
		DontUseRTime = 0
	end

	if Menu.Misc.MEQ and Q:IsReady() and E:IsReady() then
		DrawEQIndicators = true
		local PosibleTargets = GetEnemyHeroes()
		local ClosestTargetMouse 
		local closestdist = 200 * 200
		for i, target in ipairs(PosibleTargets) do
			local dist = GetDistanceSqr(mousePos, target)
			if ValidTarget(target) and dist < closestdist then
				ClosestTargetMouse = target
				closestdist = dist
			end
		end
		if ClosestTargetMouse and GetDistanceSqr(ClosestTargetMouse, myHero.visionPos) < (QERange + 300)^2 then
			if GetDistanceSqr(ClosestTargetMouse) < Q.rangeSqr then
				StartEQCombo(ClosestTargetMouse, true)
			else
				StartEQCombo(ClosestTargetMouse)
			end
		end
	end
end

function GetDistanceToClosestHero(p)
	local result = math.huge
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			result = math.min(result, GetDistanceSqr(p, enemy))
		end
	end
	return result
end

myHero.barData = {PercentageOffset = {x = 0, y = 0}}

function OnDraw()
	if DrawEQIndicators then
		DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 200, 3, GetDistanceToClosestHero(mousePos) < 200 * 200 and ARGB(200, 255, 0, 0) or ARGB(200, 0, 255, 0), 20)--sorry for colorblind people D:
	end

	if GetTarget() and GetTarget().type == 'obj_AI_Minion' and GetTarget().team == TEAM_NEUTRAL then
		DrawCircle3D(GetTarget().x, GetTarget().y, GetTarget().z, 100, 2, Menu.JungleFarm.Enabled and ARGB(175, 255, 0, 0) or ARGB(175, 0, 255, 0), 25) --sorry for colorblind people D:
	end

	if DrawJungleStealingIndicator then
		local pos = GetEnemyHPBarPos(myHero) + Vector(20, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("JungleStealing"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("JungleStealing"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
	end

	if Menu.Harass.Enabled2 then
		local pos = GetEnemyHPBarPos(myHero) + Vector(0, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("AH"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("AH"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
	end
end
