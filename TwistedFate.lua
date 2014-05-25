if myHero.charName ~= "TwistedFate" then return end

local version = 2.32
local AUTOUPDATE = true
local SCRIPT_NAME = "TwistedFate"

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


--Spell damages
local Qdamage = {60, 110, 160, 210, 260}
local Qscaling = 0.65
local Wdamage = {15, 22.5, 30, 37.5, 45}
local Wscaling = 0.5
local Edamage = { 55, 80, 105, 130, 155}
local Escaling = 0.5
local DFG, SHEEN, LICH = nil, nil, nil

--Spell data
local AArange = 650
local Rrange = 6000
local Qrange = 1450
local Qdelay = 0.25
local Qspeed =  1000
local Qradius = 40
local Qangle = 28 * math.pi / 180

local Predictions = {}
local levelUps = {2, 1, 1, 3, 1, 4, 1, 2, 1, 2, 4, 2, 2, 3, 3, 4, 3, 3}

local CastingUltimate = false
local Qtarget = nil
local AAtarget = nil

local VP

--[[Card Locker]]
local NONE, RED, BLUE, YELLOW = 0, 1, 2, 3
local READY, SELECTING, SELECTED = READY, 1, 2, 3
local Status = READY
local CardColor = NONE
local ToSelect = NONE
local LastCard = NONE

local Menu = nil

--[[	Killable texts and alerts	]]
local DamageToHeros = {}
local LastAlert = 0
local lastrefresh = 0

