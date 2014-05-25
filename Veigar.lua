if myHero.charName ~= "Veigar" then return end

local version = 1.51
local AUTOUPDATE = true
local SCRIPT_NAME = "Veigar"

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

	
--[[	Spell Data	]]
	--[[	Ranges and radiuses]]
	local Qrange = 650
	local Wrange = 900
	local Wradius = 112
	local Erange = 650
	local Eradius = 350 
	local Rrange = 650
	
	--[[	Damage	]]
	local Qdamage = {80, 125, 170, 215, 260}
	local Qscaling = 0.6
	local Wdamage = {120, 170, 220, 270, 320}
	local Wscaling = 1
	local Rdamage = {250, 375, 500}
	local Rscaling = 1.2

	--[[	Delays	]]
	local Wdelay = 1.25
	local Edelay = 0.2
	local Ewidth = 10
	--[[	Availability	]]
	local ready = {}
	local _DFG = nil
	local _IGNITE = nil
	local Qlevel = 0
	local Wlevel = 0
	local Elevel = 0
	local Rlevel = 0

	--[[	Mana	]]
	local QMana = {60, 65, 70, 75, 80}
	local WMana = {70, 80, 90, 100, 110}
	local EMana = { 80, 90, 100, 110, 120}
	local RMana = {125, 175, 225}
	
--[[	Target Selector	]]
	local QRTarget = nil
	local ETarget = nil
	local EnemyMinions = nil
	local StunnedTargets = {}
	local focusedtarget = nil
	
--[[	Combo	]]
	local Comboing = false
	local ComboTarget = nil
	local CurrentCombo = {}

--[[	Drawing	]]
	local DamageToHeros = {}
	local lastrefresh = 0
	local PredictedTargetPos = nil
	local ECastPosition = nil
	local ComboTick = 0
--[[Orbwalker]]
	local LastAttack = 0
	local LastWindUp = 0
	local LastAnimationT = 0 

	--                   Caitlyn R             Fiddle R   Fiddle W         Galio R              KatarinaR    Warwick R         Nunu R         MissFortune R             Malzahar R
	InterruptList = {"CaitlynAceintheHole", "Crowstorm", "DrainChannel", "GalioIdolOfDurand", "KatarinaR", "InfiniteDuress", "AbsoluteZero", "MissFortuneBulletTime", "AlZaharNetherGrasp"}
	
