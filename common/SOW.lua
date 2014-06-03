local version = "1.130"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/Hellsing/BoL/master/common/SOW.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH.."SOW.lua"
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>SOW:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/Hellsing/BoL/master/version/SOW.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				_AutoupdaterMsg("New version available"..ServerVersion)
				_AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				_AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		_AutoupdaterMsg("Error downloading version info")
	end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


class "SOW"
function SOW:__init(VP)
	_G.SOWLoaded = true

	self.ProjectileSpeed = myHero.range > 300 and VP:GetProjectileSpeed(myHero) or math.huge
	self.BaseWindupTime = 3
	self.BaseAnimationTime = 0.65
	self.DataUpdated = false

	self.VP = VP
	
	--Callbacks
	self.AfterAttackCallbacks = {}
	self.OnAttackCallbacks = {}
	self.BeforeAttackCallbacks = {}

	self.AttackTable =
		{
			["Ashes Q"] = "frostarrow",
		}

	self.NoAttackTable =
		{
			["Shyvana1"] = "shyvanadoubleattackdragon",
			["Shyvana2"] = "ShyvanaDoubleAttack",
			["Wukong"] = "MonkeyKingDoubleAttack",
		}

	self.AttackResetTable = 
		{
			["vayne"] = _Q,
			["darius"] = _W,
			["fiora"] = _E,
			["gangplank"] = _Q,
			["jax"] = _W,
			["leona"] = _Q,
			["mordekaiser"] = _Q,
			["nasus"] = _Q,
			["nautilus"] = _W,
			["nidalee"] = _Q,
			["poppy"] = _Q,
			["renekton"] = _W,
			["rengar"] = _Q,
			["shyvana"] = _Q,
			["sivir"] = _W,
			["talon"] = _Q,
			["trundle"] = _Q,
			["vi"] = _E,
			["volibear"] = _Q,
			["xinzhao"] = _Q,
			["monkeyking"] = _Q,
			["yorick"] = _Q,
			["cassiopeia"] = _E,
			["garen"] = _Q,
			["khazix"] = _Q,
		}

	self.LastAttack = 0
	self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_MAXHEALTH_ASC)
	self.JungleMinions = minionManager(MINION_JUNGLE, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.OtherMinions = minionManager(MINION_OTHER, 2000, myHero, MINION_SORT_HEALTH_ASC)
	
	GetSave("SOW").FarmDelay = GetSave("SOW").FarmDelay and GetSave("SOW").FarmDelay or 0
	GetSave("SOW").ExtraWindUpTime = GetSave("SOW").ExtraWindUpTime and GetSave("SOW").ExtraWindUpTime or 50
	GetSave("SOW").Mode3 = GetSave("SOW").Mode3 and GetSave("SOW").Mode3 or string.byte("X")
	GetSave("SOW").Mode2 = GetSave("SOW").Mode2 and GetSave("SOW").Mode2 or string.byte("V")
	GetSave("SOW").Mode1 = GetSave("SOW").Mode1 and GetSave("SOW").Mode1 or string.byte("C")
	GetSave("SOW").Mode0 = GetSave("SOW").Mode0 and GetSave("SOW").Mode0 or 32

	self.Attacks = true
	self.Move = true
	self.mode = -1
	self.checkcancel = 0

	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
end

function SOW:LoadToMenu(m, STS)
	if not m then
		self.Menu = scriptConfig("Simple OrbWalker", "SOW")
	else
		self.Menu = m
	end

	if STS then
		self.STS = STS
		self.STS.VP = self.VP
	end
	
	self.Menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
	self.Menu:addParam("FarmDelay", "Farm Delay", SCRIPT_PARAM_SLICE, -150, 0, 150)
	self.Menu:addParam("ExtraWindUpTime", "Extra WindUp Time", SCRIPT_PARAM_SLICE, -150,  0, 150)
	
	self.Menu.FarmDelay = GetSave("SOW").FarmDelay
	self.Menu.ExtraWindUpTime = GetSave("SOW").ExtraWindUpTime

	self.Menu:addParam("Attack",  "Attack", SCRIPT_PARAM_LIST, 2, { "Only Farming", "Farming + Carry mode"})
	self.Menu:addParam("Mode",  "Orbwalking mode", SCRIPT_PARAM_LIST, 1, { "To mouse", "To target"})

	self.Menu:addParam("Hotkeys", "", SCRIPT_PARAM_INFO, "")

	self.Menu:addParam("Mode3", "Last hit!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	self.Mode3ParamID = #self.Menu._param
	self.Menu:addParam("Mode1", "Mixed Mode!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	self.Mode1ParamID = #self.Menu._param
	self.Menu:addParam("Mode2", "Laneclear!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	self.Mode2ParamID = #self.Menu._param
	self.Menu:addParam("Mode0", "Carry me!", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	self.Mode0ParamID = #self.Menu._param

	self.Menu._param[self.Mode3ParamID].key = GetSave("SOW").Mode3
	self.Menu._param[self.Mode2ParamID].key = GetSave("SOW").Mode2
	self.Menu._param[self.Mode1ParamID].key = GetSave("SOW").Mode1
	self.Menu._param[self.Mode0ParamID].key = GetSave("SOW").Mode0
	
	AddTickCallback(function() self:OnTick() end)
	AddTickCallback(function() self:CheckConfig() end)
end

function SOW:CheckConfig()
	GetSave("SOW").FarmDelay = self.Menu.FarmDelay
	GetSave("SOW").ExtraWindUpTime = self.Menu.ExtraWindUpTime

	GetSave("SOW").Mode3 = self.Menu._param[self.Mode3ParamID].key
	GetSave("SOW").Mode2 = self.Menu._param[self.Mode2ParamID].key
	GetSave("SOW").Mode1 = self.Menu._param[self.Mode1ParamID].key
	GetSave("SOW").Mode0 = self.Menu._param[self.Mode0ParamID].key
end

function SOW:DisableAttacks()
	self.Attacks = false
end

function SOW:EnableAttacks()
	self.Attacks = true
end

function SOW:ForceTarget(target)
	self.forcetarget = target
end

function SOW:GetTime()
	return os.clock()
end

function SOW:MyRange(target)
	local myRange = myHero.range + self.VP:GetHitBox(myHero)
	if target and ValidTarget(target) then
		myRange = myRange + self.VP:GetHitBox(target)
	end
	return myRange - 20
end

function SOW:InRange(target)
	local MyRange = self:MyRange(target)
	if target and GetDistanceSqr(target.visionPos, myHero.visionPos) <= MyRange * MyRange then
		return true
	end
end

function SOW:ValidTarget(target)
	if target and target.type and (target.type == "obj_BarracksDampener" or target.type == "obj_HQ")  then
		return false
	end
	return ValidTarget(target) and self:InRange(target)
end

function SOW:Attack(target)
	self.LastAttack = self:GetTime() + self:Latency()
	myHero:Attack(target)
end

function SOW:WindUpTime(exact)
	return (1 / (myHero.attackSpeed * self.BaseWindupTime)) + (exact and 0 or GetSave("SOW").ExtraWindUpTime / 1000)
end

function SOW:AnimationTime()
	return (1 / (myHero.attackSpeed * self.BaseAnimationTime))
end

function SOW:Latency()
	return GetLatency() / 2000
end

function SOW:CanAttack()
	if self.LastAttack <= self:GetTime() then
		return (self:GetTime() + self:Latency()  > self.LastAttack + self:AnimationTime())
	end
	return false
end

function SOW:CanMove()
	if self.LastAttack <= self:GetTime() then
		return ((self:GetTime() + self:Latency() > self.LastAttack + self:WindUpTime()) or self.ParticleCreated) and not _G.evade
	end
end

function SOW:BeforeAttack(target)
	local result = false
	for i, cb in ipairs(self.BeforeAttackCallbacks) do
		local ri = cb(target, self.mode)
		if ri then
			result = true
		end
	end
	return result
end

function SOW:RegisterBeforeAttackCallback(f)
	table.insert(self.BeforeAttackCallbacks, f)
end

function SOW:OnAttack(target)
	for i, cb in ipairs(self.OnAttackCallbacks) do
		cb(target, self.mode)
	end
end

function SOW:RegisterOnAttackCallback(f)
	table.insert(self.OnAttackCallbacks, f)
end

function SOW:AfterAttack(target)
	for i, cb in ipairs(self.AfterAttackCallbacks) do
		cb(target, self.mode)
	end
end

function SOW:RegisterAfterAttackCallback(f)
	table.insert(self.AfterAttackCallbacks, f)
end

function SOW:MoveTo(x, y)
	myHero:MoveTo(x, y)
end
function SOW:OrbWalk(target, point)
	point = point or self.forceorbwalkpos
	if self.Attacks and self:CanAttack() and self:ValidTarget(target) and not self:BeforeAttack(target) then
		self:Attack(target)
	elseif self:CanMove() and self.Move then
		if not point then
			local OBTarget = GetTarget() or target
			if self.Menu.Mode == 1 or not OBTarget then
				local Mv = Vector(myHero) + 400 * (Vector(mousePos) - Vector(myHero)):normalized()
				self:MoveTo(Mv.x, Mv.z)
			elseif GetDistanceSqr(OBTarget) > 100*100 + math.pow(self.VP:GetHitBox(OBTarget), 2) then
				local point = self.VP:GetPredictedPos(OBTarget, 0, 2*myHero.ms, myHero, false)
				if GetDistanceSqr(point) < 100*100 + math.pow(self.VP:GetHitBox(OBTarget), 2) then
					point = Vector(Vector(myHero) - point):normalized() * 50
				end
				self:MoveTo(point.x, point.z)
			end
		else
			self:MoveTo(point.x, point.z)
		end
	end
end

function SOW:IsAttack(SpellName)
	return (SpellName:lower():find("attack") or table.contains(self.AttackTable, SpellName:lower())) and not table.contains(self.NoAttackTable, SpellName:lower())
end

function SOW:IsAAReset(SpellName)
	local SpellID
	if SpellName:lower() == myHero:GetSpellData(_Q).name:lower() then
		SpellID = _Q
	elseif SpellName:lower() == myHero:GetSpellData(_W).name:lower() then
		SpellID = _W
	elseif SpellName:lower() == myHero:GetSpellData(_E).name:lower() then
		SpellID = _E
	elseif SpellName:lower() == myHero:GetSpellData(_R).name:lower() then
		SpellID = _R
	end

	if SpellID then
		return self.AttackResetTable[myHero.charName:lower()] == SpellID 
	end
	return false
end

function SOW:OnProcessSpell(unit, spell)
	if unit.isMe and self:IsAttack(spell.name) then
		if self.debugdps then
			DPS = DPS and DPS or 0
			print("DPS: "..(1000/(self:GetTime()- DPS)).." "..(1000/(self:AnimationTime())))
			DPS = self:GetTime()
		end
		if not self.DataUpdated and not spell.name:lower():find("card") then
			self.BaseAnimationTime = 1 / (spell.animationTime * myHero.attackSpeed)
			self.BaseWindupTime = 1 / (spell.windUpTime * myHero.attackSpeed)
			if self.debug then
				print("<font color=\"#FF0000\">Basic Attacks data updated: </font>")
				print("<font color=\"#FF0000\">BaseWindupTime: "..self.BaseWindupTime.."</font>")
				print("<font color=\"#FF0000\">BaseAnimationTime: "..self.BaseAnimationTime.."</font>")
				print("<font color=\"#FF0000\">ProjectileSpeed: "..self.ProjectileSpeed.."</font>")
			end
			self.DataUpdated = true
		end
		self.LastAttack = self:GetTime() - self:Latency()
		self.checking = true
		self.LastAttackCancelled = false
		self:OnAttack(spell.target)
		self.checkcancel = self:GetTime()
		DelayAction(function(t) self:AfterAttack(t) end, self:WindUpTime() - self:Latency(), {spell.target})

	elseif unit.isMe and self:IsAAReset(spell.name) then
		DelayAction(function() self:resetAA() end, 0.25)
	end
end

function SOW:resetAA()
	self.LastAttack = 0
end
--TODO: Change this.
function SOW:BonusDamage(minion)
	local AD = myHero:CalcDamage(minion, myHero.totalDamage)
	local BONUS = 0
	if myHero.charName == 'Vayne' then
		if myHero:GetSpellData(_Q).level > 0 and myHero:CanUseSpell(_Q) == SUPRESSED then
			BONUS = BONUS + myHero:CalcDamage(minion, ((0.05 * myHero:GetSpellData(_Q).level) + 0.25 ) * myHero.totalDamage)
		end
		if not VayneCBAdded then
			VayneCBAdded = true
			function VayneParticle(obj)
				if GetDistance(obj) < 1000 and obj.name:lower():find("vayne_w_ring2.troy") then
					VayneWParticle = obj
				end
			end
			AddCreateObjCallback(VayneParticle)
		end
		if VayneWParticle and VayneWParticle.valid and GetDistance(VayneWParticle, minion) < 10 then
			BONUS = BONUS + 10 + 10 * myHero:GetSpellData(_W).level + (0.03 + (0.01 * myHero:GetSpellData(_W).level)) * minion.maxHealth
		end
	elseif myHero.charName == 'Teemo' and myHero:GetSpellData(_E).level > 0 then
		BONUS = BONUS + myHero:CalcMagicDamage(minion, (myHero:GetSpellData(_E).level * 10) + (myHero.ap * 0.3) )
	elseif myHero.charName == 'Corki' then
		BONUS = BONUS + myHero.totalDamage/10
	elseif myHero.charName == 'MissFortune' and myHero:GetSpellData(_W).level > 0 then
		BONUS = BONUS + myHero:CalcMagicDamage(minion, (4 + 2 * myHero:GetSpellData(_W).level) + (myHero.ap/20))
	elseif myHero.charName == 'Varus' and myHero:GetSpellData(_W).level > 0 then
		BONUS = BONUS + (6 + (myHero:GetSpellData(_W).level * 4) + (myHero.ap * 0.25))
	elseif myHero.charName == 'Caitlyn' then
			if not CallbackCaitlynAdded then
				function CaitlynParticle(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("caitlyn_headshot_rdy") then
							HeadShotParticle = obj
					end
				end
				AddCreateObjCallback(CaitlynParticle)
				CallbackCaitlynAdded = true
			end
			if HeadShotParticle and HeadShotParticle.valid then
				BONUS = BONUS + AD * 1.5
			end
	elseif myHero.charName == 'Orianna' then
		BONUS = BONUS + myHero:CalcMagicDamage(minion, 10 + 8 * ((myHero.level - 1) % 3))
	elseif myHero.charName == 'TwistedFate' then
			if not TFCallbackAdded then
				function TFParticle(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("cardmaster_stackready.troy") then
						TFEParticle = obj
					elseif GetDistance(obj) < 100 and obj.name:lower():find("card_blue.troy") then
						TFWParticle = obj
					end
				end
				AddCreateObjCallback(TFParticle)
				TFCallbackAdded = true
			end
			if TFEParticle and TFEParticle.valid then
				BONUS = BONUS + myHero:CalcMagicDamage(minion, myHero:GetSpellData(_E).level * 15 + 40 + 0.5 * myHero.ap)  
			end
			if TFWParticle and TFWParticle.valid then
				BONUS = BONUS + math.max(myHero:CalcMagicDamage(minion, myHero:GetSpellData(_W).level * 20 + 20 + 0.5 * myHero.ap) - 40, 0) 
			end
	elseif myHero.charName == 'Draven' then
			if not CallbackDravenAdded then
				function DravenParticle(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("draven_q_buf") then
							DravenParticleo = obj
					end
				end
				AddCreateObjCallback(DravenParticle)
				CallbackDravenAdded = true
			end
			if DravenParticleo and DravenParticleo.valid then
				BONUS = BONUS + AD * (0.3 + (0.10 * myHero:GetSpellData(_Q).level))
			end
	elseif myHero.charName == 'Nasus' and VIP_USER then
		if myHero:GetSpellData(_Q).level > 0 and myHero:CanUseSpell(_Q) == SUPRESSED then
			local Qdamage = {30, 50, 70, 90, 110}
			NasusQStacks = NasusQStacks or 0
			BONUS = BONUS + myHero:CalcDamage(minion, 10 + 20 * (myHero:GetSpellData(_Q).level) + NasusQStacks)
			if not RecvPacketNasusAdded then
				function NasusOnRecvPacket(p)
					if p.header == 0xFE and p.size == 0xC then
						p.pos = 1
						pNetworkID = p:DecodeF()
						unk01 = p:Decode2()
				 		unk02 = p:Decode1()
						stack = p:Decode4()
						if pNetworkID == myHero.networkID then
							NasusQStacks = stack
						end
					end
				end
				RecvPacketNasusAdded = true
				AddRecvPacketCallback(NasusOnRecvPacket)
			end
		end
	elseif myHero.charName == "Ziggs" then
		if not CallbackZiggsAdded then
			function ZiggsParticle(obj)
				if GetDistance(obj) < 100 and obj.name:lower():find("ziggspassive") then
						ZiggsParticleObj = obj
				end
			end
			AddCreateObjCallback(ZiggsParticle)
			CallbackZiggsAdded = true
		end
		if ZiggsParticleObj and ZiggsParticleObj.valid then
			local base = {20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 80, 88, 100, 112, 124, 136, 148, 160}
			BONUS = BONUS + myHero:CalcMagicDamage(minion, base[myHero.level] + (0.25 + 0.05 * (myHero.level % 7)) * myHero.ap)  
		end
	end

	return BONUS
end

function SOW:KillableMinion()
	local result
	for i, minion in ipairs(self.EnemyMinions.objects) do
		local time = self:WindUpTime(true) + GetDistance(minion.visionPos, myHero.visionPos) / self.ProjectileSpeed - 0.07
		local PredictedHealth = self.VP:GetPredictedHealth(minion, time, GetSave("SOW").FarmDelay / 1000)
		if self:ValidTarget(minion) and PredictedHealth < self.VP:CalcDamageOfAttack(myHero, minion, {name = "Basic"}, 0) + self:BonusDamage(minion) and PredictedHealth > -40 then
			result = minion
			break
		end
	end
	return result
end

function SOW:ShouldWait()
	for i, minion in ipairs(self.EnemyMinions.objects) do
		local time = self:AnimationTime() + GetDistance(minion.visionPos, myHero.visionPos) / self.ProjectileSpeed - 0.07
		if self:ValidTarget(minion) and self.VP:GetPredictedHealth2(minion, time * 2) < (self.VP:CalcDamageOfAttack(myHero, minion, {name = "Basic"}, 0) + self:BonusDamage(minion)) then
			return true
		end
	end
end

function SOW:ValidStuff()
	local result = self:GetTarget()

	if result then 
		return result
	end

	for i, minion in ipairs(self.EnemyMinions.objects) do
		local time = self:AnimationTime() + GetDistance(minion.visionPos, myHero.visionPos) / self.ProjectileSpeed - 0.07
		local pdamage2 = minion.health - self.VP:GetPredictedHealth(minion, time, GetSave("SOW").FarmDelay / 1000)
		local pdamage = self.VP:GetPredictedHealth2(minion, time * 2)
		if self:ValidTarget(minion) and ((pdamage) > 2*self.VP:CalcDamageOfAttack(myHero, minion, {name = "Basic"}, 0) + self:BonusDamage(minion) or pdamage2 == 0) then
			return minion
		end
	end

	for i, minion in ipairs(self.JungleMinions.objects) do
		if self:ValidTarget(minion) then
			return minion
		end
	end

	for i, minion in ipairs(self.OtherMinions.objects) do
		if self:ValidTarget(minion) then
			return minion
		end
	end
end

function SOW:GetTarget(OnlyChampions)
	local result
	local healthRatio

	if self:ValidTarget(self.forcetarget) then
		return self.forcetarget
	elseif self.forcetarget ~= nil then
		return nil
	end

	if (not self.STS or not OnlyChampions) and self:ValidTarget(GetTarget()) and (GetTarget().type == myHero.type or (not OnlyChampions)) then
		return GetTarget()
	end

	if self.STS then
		local oldhitboxmode = self.STS.hitboxmode
		self.STS.hitboxmode = true

		result = self.STS:GetTarget(myHero.range)

		self.STS.hitboxmode = oldhitboxmode
		return result
	end

	for i, champion in ipairs(GetEnemyHeroes()) do
		local hr = champion.health / myHero:CalcDamage(champion, 200)
		if self:ValidTarget(champion) and ((healthRatio == nil) or hr < healthRatio) then
			result = champion
			healthRatio = hr
		end
	end

	return result
end

function SOW:Farm(mode, point)
	if mode == 1 then
		self.EnemyMinions:update()
		local target = self:KillableMinion() or self:GetTarget()
		self:OrbWalk(target, point)
		self.mode = 1
	elseif mode == 2 then
		self.EnemyMinions:update()
		self.OtherMinions:update()
		self.JungleMinions:update()

		local target = self:KillableMinion()
		if target then
			self:OrbWalk(target, point)
		elseif not self:ShouldWait() then

			if self:ValidTarget(self.lasttarget) then
				target = self.lasttarget
			else
				target = self:ValidStuff()
			end
			self.lasttarget = target
			
			self:OrbWalk(target, point)
		else
			self:OrbWalk(nil, point)
		end
		self.mode = 2
	elseif mode == 3 then
		self.EnemyMinions:update()
		local target = self:KillableMinion()
		self:OrbWalk(target, point)
		self.mode = 3
	end
end

function SOW:OnTick()
	if not self.Menu.Enabled then return end
	if self.Menu.Mode0 then
		local target = self:GetTarget(true)
		if self.Menu.Attack == 2 then
			self:OrbWalk(target)
		else
			self:OrbWalk()
		end
		self.mode = 0
	elseif self.Menu.Mode1 then
		self:Farm(1)
	elseif self.Menu.Mode2 then
		self:Farm(2)
	elseif self.Menu.Mode3 then
		self:Farm(3)
	else
		self.mode = -1
	end
end

function SOW:DrawAARange(width, color)
	local p = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
	if OnScreen(p.x, p.y) then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, self:MyRange() + 25, width or 1, color or ARGB(255, 255, 0, 0))
	end
end
