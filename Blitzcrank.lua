if myHero.charName ~= "Blitzcrank" then return end

local version = 2.03
local AUTOUPDATE = true
local SCRIPT_NAME = "Blitzcrank"

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

local Qrange2, Qrange, Qwidth, Qspeed, Qdelay = 1000, 1000, 70, 1800, 0.25
local Rrange = 600

local SelectedTarget

local spells = 
	{
		{name = "CaitlynAceintheHole", menuname = "Caitlyn (R)"},
		{name = "Crowstorm", menuname = "Fiddlesticks (R)"},
		{name = "DrainChannel", menuname = "Fiddlesticks (W)"},
		{name = "GalioIdolOfDurand", menuname = "Galio (R)"},
		{name = "KatarinaR", menuname = "Katarina (R)"},
		{name = "InfiniteDuress", menuname = "WarWick (R)"},
		{name = "AbsoluteZero", menuname = "Nunu (R)"},
		{name = "MissFortuneBulletTime", menuname = "Miss Fortune (R)"},
		{name = "AlZaharNetherGrasp", menuname = "Malzahar (R)"},	
	}

local LastCastedSpell = {}

local Stats = {CastedQs = 0, LandedQ = 0, LandedQs = {}, LandedQchampions=0, LandedQminions = 0}

local pid
local pidtime = 0

local wayPointManager = WayPointManager()