function OnLoad()
	autoLevelSetSequence(levelUps)
	VP = VPrediction()
	OW = SOW(VP)
	Menu = scriptConfig("Twisted Fate", "Twisted Fate")
	
	Menu:addSubMenu("Orbwalking", "Orbwalking")
	OW:LoadToMenu(Menu.Orbwalking)
	
	Menu:addParam("combo", "Select gold + use all items", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu:addParam("dl", "Yellow card range: ", SCRIPT_PARAM_SLICE, 0, 0, 1000)
	
	Menu:addSubMenu("Spells", "spells")

		Menu.spells:addSubMenu("Q (Wild Cards)", "Q")
			Menu.spells.Q:addParam("cast", "Cast Q using VPrediction", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("T"))
			Menu.spells.Q:addParam("auto", "Auto Q if Q can't fail", SCRIPT_PARAM_ONOFF, true)
			
		Menu.spells:addSubMenu("W (Pick a card)", "W")
			Menu.spells.W:addParam("yellow", "Yellow Card", SCRIPT_PARAM_ONKEYDOWN, false,  string.byte("W"))
			Menu.spells.W:addParam("blue", "Blue Card", SCRIPT_PARAM_ONKEYDOWN, false,  string.byte("E"))
			Menu.spells.W:addParam("red", "Red Card", SCRIPT_PARAM_ONKEYDOWN, false,  string.byte("X"))
			Menu.spells.W:addParam("autoaa", "Prevent AA while locking new card (Manual)",  SCRIPT_PARAM_ONOFF, true)
		
		Menu.spells:addSubMenu("R (Destiny)", "R")
			Menu.spells.R:addParam("auto", "Auto Lock Yellow card after using ultimate",  SCRIPT_PARAM_ONOFF, true)
			
	Menu:addSubMenu("Items", "items")
		Menu.items:addParam("usedfg", "Use dfg on target", SCRIPT_PARAM_ONOFF, true)
		Menu.items:addParam("waitdfg", "Wait for yellow card before using dfg",  SCRIPT_PARAM_ONOFF, true)
		
	Menu:addSubMenu("Drawing", "drawing")
		Menu.drawing:addParam("drawQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
		Menu.drawing:addParam("drawAA", "Draw AA range", SCRIPT_PARAM_ONOFF, true)
		Menu.drawing:addParam("drawRN", "Draw R range while casting ultimate", SCRIPT_PARAM_ONOFF, true)
		Menu.drawing:addParam("drawR", "Draw R range on minimap", SCRIPT_PARAM_ONOFF, true)
		Menu.drawing:addParam("alert", "Alert about low health enemies", SCRIPT_PARAM_ONOFF, true)
		Menu.drawing:addParam("health", "Draw remaining health after combo", SCRIPT_PARAM_ONOFF, true)
	


	PrintChat("<font color=\"#81BEF7\">TwistedFate (<b>"..version.."</b>) loaded successfully</font>")
end

function ComboDamage(target)
	local magicdamage = 0
	local phdamage = 0
	local truedamage = 0
	if DFG ~= 0 and (myHero:CanUseSpell(DFG)==READY) then
		m = 1.2
		truedamage = truedamage + myHero:CalcMagicDamage(target, target.maxHealth *0.15)
	else
		m = 1
	end
	if SHEEN ~= 0 then
		phdamage = phdamage + myHero.totalDamage - myHero.addDamage
	end
	
	if LICH ~= 0 then
		magicdamage  = magicdamage + 0.75 * (myHero.totalDamage - myHero.addDamage) + 0.5 * myHero.ap
	end
	
	if (myHero:GetSpellData(_Q).level ~= 0)  and myHero:CanUseSpell(_Q) == READY  then
		magicdamage = magicdamage + Qdamage[myHero:GetSpellData(_Q).level]  + Qscaling * myHero.ap
	end
	
	if (myHero:GetSpellData(_W).level ~= 0) and myHero:CanUseSpell(_W) == READY then
		magicdamage = magicdamage + Wdamage[myHero:GetSpellData(_W).level]  + Wscaling * myHero.ap + myHero.totalDamage
	end
	
	if (myHero:GetSpellData(_E).level ~= 0)  then
		magicdamage = magicdamage + Edamage[myHero:GetSpellData(_E).level]  + Escaling * myHero.ap
	end
	phdamage = myHero.totalDamage
	
	if (IgniteSlot() ~= nil) and myHero:CanUseSpell(IgniteSlot()) == READY then
		truedamage = truedamage + 50 + 20 * myHero.level
	end
	
	return m * myHero:CalcMagicDamage(target, magicdamage) + myHero:CalcDamage(target, phdamage) + truedamage
end

function IgniteSlot()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		return SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		return SUMMONER_2
	else
		return nil
	end
end
	
function GetBestTarget(Range)
	local LessToKill = 100
	local LessToKilli = 0
	local target = nil
	--	LESS_CAST	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Range) then
			DamageToHero = myHero:CalcMagicDamage(enemy, 200)
			ToKill = enemy.health / DamageToHero
			if (ToKill < LessToKill) or (LessToKilli == 0) then
				LessToKill = ToKill
				LessToKilli = i
			end
		end
	end
	
	if LessToKilli ~= 0 then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if i == LessToKilli then
				target = enemy
			end
		end
	end
	return target
end

function OnProcessSpell(unit, spell)
	if unit.isMe then
		if spell.name == "PickACard" then
			Status = SELECTING
		elseif spell.name == "goldcardlock" or spell.name == "bluecardlock" or spell.name == "redcardlock" then
			Status = SELECTED
			CardColor = NONE
			ToSelect = NONE
		elseif spell.name == "destiny" then
			CastingUltimate = true
		elseif spell.name == "gate" then 
			CastingUltimate = false
			if Menu.spells.R.auto then
				DelayAction(SelectYellow,  0.7)
			end
		end
	end
end

function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == 'pickacard_tracker' then
		Status = SELECTED
		CardColor = NONE
		ToSelect = NONE
	end
end

function OnTick()
	DFG, SHEEN, LICH = GetInventorySlotItem(3128) and  GetInventorySlotItem(3128) or 0, GetInventorySlotItem(3057) and GetInventorySlotItem(3057) or 0, GetInventorySlotItem(3100) and GetInventorySlotItem(3100) or 0
	Qtarget = GetBestTarget(Qrange)
	AAtarget = GetBestTarget(AArange)
	OW:EnableAttacks()
	OW:ForceTarget(nil)
	OW:ForceTarget(AAtarget)

	if (((myHero:CanUseSpell(_W) == READY) and (Status ~= SELECTING)) or myHero.dead) then Status = READY end
	
	RefreshKillableTexts()

	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Qrange) then
			local CastPosition, HitChance, Position = VP:GetLineCastPosition(enemy, Qdelay, Qradius, Qrange, Qspeed)
			Predictions[enemy.networkID] = {hitbox = VP:GetHitBox(enemy), Position = Vector(Position), CastPosition = Vector(CastPosition), HitChance=HitChance}
		else
			Predictions[enemy.networkID] = nil
		end
	end

	if Menu.combo then
		if Status == READY and (Menu.dl == 0 or (CountEnemyHeroInRange(Menu.dl) >= 1)) then
			ToSelect = YELLOW
			CastSpell(_W)
		end
		
		if Status == SELECTED then
			if AAtarget ~= nil then
				if (DFG ~= 0) and (myHero:CanUseSpell(DFG)==READY) then
					CastSpell(DFG, AAtarget)
				end
			end
		end
	end
	--Spells
	--
	--Q
	if Menu.spells.Q.cast and Qtarget ~= nil then
		CastQ(Qtarget)
	else
		CastQ()
	end
	
	--W
	if Menu.spells.W.yellow or Menu.spells.W.red or Menu.spells.W.blue then
		if Status == READY then
				if  Menu.spells.W.yellow then
					ToSelect = YELLOW
				elseif Menu.spells.W.red then
					ToSelect = RED
				elseif Menu.spells.W.blue then
					ToSelect = BLUE
				end
				CastSpell(_W)
		end
	end
	
	if Menu.spells.W.autoaa and (Status == SELECTING) then --Cancel the autoattacks while moving
		BlockAttacks = true
		OW:DisableAttacks()
		_G.HOWBlockAttacks = true
	elseif BlockAttacks then
		BlockAttacks = false
		_G.HOWBlockAttacks = false
	end
	
	if Menu.drawing.alert then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if (enemy.health < ComboDamage(enemy)) and ((GetTickCount() - LastAlert) > 30000)then
					PrintAlert("Enemy "..enemy.charName.." is killable!", 3, 255, 0, 0,nil)
					LastAlert = GetTickCount()
					for i = 1, 3 do
						DelayAction(RecPing,  1000 * 0.3 * i/1000, {enemy.x, enemy.z})
					end
				end
			end
		end
	end
