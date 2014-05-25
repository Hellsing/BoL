if myHero.charName ~= "Shaco" then return end

local version = 1.1
local AUTOUPDATE = true
local SCRIPT_NAME = "Shaco"

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

local LastAttack = 0
local Winduptime = 0
local AnimationTime = 0

local CLastAttack = 0
local CWinduptime = 0
local CAnimationTime = 0

local clone

local Qrange = 400
local Wrange = 425
local Erange = 625
local Rrange = 2400 --aprox

local wp
local TargetsWaypoints = {}

local DeceiveTime = 0
local isgrass = false

local HTarget  
--23

local _HYDRA
local _DFG
local _IGNITE
local _SHEEN
local _LICH
local _TF

local DamageToHeros = {}
local lastrefresh = 0

local _RED --TODO

local Htime = 0
function OnLoad()
	Menu = scriptConfig("Shaco", "Shaco")
	
	Menu:addSubMenu("Orbwalker", "Orbwalker")
		Menu.Orbwalker:addParam("Range", "Orwalk Range",  SCRIPT_PARAM_SLICE, 300, 0, 1000)
		Menu.Orbwalker:addParam("DrawRange", "Draw Orbwalk range", SCRIPT_PARAM_ONOFF, true)
		Menu.Orbwalker:addParam("Orbwalk", "Orbwalk!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	
	Menu:addSubMenu("Jungle Farm", "JungleFarm")
		Menu.JungleFarm:addParam("Orbwalk", "Orwalk the mobs",  SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Spells", "Use spells", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Farm", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	
	Menu:addSubMenu("Q (Deceive)", "Q")
		Menu.Q:addParam("DrawTime", "Draw time", SCRIPT_PARAM_ONOFF, true)
		Menu.Q:addParam("DrawRange", "Draw Q range", SCRIPT_PARAM_ONOFF, false)
		Menu.Q:addParam("SR", "Use Q while recalling (stealth recall)", SCRIPT_PARAM_ONOFF, true)
		Menu.Q:addParam("Landing", "Draw landing position", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Q"))
		
	Menu:addSubMenu("W (Jack In The Box)", "W")
		Menu.W:addParam("auto", "Auto W bushes if enemy chasing", SCRIPT_PARAM_ONOFF, true)
		Menu.W:addParam("auto2", "Auto W if the enemy is stunned (Can cause fps drops!!)", SCRIPT_PARAM_ONOFF, false)
		Menu.W:addParam("auto3", "Auto W in blitzcrank hook", SCRIPT_PARAM_ONOFF, false)
		Menu.W:addParam("DrawRange", "Draw W range", SCRIPT_PARAM_ONOFF, false)
	
	Menu:addSubMenu("E (Two-Shiv Poison)", "E")
		Menu.E:addParam("DrawRange", "Draw E range", SCRIPT_PARAM_ONOFF, false)
		Menu.E:addParam("Packets", "Cast E using packets", SCRIPT_PARAM_ONOFF, true)
		Menu.E:addParam("B", "Cast E from the back", SCRIPT_PARAM_ONOFF, false)
		Menu.E:addParam("CastE2", "Cast E!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.E:addParam("CastE", "Cast E!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	
	Menu:addSubMenu("R (Hallucinate)", "R")
		Menu.R:addSubMenu("Auto-movement", "movement")
			Menu.R.movement:addParam("S", "Let the script decide the best option", SCRIPT_PARAM_ONOFF, true)
			Menu.R.movement:addParam("Mouse", "Move to mouse", SCRIPT_PARAM_ONOFF, false)
			Menu.R.movement:addParam("Random", "Run in random directions", SCRIPT_PARAM_ONOFF, false)
			Menu.R.movement:addParam("Escape", "Run trying to escape from enemy team", SCRIPT_PARAM_ONOFF, false)
			Menu.R.movement:addParam("Kamikaze", "Orbwalk the best target in a wide range", SCRIPT_PARAM_ONOFF, false)
			Menu.R.movement:addParam("AlwaysOrbwalk", "Orbwalk the best target", SCRIPT_PARAM_ONOFF, false)
			Menu.R.movement:addParam("CTarget", "Attack shaco's target", SCRIPT_PARAM_ONOFF, false)
			
	Menu.R:addParam("DrawRange", "Draw R range", SCRIPT_PARAM_ONOFF, false)
	Menu.R:addParam("Orbwalk", "Force orbwalking", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	
	Menu:addSubMenu("Items", "Items")
	Menu.Items:addParam("Hydra", "Use Hydra", SCRIPT_PARAM_ONOFF, true)
	Menu.Items:addParam("DFG", "Use DFG", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addSubMenu("Damage calculation", "DamageCalc")
		Menu.DamageCalc:addSubMenu("Combo", "Combo")
			Menu.DamageCalc.Combo:addParam("Q", "Q",  SCRIPT_PARAM_SLICE, 1, 0, 1)
			Menu.DamageCalc.Combo:addParam("W", "W",  SCRIPT_PARAM_SLICE, 1, 0, 10)
			Menu.DamageCalc.Combo:addParam("E", "E",  SCRIPT_PARAM_SLICE, 1, 0, 3)
			Menu.DamageCalc.Combo:addParam("R", "R",  SCRIPT_PARAM_SLICE, 1, 0, 1)
			Menu.DamageCalc.Combo:addParam("AA", "AA",  SCRIPT_PARAM_SLICE, 1, 0, 5)
			Menu.DamageCalc.Combo:addParam("CAA", "CAA",  SCRIPT_PARAM_SLICE, 1, 0, 5)
			Menu.DamageCalc.Combo:addParam("IGNITE", "IGNITE",  SCRIPT_PARAM_SLICE, 1, 0, 1)
	
	Menu.DamageCalc:addParam("Draw", "Draw health after combo in enemies", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)
	
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		_IGNITE = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		_IGNITE = SUMMONER_2
	else
		_IGNITE = nil
	end
	
	JungleMinions = minionManager(MINION_JUNGLE, Erange, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	VP = VPrediction()
	wp = WayPointManager()
end


function GetComboDamage(target)
	local result = 0
	local m = 1
	local p = Facing(target) and 1 or 1.2
	local Qcrit = {1, 1.4, 1.6, 1.8, 2, 2.2}
	
	local Wdamage = {35, 50, 65, 80, 95}
	local Wscaling = 0.2
	
	local Edamage = {35, 50, 65, 80, 95}
	local Escaling = 1
	
	local Rdamage= {300, 450, 600}
	local Rscaling = 1
	
	
	local Qlevel = myHero:GetSpellData(_Q).level
	local Wlevel = myHero:GetSpellData(_W).level
	local Elevel = myHero:GetSpellData(_E).level
	local Rlevel = myHero:GetSpellData(_R).level
	
	
	if _HYDRA and myHero:CanUseSpell(_HYDRA) == READY then
		result = result + myHero:CalcDamage(target, myHero.totalDamage)
	end
	
	if _DFG and myHero:CanUseSpell(_DFG) == READY then
		result = result + myHero:CalcMagicDamage(target, target.maxHealth *0.15)
		m = 1.2
	end
	
	if Menu.DamageCalc.Combo.IGNITE and _IGNITE and myHero:CanUseSpell(_IGNITE) == READY then
		result = result + 50 + 20 * myHero.level
	end
	
	if Menu.DamageCalc.Combo.W > 0 and Wlevel > 0 then
		for i =1, Menu.DamageCalc.Combo.W, 1 do
			result = result + m * (myHero:CalcMagicDamage(target, Wdamage[Wlevel]) + myHero.ap * Wscaling)
		end
	end
	
	if Menu.DamageCalc.Combo.E > 0 and Elevel > 0 then
		for i =1, Menu.DamageCalc.Combo.E, 1 do
			result = result + p * m * (myHero:CalcMagicDamage(target, Edamage[Elevel]) + myHero.ap * Escaling + myHero.damage * Escaling)
		end
	end
	
	if Menu.DamageCalc.Combo.AA > 0 then
		local sheendamage = _SHEEN and myHero.totalDamage - myHero.damage or 0
		local lichdamage = _LICH and myHero.ap or 0
		local tfdamage = _TF and 2 * (myHero.totalDamage - myHero.damage) or 0
		
		result = result + p * (myHero:CalcDamage(target, Qcrit[Qlevel+1] * myHero.totalDamage + sheendamage + tfdamage)) + p * m * (myHero:CalcMagicDamage(target, lichdamage))
		for i =2, Menu.DamageCalc.Combo.AA, 1 do
			result = result + p * (myHero:CalcDamage(target,  myHero.totalDamage))
		end
	end
	
	if Menu.DamageCalc.Combo.CAA > 0 and (clone or myHero:CanUseSpell(_R) == READY) then
		for i =1, Menu.DamageCalc.Combo.CAA, 1 do
			result = result +  (myHero:CalcDamage(target,  myHero.totalDamage * 0.75))
		end
	end
	
	if Menu.DamageCalc.Combo.R == 1 and (clone or myHero:CanUseSpell(_R) == READY) and Rlevel > 0 then
		result = result + p * m * myHero:CalcMagicDamage(target, Rdamage[Rlevel])
	end
	return result
end

function TrackWaypoints()
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			local Waypoints = wp:GetWayPoints(enemy)
			if #Waypoints > 1 and GetDistance(Waypoints[1], Waypoints[2]) > 50 then
				TargetsWaypoints[enemy.charName] = Waypoints
			end
		end
	end
	
	for i, mob in ipairs(JungleMinions.objects) do
		if ValidTarget(mob) then
			local Waypoints = wp:GetWayPoints(mob)
			if #Waypoints > 1 and GetDistance(Waypoints[1], Waypoints[2]) > 50 then
				TargetsWaypoints[mob.networkID] = Waypoints
			end
		end
	end
end

function Facing(target)
	local b = GetBack(target)
	
	if b.x == target.x and b.z == target.z then
		return true
	end
	
	--[[does not work if getdistance(target) < 30, too lazy to check the angle :)]]
	if GetDistance(b) >= GetDistance(target) then
		return true
	else
		return false
	end
end

function GetBack(target)
	if target then
		local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(target, 0, 1, math.huge, myHero.ms, myHero)
		if not TargetsWaypoints[target.networkID] then
			return Vector(Position.x, 0, Position.z)
		else
			return Vector(Position.x, 0, Position.z) -  60 * Vector(TargetsWaypoints[target.networkID][2].x - Position.x, 0, TargetsWaypoints[target.networkID][2].y - Position.z):normalized()
		end
	end
end

function GetTrueRange()
	return 240
end


function OnSendPacket(p)
	 if p.header == Packet.headers.S_CAST then
		p.pos = 1
		local decodedPacket = Packet(p)
		if decodedPacket:get('spellId') == RECALL and Menu.Q.SR and myHero:CanUseSpell(_Q) then 
			Packet('S_CAST', { spellId = _Q, toX = myHero.x, toY = myHero.z, fromX = myHero.x, fromY = myHero.z }):send()
			Packet('S_CAST', { spellId = RECALL, toX = myHero.x, toY = myHero.z, fromX = myHero.x, fromY = myHero.z }):send()
		end
	end
end

function OnTick()
	_HYDRA = GetInventorySlotItem(3074) and GetInventorySlotItem(3074) or GetInventorySlotItem(3077)
	_DFG	= GetInventorySlotItem(3074) and GetInventorySlotItem(3074) or nil
	_SHEEN = GetInventorySlotItem(3057) and GetInventorySlotItem(3057) or nil
	_LICH	= GetInventorySlotItem(3100) and GetInventorySlotItem(3100) or nil 
	_TF =  GetInventorySlotItem(3078) and GetInventorySlotItem(3078) or nil 
	
	RefreshKillableTexts()
	TrackWaypoints()
	JungleMinions:update()
	if Menu.JungleFarm.Farm then
		if JungleMinions.objects[1] ~= nil then
			local mob = JungleMinions.objects[1]
			
			if Menu.JungleFarm.Orbwalk then
				if os.clock() + GetLatency()/2000 > LastAttack + AnimationTime and GetDistance(mob) < GetTrueRange() then
						Packet('S_MOVE', {type = 3, targetNetworkId=mob.networkID}):send()
					elseif os.clock() + GetLatency()/2000 > LastAttack + Winduptime + 0.05 then
						local Point = GetBack(mob)
						if GetDistance(Point) > 30 then
							--myHero:MoveTo(Point.x, Point.z)
							Packet('S_MOVE', {type = 2, x = Point.x, y = Point.z}):send()
						end
				end
			end
			
			if Menu.JungleFarm.Spells then
				if myHero:CanUseSpell(_E) == READY then
					CastSpell(_E, mob)
				end
				if myHero:CanUseSpell(_W) == READY then
					CastSpell(_W, mob.x, mob.z)
				end
			end
		end
	end

	if Menu.Orbwalker.Orbwalk then
		local target = GetBestTarget(myHero, Menu.Orbwalker.Range)
		
		if target and ValidTarget(target) then
				if os.clock() + GetLatency()/2000 > LastAttack + AnimationTime and GetDistance(target) < GetTrueRange() then
					Packet('S_MOVE', {type = 3, targetNetworkId=target.networkID}):send()
				elseif os.clock() + GetLatency()/2000 > LastAttack + Winduptime + 0.05 then
					local Point = GetBack(target)
					if GetDistance(Point) > 30 then
						Packet('S_MOVE', {type = 2, x = Point.x, y = Point.z}):send()
					end
				end
		else
			Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
		end
	end
	
	if Menu.W.auto and DeceiveTime == 0 and (false or CountEnemyHeroInRange(700, myHero)>0)  and (myHero:CanUseSpell(_W) == READY) then
		if isgrass == false and IsWallOfGrass(D3DXVECTOR3(myHero.x, myHero.y, myHero.z)) then
			CastSpell(_W, myHero.x, myHero.z)	
		end
		isgrass = IsWallOfGrass(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
	end
	
	if Menu.W.auto2 and DeceiveTime == 0 and (myHero:CanUseSpell(_W) == READY) then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(enemy, 0.5, 1, Wrange)
				if GetDistance(CastPosition) < Wrange and HitChance == 4 then--[[enemy immobile]]
					CastSpell(_W, CastPosition.x, CastPosition.z)
				end
			end
		end
	end
	
	if Menu.E.CastE or Menu.E.CastE then
		local target = GetBestTarget(myHero, Erange)
		if target and ValidTarget(target) and (not Facing(target) or not Menu.E.B) then
		
			if Menu.Items.DFG and _DFG and myHero:CanUseSpell(_DFG) == READY then
				CastSpell(_DFG, target)
			end
			
			if Menu.E.Packets then
				Packet("S_CAST", {spellId = _E, targetNetworkId = target.networkID}):send()
			else
				CastSpell(_E, target)
			end
		end
	end
	
	if myHero:CanUseSpell(_R) == COOLDOWN or myHero:GetSpellData(_R).name:lower():find("full") then
		clone = nil
	end
		
	if clone then
		local ctarget = GetBestTarget(clone, Menu.Orbwalker.Range)
		
		if Menu.R.movement.S then
			Menu.R.movement['AlwaysOrbwalk'] = false
			Menu.R.movement['Mouse'] = false
			Menu.R.movement['Random'] = false
			Menu.R.movement['Escape'] = false
			Menu.R.movement['Kamikaze'] = false
			Menu.R.movement["CTarget"] = false
			
			if ValidTarget(HTarget) and (os.clock() - Htime < 5) then
				ctarget = HTarget
				Menu.R.movement["CTarget"] = true
			elseif ctarget and ctarget.health < ctarget.maxHealth * 0.25 then
				Menu.R.movement['AlwaysOrbwalk'] = true
			elseif myHero.health < myHero.maxHealth * 0.25 then
				Menu.R.movement['Escape']  = true
			else
				Menu.R.movement['Kamikaze'] = true				
			end
		end
		
		if ValidTarget(HTarget) and Menu.R.movement.CTarget then
			if os.clock() + GetLatency()/2000 > CLastAttack + CAnimationTime+0.05 then
				CastSpell(_R, HTarget.x, HTarget.z)
			end
		elseif Menu.R.Orbwalk or Menu.R.movement.Kamikaze or Menu.R.movement.AlwaysOrbwalk then	
			if Menu.R.movement.Kamikaze then
				ctarget = GetBestTarget(clone, 1000)
				if not ctarget then
					ctarget = GetBestTarget(clone, 2000)
				end
			end
			if ctarget and ValidTarget(ctarget) then
				if os.clock() + GetLatency()/2000 > CLastAttack + CAnimationTime and GetDistance(clone, ctarget) < GetTrueRange() then
					CastSpell(_R, ctarget.x, ctarget.z)
				elseif os.clock() + GetLatency()/2000 > CLastAttack + CWinduptime + 0.05 and GetDistance(clone, ctarget) < 30 then
					local Point = GetBack(ctarget)
					CastSpell(_R, ctarget.x, ctarget.z)
				elseif os.clock() + GetLatency()/2000 > CLastAttack + CWinduptime + 0.05 then
					local Point = Vector(GetBack(ctarget)) - 1000 * (Vector(clone) - Vector(GetBack(ctarget))):normalized()
					CastSpell(_R, Point.x, Point.z)
					--[[Casting CastSpell(_R, ctarget.x, ctarget.z) causes the clone to attack that unit instead of moving to that point]]
				end
			else
					CastSpell(_R, mousePos.x, mousePos.z)
			end
			
		elseif Menu.R.movement.Random then
			local movepoint =  wp:GetWayPoints(myHero)
			local line = Vector(clone) - Vector(myHero):perpendicular()
			local Direction = (Vector(movepoint[#movepoint].x, 0, movepoint[#movepoint].z) - Vector(myHero)):mirrorOn(line):normalized()
			
			local movepos = Vector(clone) + 500 * Direction
			CastSpell(_R, movepos.x, movepos.z)
			
		elseif Menu.R.movement.Mouse then
			CastSpell(_R, mousePos.x, mousePos.z)
			
		elseif Menu.R.movement.Escape then
			local Point = Vector(0, 0, 0)
			local Count = 0
			for i, hero in ipairs(GetAllyHeroes()) do
				Point = Vector(Point) + Vector(hero)
				Count = Count + 1
			end
			Count = Count or 1
			Point = 1/Count * Vector(Point)
			CastSpell(_R, Point.x, Point.z)
		end
	end
end

function GetBestTarget(From, Range)
	local MKillable = nil
	local Min = 0
	local Closest = 0
	local D = 0

	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Range) then
			local Damage = myHero.ap < 100 and myHero:CalcDamage(enemy, 200) or myHero:CalcMagicDamage(enemy, 200)
			local DMG = enemy.health / Damage

			
			if (DMG <= Min or MKillable == nil) then
				MKillable = enemy
				Min = DMG
			end
		end
	end

	return MKillable
end

function OnCreateObj(object)
	--[[TO-Check: Different obects names depending on skins?]]
	if GetDistance(object) < 500 and object.name:lower():find("jester_copy.troy") then
		clone = object
	end
end

function OnGainBuff(unit, buff)
	--[[Q]]--
	if unit.isMe and buff.name == "Deceive" then
		DeceiveTime = os.clock()
	end
end

function OnLoseBuff(unit, buff)
	--[[Q]]--
	if unit.isMe and buff.name == "Deceive" then
		DeceiveTime = 0
	end
end

function OnProcessSpell(unit, spell)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and enemy.networkID == unit.networkID and spell.target then
			TargetsWaypoints[enemy.networkID] = {
			[2] = {x =  spell.target.x, y = spell.target.z}
			}
		end
	end
	for i, mob in ipairs(JungleMinions.objects) do
		if ValidTarget(mob) and unit.networkID == mob.networkID and spell.target then
						TargetsWaypoints[mob.networkID] = {
			[2] = {x =  spell.target.x, y = spell.target.z}
			}
		end
	end
	--[[Clone auto-attack]]
	if unit.team == myHero.team and unit.charName == myHero.charName and unit.networkID ~= myHero.networkID and  spell.name:lower():find("attack") then
		CWinduptime = spell.windUpTime
		CAnimationTime = spell.animationTime
		CLastAttack = os.clock() - GetLatency()/2000
	end
	
	if unit.networkID == myHero.networkID and spell.name:lower():find("attack") then
		Winduptime = spell.windUpTime
		AnimationTime = spell.animationTime
		LastAttack = os.clock() - GetLatency()/2000
		
		if Menu.Items.Hydra and _HYDRA and myHero:CanUseSpell(_HYDRA) == READY and spell.target.type == myHero.type then
			CastSpell(_HYDRA)
		end
			
		if spell.target then
			HTarget = spell.target
			Htime = os.clock()
		end
	end
	
	if Menu.W.auto3 and ValidTarget(unit, 1000) and unit.charName == "Blitzcrank" and spell.name:lower():find("grab") and (myHero:CanUseSpell(_W) == READY) then
		local spoint = Vector(unit)
		local Direction = - (Vector(unit) - Vector(spell.endPos)):normalized()
		local epoint = spoint + 1050 * Direction
		local projection, line, isonsegment = VectorPointProjectionOnLineSegment(spoint, epoint, Vector(myHero) - 60 * Direction)
		--[[Maybe better evade first and the put the box :)]]
		if isonsegment and GetDistance(projection) < Wrange then
			print("W casted in blitzcrank's grab, did it work? :o")
			CastSpell(_W, projection.x, projection.z)
		end
	end
end

function GetLandingPos(CastPoint)
	local wall = IsWall(D3DXVECTOR3(CastPoint.x, CastPoint.y, CastPoint.z))
	local Point = Vector(CastPoint)
	local StartPoint = Vector(Point)
	--[[Checks for 500 / 10 * pi/0.2 points]]
	for i = 0, 500, 10--[[Decrease for better precision, increase for less fps drops:]] do
		for theta = 0, 2 * math.pi + 0.2, 0.2 --[[Same :)]] do
			local c = Vector(StartPoint.x + i * math.cos(theta), StartPoint.y, StartPoint.z + i * math.sin(theta))
			if not IsWall(D3DXVECTOR3(c.x, c.y, c.z)) then
				return c
			end
		end
	end
	return Point
end

function DLine(From, To, Color)
	DrawLine3D(From.x, From.y, From.z, To.x, To.y, To.z, 2, Color)
end

function DrawQ(To, Color)
	local myPos = Vector(myHero.x, myHero.y, myHero.z)
	local Direction = (Vector(To.x, To.y, To.z) - Vector(myPos)):perpendicular():normalized()
	local Distance = GetDistance(To, myPos)
	local Width = 75
	
	local P1r = Vector(myPos) + Width * Vector(Direction)
	local P1l = Vector(myPos) - Width * Vector(Direction)
	local P2r = Vector(myPos) + Width * Direction - Vector(Direction):perpendicular() * GetDistance(To)
	local P2l = Vector(myPos) - Width * Direction - Vector(Direction):perpendicular() * GetDistance(To)
	
	DLine(P1r, P1l, Color)
	DLine(P1r, P2r, Color)
	DLine(P1l, P2l, Color)
	DLine(P2r, P2l, Color)
end

--[[Update the bar texts]]
function RefreshKillableTexts()
	if ((GetTickCount() - lastrefresh) > 1000) then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				DamageToHeros[i] =  GetComboDamage(enemy)
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
	--[[
	debug:
	for i, enemy in ipairs(GetEnemyHeroes()) do
		 local P = GetBack(enemy)
		 DrawCircle2( P.x,  P.y,  P.z, 100, ARGB(255, 255, 0, 0))	
	end
	]]--

	if Menu.DamageCalc.Draw then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				local RemainingHealth = 0
				if DamageToHeros[i] ~= nil then
					RemainingHealth = enemy.health - DamageToHeros[i]
				end
					DrawOnHPBar(enemy, math.floor(RemainingHealth))
					DrawIndicator(enemy, math.floor(RemainingHealth))
			end
		end
	end
	
	if Menu.Orbwalker.DrawRange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Menu.Orbwalker.Range, ARGB(255, 255, 0, 0))	
		if clone then
			DrawCircle2(clone.x, clone.y, clone.z, Menu.Orbwalker.Range, ARGB(255, 0, 255, 0))	
		end
	end
	
	if Menu.Q.DrawRange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Qrange, ARGB(255, 255, 0, 0))	
	end
	
	if Menu.W.DrawRange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Wrange, ARGB(255, 255, 0, 0))	
	end
	
	if Menu.E.DrawRange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Erange, ARGB(255, 255, 0, 0))	
	end
	
	if Menu.R.DrawRange and clone then
		DrawCircle(myHero.x, myHero.y, myHero.z, Rrange, ARGB(255, 0, 255, 0))	
	end
	
	if Menu.Q.Landing then
		local CastPoint = GetDistance(mousePos) <= Qrange and Vector(mousePos) or Vector(myHero) + Qrange * (Vector(mousePos)-Vector(myHero)):normalized()
		CastPoint = GetLandingPos(CastPoint)
		local Color = myHero:CanUseSpell(_Q)==READY and  ARGB(255, 0, 255, 0) or ARGB(255, 255, 0, 0)
		DrawQ(CastPoint, Color)
	end
	
	if Menu.Q.DrawTime and DeceiveTime and DeceiveTime ~= 0 then
		local myPos = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
		DrawText(tostring(math.floor(35 - 10*(os.clock() - DeceiveTime))), 16, myPos.x, myPos.y, ARGB(255,255,0,0))
	end
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