function OnLoad()--ASk thresh to add lantern-grab
	Menu = scriptConfig("Blitzcrank", "Blitzcrank")
	Menu:addParam("Grab", "Grab!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addParam("AutoE", "Auto-E after grab", SCRIPT_PARAM_ONOFF, true)

	Menu:addParam("Move", "Move to mouse", SCRIPT_PARAM_ONOFF, false)

	Menu:addSubMenu("Auto-Interrupt", "AutoInterrupt")
		for i, spell in ipairs(spells) do
			Menu.AutoInterrupt:addParam(spell.name, spell.menuname, SCRIPT_PARAM_ONOFF, true)
		end

 	Menu:addSubMenu("Auto-Grab", "AutoGrab")
	 	Menu.AutoGrab:addParam("AutoD", "Auto-Grab dashing enemies", SCRIPT_PARAM_ONOFF, true)
	 	Menu.AutoGrab:addParam("AutoS", "Auto-Grab immobile enemies", SCRIPT_PARAM_ONOFF, true)
	 	Menu.AutoGrab:addParam("DAG", "Don't auto grab if my health < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

	Menu:addSubMenu("Targets", "Targets")
		for i, enemy in ipairs(GetEnemyHeroes()) do
			Menu.Targets:addParam(enemy.charName, enemy.charName, SCRIPT_PARAM_LIST, 3, {"Don't grab", "Normal grab", "Normal + Auto-grab"})
		end

	Menu:addSubMenu("Drawing", "Drawing")
		Menu.Drawing:addParam("ShowStats", "Draw stats on the side", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("Qrange", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("DrawWP", "Draw selected target waypoints", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("DrawWPR", "Draw selected target waypoint rate", SCRIPT_PARAM_ONOFF, true)

	VP = VPrediction()
end

function CheckBLHeroCollision(Pos)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and GetDistance(enemy) < Qrange * 1.5 and Menu.Targets[enemy.charName] == 1 then
			local proj1, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(myHero), Pos, Vector(enemy))
			if (GetDistanceSqr(enemy, proj1) <= (VP:GetHitBox(enemy) * 2 + Qwidth) ^ 2) then
				return true
			end
		end
	end
	return false
end

function OnTick()
	if myHero:CanUseSpell(_Q) == READY then
		local HitChance2Targets = {}
		local SelectedTargetInRange = false
		local MinPercentageHP = myHero.health / myHero.maxHealth * 100

		for i, ally in ipairs(GetAllyHeroes()) do
			local mp = ally.health / ally.maxHealth * 100
			if mp <= MinPercentageHP and not ally.dead and GetDistance(ally) < 700 then
				MinPercentageHP = mp
			end
		end

		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, 1500) and Menu.Targets[enemy.charName] >= 1 then
				local CastPosition, HitChance, HeroPosition = VP:GetLineCastPosition(enemy, Qdelay, Qwidth, Qrange, Qspeed, myHero, true)
				
				if MinPercentageHP > Menu.AutoGrab.DAG and HitChance == 5 and Menu.AutoGrab.AutoD and Menu.Targets[enemy.charName] == 3 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if not CheckBLHeroCollision(CastPosition) then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				elseif MinPercentageHP > Menu.AutoGrab.DAG and HitChance == 4 and Menu.AutoGrab.AutoS and Menu.Targets[enemy.charName] == 3 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if GetDistance(CastPosition) > 300 and not CheckBLHeroCollision(CastPosition) then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				elseif HitChance == 2 and GetDistance(myHero.visionPos, CastPosition) < Qrange then
					if Menu.Targets[enemy.charName] > 1 then
						HitChance2Targets[enemy.networkID] = {unit = enemy, CastPosition = CastPosition}
					end
					if Menu.Grab and SelectedTarget and enemy.networkID == SelectedTarget.networkID then
						CastSpell(_Q, CastPosition.x, CastPosition.z)
					end
				end

				if SelectedTarget and enemy.networkID == SelectedTarget.networkID then
					SelectedTargetInRange = true
				end
			end
		end

		if not SelectedTargetInRange and Menu.Grab then
			local BestTarget = nil
			local MinL = math.huge
			for nid, target in pairs(HitChance2Targets) do
				local L = target.unit.health / myHero:CalcMagicDamage(target.unit, 100)
				if L < MinL then
					BestTarget = target.unit
					MinL = L
				end
			end
			if BestTarget then
				if not CheckBLHeroCollision(HitChance2Targets[BestTarget.networkID].CastPosition) then
					CastSpell(_Q, HitChance2Targets[BestTarget.networkID].CastPosition.x, HitChance2Targets[BestTarget.networkID].CastPosition.z)
				end
			end
		end
	end

	if Menu.Move and Menu.Grab then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end

	if myHero:CanUseSpell(_R) == READY then
		for i, spell in ipairs(spells) do
			if Menu.AutoInterrupt[spell.name] then
				for j, LastCast in pairs(LastCastedSpell) do
					if LastCast.name == spell.name:lower() and (os.clock() - LastCast.time) < 3 and GetDistance(LastCast.caster.visionPos, myHero.visionPos) < Rrange and ValidTarget(LastCast.caster) then
						CastSpell(_R, myHero.x, myHero.z)
						break
					end
				end
			end
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit.team ~= myHero.team and unit.type == myHero.type then
		LastCastedSpell[unit.networkID] = {name = spell.name:lower(), time = os.clock(), caster = unit}
	end
end

function OnDraw()
	if Menu.Drawing.Qrange then
		DrawCircle2(myHero.x, myHero.y, myHero.z, Qrange, ARGB(255, 0, 255, 0))
	end
	
	if SelectedTarget ~= nil then
		DrawCircle2(SelectedTarget.x, SelectedTarget.y, SelectedTarget.z, 100, ARGB(255, 255, 0, 0))

		if Menu.Drawing.DrawWP then
			wayPointManager:DrawWayPoints(SelectedTarget)
		end
		if Menu.Drawing.DrawWPR then
        	DrawText3D(tostring(wayPointManager:GetWayPointChangeRate(SelectedTarget)), SelectedTarget.x, SelectedTarget.y, SelectedTarget.z, 30, ARGB(255,0,255,0), true)
		end
	end

	if Menu.Drawing.ShowStats and Stats.CastedQs > 0 then
		DrawText("Stats", 17, 10, 10, ARGB(255,225,255,255))
		local Ratio = Stats.LandedQchampions / Stats.CastedQs

		DrawText("Landed Q's (Total): "..Stats.LandedQ.."/"..Stats.CastedQs.." "..math.floor(Stats.LandedQ/Stats.CastedQs * 100).."%", 13, 10, 30, ARGB(255,255,255,255))
		DrawText("Landed Q's (Champions): "..Stats.LandedQchampions.."/"..Stats.CastedQs.." "..math.floor(Stats.LandedQchampions/Stats.CastedQs * 100).."%", 13, 10, 45, ARGB(255,255,255,255))
		DrawText("Landed Q's (Minions): "..Stats.LandedQminions.."/"..Stats.CastedQs.." "..math.floor(Stats.LandedQminions/Stats.CastedQs * 100).."%", 13, 10, 60, ARGB(255,255,255,255))

		local i = 1
		for name, times in ipairs(Stats.LandedQs) do
			DrawText("Landed Q's ("..name.."): "..times, 13, 10, 60 + i * 15, ARGB(255,255,255,255))
			i = i + 1
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

function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local starget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= minD or starget == nil then
					minD = GetDistance(enemy, mousePos)
					starget = enemy
				end
			end
		end
		
		if starget and minD < 500 then
			if SelectedTarget and starget.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = starget
				print("<font color=\"#FF0000\">Blitzcrank: New target selected: "..starget.charName.."</font>")
			end
		end
	end
end


function OnRecvPacket(p)
	if p.header == 0xB4 then
		p.pos = 1
		local b1 = p:DecodeF()
		p.pos = p.size - 25
		local b2 = p:Decode1()
		p.pos = p.size - 44
		local b3 = p:Decode1()

		if b1 == myHero.networkID and b2 == 43 and b3 ~= 0 then
			Stats.CastedQs = Stats.CastedQs + 1
			p.pos = 37
			pid = p:DecodeF()
			pidtime = os.clock()
		end
	elseif p.header == 0x25 then
		p.pos = 1
		local pr = p:DecodeF()
		if pr == pid and (os.clock() - pidtime) < 5 then
			p.pos = p.pos + 2
			local h = objManager:GetObjectByNetworkId(p:DecodeF())
			if h and h.valid then
				Stats.LandedQ = Stats.LandedQ + 1
				if h.type == myHero.type then
					if myHero:CanUseSpell(_E) == READY then
						CastSpell(_E)
						myHero:Attack(h)
					end
					Stats.LandedQchampions = Stats.LandedQchampions + 1
					Stats.LandedQs[h.charName] = (Stats.LandedQs[h.charName] and Stats.LandedQs[h.charName] or 0 ) + 1
				else
					Stats.LandedQminions = Stats.LandedQminions + 1
				end
			end
		end
	end
end