end

function SelectYellow()
	if Status == READY then
		ToSelect = YELLOW
		CastSpell(_W)	
	end
end


function CountQHits(pos)
	local count = 0
	local LVector = Vector(myHero.visionPos) + (pos - Vector(myHero.visionPos)):rotated(0,Qangle,0)
	local MidVector = pos
	local RVector = Vector(myHero.visionPos) + (pos - Vector(myHero.visionPos)):rotated(0,-Qangle,0)
	for i = 1, 3 do
		local EndPos
		if i == 1 then
			EndPos = LVector
		elseif i == 2 then
			EndPos = MidVector
		elseif i == 3 then
			EndPos = RVector
		end

		for i, Prediction in pairs(Predictions) do
			local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero.visionPos), EndPos, Prediction.Position)
			if isOnSegment and GetDistanceSqr(Prediction.Position, pointSegment) <= (Prediction.hitbox + Qradius)^2 then
				count = count + 1
			end
		end
	end
	return count
end

function CastQ(target) 
	local PosiblePositions = {}
	if myHero:CanUseSpell(_Q) ~= READY then return end
	--Predictions[enemy.networkID] = {Position = Position, CastPosition = CastPosition, HitChance=HitChance}
	if target then
		if not Predictions[target.networkID] then return end
		local CP = Vector(Predictions[target.networkID].CastPosition)
		local CP2 = Vector(myHero) + (CP - Vector(myHero.visionPos)):rotated(0,Qangle,0)
		local CP3 = Vector(myHero) + (CP - Vector(myHero.visionPos)):rotated(0,-Qangle,0)
		table.insert(PosiblePositions, CP)
		table.insert(PosiblePositions, CP2)
		table.insert(PosiblePositions, CP3)
	elseif Menu.spells.Q.auto then
		--{hitbox = VP:GetHitBox(enemy), Position = Position, CastPosition = CastPosition, HitChance=HitChance}
		for i, Prediction in pairs(Predictions) do
			if Prediction.HitChance >= 3 then
				
				for i = 1, 3 do
					local CP = Vector(Prediction.CastPosition)
					local Direction = (CP - Vector(myHero.visionPos)):perpendicular():normalized()
					if i == 2 then
						CP = CP + (Qradius - 10 + Prediction.hitbox) * Direction
					elseif i == 3 then
						CP = CP - (Qradius - 10 + Prediction.hitbox) * Direction
					end
					local CP2 = Vector(myHero.visionPos) + (CP - Vector(myHero.visionPos)):rotated(0,Qangle,0)
					local CP3 = Vector(myHero.visionPos) + (CP - Vector(myHero.visionPos)):rotated(0,-Qangle,0)
					table.insert(PosiblePositions, CP)
					table.insert(PosiblePositions, CP2)
					table.insert(PosiblePositions, CP3)
				end
			end
		end
	end
	local BestPosition = nil
	local BestHit = 0

	for i, position in ipairs(PosiblePositions) do
		local CountHit = CountQHits(position)
		if CountHit > BestHit then
			BestHit = CountHit
			BestPosition = position
		end
	end

	if BestPosition and BestHit >= 1 then
		CastSpell(_Q, BestPosition.x, BestPosition.z)
	end