function OnLoad()
	Menu = scriptConfig("Veigar", "Veigar")
	--[[	Combo	]]
	Menu:addSubMenu("Combo", "Combo")
	Menu.Combo:addParam("AutoW", "Use W stunned enemies (Recommended)", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("UseE", "Use E in combo ("..Qrange.." range)", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("packet", "Cast targetted spells using packets", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	Menu.Combo:addParam("moveto", "Move to mouse", SCRIPT_PARAM_ONOFF, false)
	Menu.Combo:addParam("Enabled", "Use Combo", SCRIPT_PARAM_ONKEYDOWN, false,   32)
	Menu.Combo:addParam("Enabled2", "Use ALL spells in target", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("R"))
	
	--[[Harras]]
	Menu:addSubMenu("Harras", "Harras")
	Menu.Harras:addParam("UseQ", "Harras enemy using Q", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
	Menu.Harras:addParam("UseW", "Harras enemy using W", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
	
	--[[	E	]]
	Menu:addSubMenu("E", "E")
	Menu.E:addParam("interrupt", "Use E to interrupt channeled ultimates", SCRIPT_PARAM_ONOFF, true)
	Menu.E:addSubMenu("Interrupt list", "List")
	for i, spell in ipairs(InterruptList) do 
		Menu.E.List:addParam(spell, "Interrupt "..spell, SCRIPT_PARAM_ONOFF, true)
	end
	Menu.E:addParam("ProdictionPro", "Use E on stunned enemies", SCRIPT_PARAM_ONOFF, true)
	Menu.E:addParam("UseE", "Cage enemies in E range", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	Menu.E:addParam("MultiTarget", "Try to stun as many enemies as possible", SCRIPT_PARAM_ONOFF, true)
	Menu.E:addParam("StunC", "Stun closest enemy", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("X"))
	
	--[[	Dont use R on..]]
	Menu:addSubMenu("Targets", "Targets")
	for i, enemy in ipairs(GetEnemyHeroes()) do
		Menu.Targets:addParam("DontUseCombo"..enemy.charName, "Dont use R/DFG in "..enemy.charName, SCRIPT_PARAM_ONOFF, false)
	end	
	
	--[[	Farm	]]
	Menu:addSubMenu("Farm", "Farm")
	Menu.Farm:addParam("Enabled", "Farm minions using Q", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
	Menu.Farm:addParam("EnabledW", "Farm minions using W", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("W"))
	Menu.Farm:addParam("SaveE", "Dont farm if Mana < EManaCost",  SCRIPT_PARAM_ONOFF, true)
	
	--[[	Drawing	]]
	Menu:addSubMenu("Drawing", "Drawing")
	Menu.Drawing:addParam("lagfree", "Use lag-free drawing", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("killable", "Draw killable enemies", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("health", "Draw remaining health in the bar", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("minions", "Draw circle arround killable minion with Q", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("Erange", "Draw E max range", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("Qrange", "Draw Q max range", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("Mana", "Warn when low Mana", SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("Priority", "Draw circle arround selected target (by left clicking)", SCRIPT_PARAM_ONOFF, true)
	
	--[[	Debug	]]
	Menu:addSubMenu("Debug", "Debug")
	Menu.Debug:addParam("Enabled", "Enable debug?", SCRIPT_PARAM_ONOFF, false)
	Menu.Debug:addParam("Predict", "Constantly predict E positions", SCRIPT_PARAM_ONOFF, false)
	Menu.Debug:addParam("DrawT", "Draw text on the sides", SCRIPT_PARAM_ONOFF, false)
	
	Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)

	--[[	Enemy minions]]
	EnemyMinions = minionManager(MINION_ENEMY, Qrange, myHero, MINION_SORT_HEALTH_ASC)
	EnemyMinions2 = minionManager(MINION_ENEMY, Wrange, myHero, MINION_SORT_HEALTH_ASC)
	
	--[[VPrediction]]
	VP = VPrediction()
	
	PrintChat("<font color=\"#81BEF7\">ProVeigar ("..version..") loaded successfully</font>")
end

function ManaCost(Spell)
	if Spell == _Q and Qlevel ~= 0 then
		return QMana[Qlevel]
	elseif Spell == _W and Wlevel ~= 0 then
		return WMana[Wlevel]
	elseif Spell == _E and Elevel ~= 0 then
		return EMana[Elevel]
	elseif Spell == _R and Rlevel ~= 0 then
		return RMana[Rlevel]
	end
	return 0
end

function ComboManaCost(Combo)
	local Result = 0	
	for i, spell in ipairs(Combo) do
		Result = Result + ManaCost(spell)
	end
	return Result
end

--[[	Returns the true damage that one spell deals to a target]]
function GetDamage(target, Spell, usedfg)
	TotalMagicDamage = 0
	TrueDamage = 0
	if usedfg and _DFG ~= -1 then
		m = 1.2
		if (_DFG ~= -1 and Spell == _DFG) then
			TotalMagicDamage = TotalMagicDamage + target.maxHealth * 0.15 / 1.2
		end
	else
		m = 1
	end

	if (ready[_Q] and (Qlevel ~= 0) and (Spell == _Q)) then
		TotalMagicDamage = TotalMagicDamage + Qdamage[Qlevel] + Qscaling * myHero.ap
	end
	if (ready[_E] and ready[_W] and (Wlevel ~= 0) and (Spell == _W)) then
		TotalMagicDamage = TotalMagicDamage + Wdamage[Wlevel] + Wscaling * myHero.ap
	end
	if (ready[_R] and (Rlevel ~= 0)  and (Spell == _R)) then
		TotalMagicDamage = TotalMagicDamage + Rdamage[Rlevel] + Rscaling * myHero.ap + 0.8 * target.ap
	end
	TrueDamage = m * myHero:CalcMagicDamage(target, TotalMagicDamage)

	if ready[_IGNITE]  and (Spell == _IGNITE) then
		TrueDamage = TrueDamage + myHero.level * 20 + 50
	end
	return TrueDamage
end
	
function ComboGetDamage(target, Array)
	local TotalDamage = 0
	local usedfg = false
	for i, spell in ipairs(Array) do
		if ((_DFG ~= -1) and (spell == _DFG)) then
			usedfg = true		
		end
	end
	for i, spell in ipairs(Array) do
		TotalDamage = TotalDamage + GetDamage(target, spell, usedfg)
	end
	return TotalDamage
end

--[[Calculates the points where E has to be casted to hit 2 targets.]]
function CalculateEcastPoints(target1, target2)
	local CenterPoint = Vector((target1.x + target2.x)/2,0,(target1.z + target2.z)/2)
	local Perpendicular = Vector(target1.x - target2.x, 0, target1.z - target2.z):normalized():perpendicular()
	local D = GetDistance(target1, target2) / 2
	local A = math.sqrt(Eradius * Eradius - D * D)
	local S1 = CenterPoint + A * Perpendicular
	local S2 = CenterPoint - A * Perpendicular
	return S1, S2
end

--[[E callback]]
function ProdictionECallback(unit, pos, spell)
	if not ready[_E] then return end
	local PredictedPosition = Vector(pos.x, 0, pos.z)
	local myPos = Vector(myHero.x, 0, myHero.z)
	local Targets = {}
	if Menu.E.MultiTarget then 
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and (enemy.charName ~= unit.charName) then
				local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(enemy, Edelay, Ewidth, math.huge)
				if Position and (GetDistance(Position) <= Erange + Eradius) then
					table.insert(Targets, Position)
				end
			end
		end
		
		--[[At the moment only 2 targets supported]]
		while #Targets > 1 do
			table.remove(Targets, 1)
		end
		
		--[[The main target and another 1]]
		if #Targets == 1 then
			PredictedTargetPos = PredictedPosition -- for debugging
			SecondaryPos = Vector(Targets[1].x, 0, Targets[1].z)
			if (GetDistance(PredictedPosition, SecondaryPos) <= Eradius * 2) and (GetDistance(PredictedPosition, SecondaryPos) ~= 0) then
				--Get the point(s) to get the two targets 
				Solution1, Solution2 = CalculateEcastPoints(SecondaryPos, PredictedPosition)
				if GetDistance(Solution1) <= Erange then
					ECastPosition = Solution1
				elseif GetDistance(Solution2) <= Erange then
					ECastPosition = Solution2
				else--[[Solutions out of range, calculate the solution for the main target]]
					table.remove(Targets, 1)
				end
			else --Cant get the two targets, calculate the solution for the main target
				table.remove(Targets, 1)
			end
		end
	end
	
	--[[Only 1 target in range, cast E in our direction]]
	if #Targets == 0 then
		local DirectionVector = Eradius * (myPos - PredictedPosition):normalized()
		ECastPosition = Vector(PredictedPosition.x + DirectionVector.x, 0, PredictedPosition.z + DirectionVector.z)
	end
	
	if ECastPosition and (GetDistance(ECastPosition) < Erange) and not Menu.Debug.Predict then
			CastSpell(_E, ECastPosition.x, ECastPosition.z)
	end
end

--[[W callback]]
function ProdictionWCallback(unit, pos, spell)
	local PredictedPosition = Vector(pos.x, 0, pos.z)
	local myPos = Vector(myHero.x, 0, myHero.z)
		if (GetDistance(PredictedPosition) < (Wrange + Wradius)) and ready[_W] then
			local DirectionVector = Wrange * (PredictedPosition - myPos):normalized()
			if GetDistance(PredictedPosition) <= Wrange then
				CastSpell(_W, PredictedPosition.x, PredictedPosition.z)		
				if Menu.Debug.Enabled then
					PrintChat("W casted")
				end
			else
				CastSpell(_W, myPos.x + DirectionVector.x, myPos.z + DirectionVector.z)
				if Menu.Debug.Enabled then
					PrintChat("W casted")
				end
			end
		end

end

function UseE(target)
	local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(target, Edelay, Ewidth, math.huge)
	ProdictionECallback(target, Position, _E)
end

function UseSpell(target, Spell)
	if Spell == _Q then
		if Menu.Combo.packet then
			Packet("S_CAST", {spellId = Spell, targetNetworkId = target.networkID}):send()
		else
			CastSpell(Spell, target)
		end
	elseif Spell == _W then
		--Only on stunned
	elseif Spell == _E then
		if Menu.Combo.UseE then
			UseE(target)
		end
	elseif Spell == _R then
		if Menu.Combo.packet then
			Packet("S_CAST", {spellId = Spell, targetNetworkId = target.networkID}):send()
		else
			CastSpell(Spell, target)
		end
	elseif Spell == _DFG then
		if Menu.Combo.packet then
			Packet("S_CAST", {spellId = Spell, targetNetworkId = target.networkID}):send()
		else
			CastSpell(Spell, target)
		end
	elseif Spell == _IGNITE then
		if Menu.Combo.packet then
			Packet("S_CAST", {spellId = Spell, targetNetworkId = target.networkID}):send()
		else
			CastSpell(Spell, target)
		end
	end
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
			if focusedtarget and starget.charName == focusedtarget.charName then
				focusedtarget = nil
			else
				focusedtarget = starget
			end
		end
	end
end

function GetBestTarget(Range)
	local LessToKill = 100
	local LessToKilli = 0
	local target = nil
	
	--	LESS_CAST	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, Range) then
			if focusedtarget ~= nil and enemy.charName == focusedtarget.charName then return enemy end
			DamageToHero = myHero:CalcMagicDamage(enemy, 200)
			ToKill = enemy.health / DamageToHero
			if ((ToKill < LessToKill) and not Menu.Targets["DontUseCombo"..enemy.charName]) or (LessToKilli == 0) then
				if Menu.Targets["DontUseCombo"..enemy.charName] then
					LessToKill = ToKill
				else
					LessToKill = 10
				end
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

local LastTick = 0
local TickLimit = 10
function CheckStunnedTargets()
	if (os.clock() - LastTick) > 1/TickLimit then
		for i, enemy in ipairs(GetEnemyHeroes())  do
			local Position, HitChance = VP:GetPredictedPos(enemy, Edelay)
			if HitChance >= 3 then
				ProdictionECallback(enemy, enemy, _E)
			end
			Position, HitChance = VP:GetPredictedPos(enemy, Wdelay)
			if HitChance >= 3 then
				ProdictionWCallback(enemy, enemy, _W)
			end
		end
	end
end

function OnTick()
	--[[	Refresh our spells data]]
	_DFG = GetInventorySlotItem(3128) or -1
	_IGNITE = IgniteSlot() or -1
	ready[_DFG] = (_DFG ~= -1) and (myHero:CanUseSpell(_DFG) == READY) or false
	ready[_IGNITE] =  (_IGNITE ~= -1) and (myHero:CanUseSpell(_IGNITE) == READY) or false
	ready[_Q] = (myHero:CanUseSpell(_Q) == READY)
	ready[_W] = (myHero:CanUseSpell(_W) == READY)
	ready[_E] = (myHero:CanUseSpell(_E) == READY)
	ready[_R] = (myHero:CanUseSpell(_R) == READY)
	Qlevel = myHero:GetSpellData(_Q).level
	Wlevel = myHero:GetSpellData(_W).level
	Elevel = myHero:GetSpellData(_E).level
	Rlevel = myHero:GetSpellData(_R).level
	
	RefreshKillableTexts()
	--[[	Select best target	]]
	QRtarget = GetBestTarget(Qrange + 50)
	Etarget = GetBestTarget(Erange + Eradius)
	
	CheckStunnedTargets()
	
	if Menu.Debug.Enabled then
		if Menu.Debug.Predict and Etarget then
			UseE(Etarget)
		end
	end
	
	if Menu.E.StunC then
		minD = 0
		minE = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, Erange+Eradius) then
				if GetDistance(enemy) < minD or minE == nil then
					minD = GetDistance(enemy)
					minE = enemy
				end
			end
		end
		if minE ~= nil then
			UseE(minE)
		end
	end
	
	

	if Menu.E.UseE then
		if QRtarget ~= nil then
			UseE(QRtarget)
		elseif Etarget ~= nil then
			UseE(Etarget)
		end
	end

	if Comboing then 
		ExecuteCombo(Combotarget, CurrentCombo) 
	end
	
	if not Comboing and QRtarget then
		if Menu.Combo.Enabled2 then
					Combotarget = QRtarget
					CurrentCombo = { _E, _DFG, _IGNITE, _Q, _W, _R}
					ComboTick = GetTickCount()
					ExecuteCombo(Combotarget, CurrentCombo)
		end
			
		if Menu.Combo.Enabled then
			--[[	KS combos	]]
			local AvailableCombos = {}
			if not Menu.Targets["DontUseCombo"..(QRtarget.charName)] then
				--From more to less priority
				table.insert(AvailableCombos,{ _E, _DFG, _Q, _Q, _W})
				table.insert(AvailableCombos,{ _E, _IGNITE, _Q, _Q, _W})
				table.insert(AvailableCombos,{ _E, _DFG, _IGNITE, _Q, _Q, _W})
				table.insert(AvailableCombos,{ _E, _DFG, _IGNITE, _Q, _Q, _W, _R})
			end
			
			for id, Combo in ipairs(AvailableCombos) do
				local ComboDamage = ComboGetDamage(QRtarget, Combo)
				if (ComboDamage > QRtarget.health) then
					Combotarget = QRtarget
					CurrentCombo = Combo
					ComboTick = GetTickCount()
					if Menu.Debug.Enabled then
						PrintChat("Valid combo found, Target: "..Combotarget.charName..", Combo: "..ComboToText(CurrentCombo)..", Damage: "..ComboDamage)					
					end
					ExecuteCombo(Combotarget, CurrentCombo)
					break
				end			
			end
			--[[	Basic combo (if target is not killable)]]
			if not Comboing then
				if ready[_E] and Menu.Combo.UseE then
					UseSpell(QRtarget, _E)
				end
				if ready[_Q] then
					UseSpell(QRtarget, _Q)
				end
			end
		end
		if Menu.Harras.UseQ then
			if QRtarget then
				UseSpell(QRtarget, _Q)
			end
		end
		if Menu.Harras.UseW then
			if Etarget then
				local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(Etarget, Wdelay, Wradius, Wrange)
				if HitChance > 2 then
					ProdictionWCallback(Etarget, CastPosition, _W)
				end
			end
		end
	end
	
	--[[	Farm using Q	]]
	if Menu.Farm.Enabled then
		EnemyMinions:update()
		if (EnemyMinions.objects[1] ~= nil) and (EnemyMinions.objects[1].health < GetDamage(EnemyMinions.objects[1], _Q, false)) then
			if (myHero.mana > ComboManaCost({_Q, _E})) or not Menu.Farm.SaveE then
				UseSpell(EnemyMinions.objects[1], _Q)
			end
		end
	end

	if Menu.Farm.EnabledW then
		Max = 0
		EnemyMinions2:update()
		for i, minion in pairs(EnemyMinions2.objects) do
			if (GetDistance(minion) < Wrange) and (minion.charName:find("Wizard") or minion.charName:find("Caster")) then
				Count = GetNMinionsHit(minion, Wradius)
				if Count > Max then
					Max = Count
					MaxPos = Vector(minion.x, 0, minion.z)
				end
			end
		end
		
		if (Max > 2) and (myHero.mana > ComboManaCost({_W, _E})) or not Menu.Farm.SaveE  then
			CastSpell(_W, MaxPos.x, MaxPos.z)
		end
	end

	if Menu.Combo.Enabled and Menu.Combo.moveto and not _G.evade then
		Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
	elseif Menu.Combo.Enabled and Menu.Combo.Orbwalk then
		local Otarget = GetBestTarget(550)
		if Otarget then
		if os.clock() + GetLatency()/2000 > LastAttack + LastAnimationT and GetDistance(Otarget) < 550 and not _G.evade  then
			Packet('S_MOVE', {type = 3, targetNetworkId=Otarget.networkID}):send()
		elseif os.clock() + GetLatency()/2000 > LastAttack + LastWindUp + 0.05 and not _G.evade then
				Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
		end
		elseif not _G.evade then
			Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
		end
	end
end

function GetNMinionsHit(Pos, radius)
	local count = 0
	for i, minion in pairs(EnemyMinions2.objects) do
		if GetDistance(minion, Pos) < (radius + 50) then
			count = count + 1
		end
	end
	return count
end

function ComboToText(Combo)
	local Result = ""
	for i, spell in ipairs(Combo) do
		if spell == _Q then
			Result = Result.."Q->"
		elseif spell == _W then
			Result = Result.."W->"
		elseif spell == _E then
			Result = Result.."E->"
		elseif spell == _R then
			Result = Result.."R->"
		elseif spell == _IGNITE then
			Result = Result.."IGNITE->"
		elseif spell == _DFG then
			Result = Result.."DFG->"
		end
	end
	return Result
end

function ExecuteCombo(target, Combo)
	Comboing = true
	for i, Spell in ipairs(Combo) do
		if not ValidTarget(target, Qrange + 300) then 
			Comboing = false 
		end
		if Comboing then
			if ready[Spell] and ((Spell ~= _E) or Menu.Combo.UseE)  then
				UseSpell(target, Spell)
			end
		end
	end
	if GetTickCount() - ComboTick > 1500 then
		Comboing = false
	end
end

--[[Interrupt spells using E ]]
function OnProcessSpell(unit, spell)
	if Menu.E.interrupt and ready[_E] then
		if Menu.E.List[spell.name] and unit.team ~= myHero.team then
			if (Eradius + Erange) >= GetDistance(unit) then
				ProdictionECallback(Vector(unit.x, 0, unit.z), Vector(unit.x, 0, unit.z), _E)
				PrintChat("<font color=\"#FF0000\">Trying to interrupt: " .. spell.name.."</font>")
			end
		end
	end
	
	if unit.isMe then
		if spell.name:lower():find("attack") then
			LastWindUp = spell.windUpTime
			LastAnimationT = spell.animationTime
			LastAttack = os.clock() - GetLatency()/2000
		end
	end
end


--[[Functions related with drawing]]

--[[Update the bar texts]]
function RefreshKillableTexts()
	if ((GetTickCount() - lastrefresh) > 100) and (Menu.Drawing.killable or Menu.Drawing.health) then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				DamageToHeros[i] =  ComboGetDamage(enemy, {_Q, _W, _E, _R, _DFG, _IGNITE}) 
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
	DrawText("|", 13, Position, SPos.y+10, ARGB(255,0,255,0))
end

function DrawOnHPBar(unit, health)
	local Pos = GetHPBarPos(unit)
	if health < 0 then
		DrawCircle2(unit.x, unit.y, unit.z, 100, ARGB(255, 255, 0, 0))	
		DrawText("HP: "..health,13, Pos.x, Pos.y+5, ARGB(255,255,0,0))
	else
		DrawText("HP: "..health,13, Pos.x, Pos.y+5, ARGB(255,0,255,0))
	end
end

function DrawNoMana()
	local myPos = GetHPBarPos(myHero)
	timetoregen = (ComboManaCost({_Q, _W, _E, _R}) - myHero.mana) / myHero.mpRegen
	DrawText("No Mana ("..math.floor(timetoregen).."s) !!", 13, myPos.x, myPos.y, ARGB(255,0,225,255))
end

--[[Credits to barasia, vadash and viseversa for anti-lag circles]]
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
	if not Menu.Drawing.lagfree then
		return DrawCircle(x, y, z, radius, color)
	end
	if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
		DrawCircleNextLvl(x, y, z, radius, 1, color, 75)	
	end
end

function OnDraw()
	--[[	Ranges	]]
	if Menu.Drawing.Erange then
		DrawCircle2(myHero.x,myHero.y,myHero.z,Erange+Eradius,ARGB(255, 0, 255, 0))
	end
	
	if Menu.Drawing.Qrange then
		DrawCircle2(myHero.x,myHero.y,myHero.z,Qrange,ARGB(255, 0, 255, 0))
	end
	
	--[[HealthBar HP tracker]]
	if Menu.Drawing.health then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				if DamageToHeros[i] ~= nil then
					RemainingHealth = enemy.health - DamageToHeros[i]
				end
				if RemainingHealth ~= nil then
					DrawIndicator(enemy, math.floor(RemainingHealth))
				end
			end
		end
	end
	
	--[[Killable text tracker]]
	if Menu.Drawing.killable then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) then
				if DamageToHeros[i] ~= nil then
					RemainingHealth = enemy.health - DamageToHeros[i]
				end
				if RemainingHealth ~= nil then
					DrawOnHPBar(enemy, math.floor(RemainingHealth))
				end
			end
		end
	end

	--[[Draw Circle arround killable minion]]
	if Menu.Drawing.minions then
		if (EnemyMinions.objects[1] ~= nil)  and (EnemyMinions.objects[1].health < GetDamage(EnemyMinions.objects[1], _Q, false))  then
			DrawCircle2(EnemyMinions.objects[1].x, EnemyMinions.objects[1].y, EnemyMinions.objects[1].z, 100, ARGB(255, 0, 255, 0))	
		end
	end

	--[[Draw low mana text]]
	if Menu.Drawing.Mana then
		if myHero.mana < ComboManaCost({_Q, _W, _E, _R}) then
			DrawNoMana()
		end
	end
	
	if Menu.Drawing.Priority then
		for i=1, heroManager.iCount do
			local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) and focusedtarget ~= nil and (enemy.charName == focusedtarget.charName)  then
				DrawCircle2(enemy.x,enemy.y,enemy.z,100,ARGB(255, 0, 255, 0))
			end
		end
	end
	
	--[[Debug]]
	if Menu.Debug.Enabled then
		if PredictedTargetPos ~= nil then
			DrawCircle2(PredictedTargetPos.x, PredictedTargetPos.y, PredictedTargetPos.z, 90, ARGB(255, 0, 255, 0))
		end
		if  SecondaryPos ~= nil then
		DrawCircle2(SecondaryPos.x, SecondaryPos.y, SecondaryPos.z, 90, ARGB(255, 0, 255, 0))
		end
		if Solution1 ~= nil then
		DrawCircle2(Solution1.x, Solution1.y, Solution1.z, 90, ARGB(255, 0, 0, 255))
		end
		if Solution2 ~= nil then
		DrawCircle2(Solution2.x, Solution2.y, Solution2.z, 90, ARGB(255, 0, 0, 255))
		end
		if ECastPosition ~= nil then
			DrawCircle2(ECastPosition.x, ECastPosition.y, ECastPosition.z, Eradius, ARGB(255, 255, 0, 0))
		end
		if Menu.Debug.DrawT then
			local Sep, FontSize, X, Y, BlockSep = 17, 13, 100, 10, 20
			Block = {"Spells", "Q ready: "..(ready[_Q] and "yes" or "no"), "W ready: "..(ready[_W] and "yes" or "no"), "E ready: "..(ready[_E] and "yes" or "no"), "R ready: "..(ready[_R] and "yes" or "no"), 
				 "DFG ready: "..(ready[_DFG] and "yes" or "no"), "IGNITE ready: "..(ready[_IGNITE] and "yes" or "no"), "DFG slot: ".._DFG }
			for i, Text in ipairs(Block) do
				DrawText(Text,(i==1 and FontSize + 2 or FontSize) , X, Y + (i - 1) * Sep, ARGB(255,255,255,255))
			end
		
			local Sep, FontSize, X, Y, BlockSep = 17, 13, 100, 10 + 400, 20
			local target = GetBestTarget(Qrange + 50)
			if target ~= nil then
				Block = {"Target", "QTarget: "..target.charName, "Health: "..target.health, "Max. Damage: "..ComboGetDamage(target, {_Q, _W, _E, _R, _DFG, _IGNITE})}
				for i, Text in ipairs(Block) do
					DrawText(Text,(i==1 and FontSize + 2 or FontSize) , X, Y + (i - 1) * Sep, ARGB(255,255,255,255))
				end
			end	
		end
	end
end
--EOS--