end

function RecPing(X, Y)
	Packet("R_PING", {x = X, y = Y, type = PING_FALLBACK}):receive()
end

function RefreshKillableTexts()
	if ((GetTickCount() - lastrefresh) > 1000) and (Menu.drawing.health) then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				DamageToHeros[i] =  ComboDamage(enemy)
			end
		end
		lastrefresh = GetTickCount()
	end
end
	
--[[	Credits to zikkah	]]
function GetHPBarPos(enemy)
	enemy.barData = GetEnemyBarData()
	local barPos = GetUnitHPBarPos(enemy)
	local barPosOffset = GetUnitHPBarOffset(enemy)
	local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local BarPosOffsetX = 171
	local BarPosOffsetY = 46
	local CorrectionY =  0
	local StartHpPos = 31
	barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos
	barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 
	local StartPos = Vector(barPos.x , barPos.y, 0)
	local EndPos =  Vector(barPos.x + 108 , barPos.y , 0)
	return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end

function DrawIndicator(unit, health)
	local SPos, EPos = GetHPBarPos(unit)
	local barlenght = EPos.x - SPos.x
	local Position = SPos.x + (health / unit.maxHealth) * barlenght
	if Position < SPos.x then
		Position = SPos.x
	end
	DrawText("|", 13,  math.floor(Position),  math.floor(SPos.y+10), ARGB(255,0,255,0))
end

function DrawOnHPBar(unit, health)
	local Pos = GetHPBarPos(unit)
	if health < 0 then
		DrawCircle2(unit.x, unit.y, unit.z, 100, ARGB(255, 255, 0, 0))	
		DrawText("HP: "..health,13, math.floor(Pos.x), (Pos.y+5), ARGB(255,255,0,0))
	else
		DrawText("HP: "..health,13,  math.floor(Pos.x),  math.floor(Pos.y+5), ARGB(255,0,255,0))
	end
end

function OnDraw()
	if Menu.drawing.drawQ then
		DrawCircle2(myHero.x,myHero.y,myHero.z,Qrange,ARGB(255, 0, 255, 0))
	end

	if Menu.drawing.drawAA then
		DrawCircle2(myHero.x,myHero.y,myHero.z,OW:MyRange() + 50,ARGB(255, 0, 255, 0))
	end

	if Menu.drawing.drawR  then
		DrawCircleMinimap(myHero.x,myHero.y,myHero.z,Rrange)
	end

	if Menu.drawing.drawRN and (CastingUltimate or (GetDistance(cameraPos) > (Rrange - 1500) and GetDistance(cameraPos) < (Rrange + 1500) and myHero:CanUseSpell(_R) == READY) ) then
		DrawCircle(myHero.x,myHero.y,myHero.z,Rrange,ARGB(255, 0, 255, 0))
	end
	
	if Menu.drawing.health then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				if DamageToHeros[i] ~= nil then
					local RemainingHealth = enemy.health - DamageToHeros[i]
					DrawOnHPBar(enemy, math.floor(RemainingHealth))
					DrawIndicator(enemy, math.floor(RemainingHealth))
				end
				
			end
		end
	end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
	radius = radius or 300
	quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
	quality = 2 * math.pi / quality
	radius = radius*.92
	local points = {}
	for theta = 0, 2 * math.pi + quality, quality do
		local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
		points[#points + 1] = D3DXVECTOR2(c.x, c.y)
	end
	DrawLines2(points, width or 1, color or 4294967295)
end

function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
        DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
    end
end

function OnRecvPacket(p)
	if p.header == 0x17 then
		p.pos = 1
		local NId = p:DecodeF()
		if NId == myHero.networkID then
			p.pos = 7
			local b = p:Decode1()
			if b == 0x52 and ToSelect == RED then
				Packet('S_CAST', {spellId=_W}):send()
			elseif b == 0x47 and ToSelect == YELLOW then
				Packet('S_CAST', {spellId=_W}):send()
			elseif b == 0x42 and ToSelect == BLUE then
				Packet('S_CAST', {spellId=_W}):send()
			end
		end
	end
end

function OnSendPacket(p)
	if BlockAttacks then
		local packet = Packet(p)
		if (packet:get('name') == 'S_MOVE') and ((packet:get('type') == 3) or (packet:get('type') == 7)) then
			packet:block()
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	end
end

--EOS--
