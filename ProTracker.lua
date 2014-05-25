local version = 1.30
local AUTOUPDATE = true
local SCRIPT_NAME = "ProTracker"

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

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local TrackSpells = {_Q, _W, _E, _R, SUMMONER_1, SUMMONER_2}
local SpellsData = {}
local TickLimit = 0
local FirstTick = false


local SSpells = {		{CName="Flash", Name="SummonerFlash", Color={255, 255, 255, 0} },
						{CName="Ghost", Name="SummonerHaste", Color={255, 0, 0, 255} },
						{CName="Ignite", Name="SummonerDot", Color={255, 255, 0, 0 }},
						{CName="Barrier", Name="SummonerBarrier", Color={255, 209, 143, 0}},
						{CName="Smite", Name="SummonerSmite", Color={255, 209, 143, 0}},
						{CName="Exhaust", Name="SummonerExhaust", Color={255, 209, 143, 0}},
						{CName="Heal", Name="SummonerHeal", Color={255, 0, 255, 0}},
						{CName="Teleport", Name="SummonerTeleport", Color={255, 192, 0, 209}},
						{CName="Cleanse", Name="SummonerBoost", Color={255, 255, 138, 181}},
						{CName="Clarity", Name="SummonerMana", Color={255, 0, 110, 255}},
						{CName="Clairvoyance", Name="SummonerClairvoyance", Color={255, 0, 110, 255}},
						{CName="Revive", Name="SummonerRevive", Color={255, 0, 255, 0}},
						{CName="Garrison", Name="SummonerOdinGarrison", Color={255, 0, 110, 255}},
						{CName="The Rest", Name="TheRest", Color={255, 255, 255, 255}},
						}
						
function OnLoad()
	Menu = scriptConfig("ProTracker", "ProTrackerv2")
	Menu:addParam("Enabled", "Draw indicators in enemies", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("M"))
	Menu:addParam("Enabled2", "Draw indicators in allies", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("N"))
	
	Menu:addSubMenu("Drawing", "Drawing")
	Menu.Drawing:addParam("Always", "Always draw the indicators",  SCRIPT_PARAM_ONOFF, true)
	Menu.Drawing:addParam("DrawKey", "Only draw while holding", SCRIPT_PARAM_ONKEYDOWN, false, 16)
	
	--[[Appearance submenu]]
	Menu:addSubMenu("Appearance ", "Appearance")
	Menu.Appearance:addParam("showh", "Show horizontal indicators", SCRIPT_PARAM_ONOFF, true)
	Menu.Appearance:addParam("vposition", "Horizontal indicators vertical position", SCRIPT_PARAM_SLICE, 0, -25, 25)
	Menu.Appearance:addParam("width", "Horizontal indicators width", SCRIPT_PARAM_SLICE, 20, 1, 25)
	Menu.Appearance:addParam("height", "Horizontal indicators height", SCRIPT_PARAM_SLICE, 5, 1, 20)
	Menu.Appearance:addParam("n", "Number of horizontal indicators", SCRIPT_PARAM_SLICE, 4, 1, 6)
	Menu.Appearance:addParam("showv", "Show vertical indicators", SCRIPT_PARAM_ONOFF, true)
	Menu.Appearance:addParam("width2", "Vertical indicators width", SCRIPT_PARAM_SLICE, 9, 1, 25)
	Menu.Appearance:addParam("textsize", "Text size", SCRIPT_PARAM_SLICE, 13, 10, 20)
	
	--[[Submenu to select the colors]]
	Menu:addSubMenu("Colors", "Colors")
	Menu.Colors:addParam("cdcolor", "Cooldown color", SCRIPT_PARAM_COLOR, {255, 214, 114, 0})--orange
	Menu.Colors:addParam("readycolor", "Ready color", SCRIPT_PARAM_COLOR, {255, 54, 214, 0})--green
	Menu.Colors:addParam("textcolor", "Text color", SCRIPT_PARAM_COLOR, {255, 255, 255, 255})--white
	Menu.Colors:addParam("backgroundcolor", "Background color", SCRIPT_PARAM_COLOR, {255, 128, 128, 128})--grey
	
	Menu.Colors:addSubMenu("Summoner Spells", "SSpells")
	for i, spell in ipairs(SSpells) do
		Menu.Colors.SSpells:addParam(spell.Name, spell.CName, SCRIPT_PARAM_COLOR, spell.Color)
	end

end

--[[Returns the healthbar position]]
function GetHPBarPos(enemy)
	enemy.barData = {PercentageOffset = {x = -0.05, y = 0}}--GetEnemyBarData()
	local barPos = GetUnitHPBarPos(enemy)
	local barPosOffset = GetUnitHPBarOffset(enemy)
	local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local BarPosOffsetX = 171
	local BarPosOffsetY = 46
	local CorrectionY = 39
	local StartHpPos = 31
	
	barPos.x = math.floor(barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos)
	barPos.y = math.floor(barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY)
						
	local StartPos = Vector(barPos.x , barPos.y, 0)
	local EndPos =  Vector(barPos.x + 108 , barPos.y , 0)
	return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end

function OnTick()
	if os.clock() - TickLimit > 0.3 then
		TickLimit = os.clock()
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ValidTarget(hero, math.huge, false) or ValidTarget(hero) then
				--[[	Update the current cooldowns]]
				hero = heroManager:getHero(i)
				for _, spell in pairs(TrackSpells) do
					if SpellsData[i] == nil then
						SpellsData[i] = {}
					end
					if SpellsData[i][spell] == nil then
						SpellsData[i][spell] = {currentCd=0, maxCd = 0, level=0}
					end
					--[[	Get the maximum cooldowns to make the progress  bar]]
					local thespell = hero:GetSpellData(spell)
					local currentcd
					if thespell and thespell.currentCd then
						currentcd = thespell.currentCd
					end
					if currentcd and thespell and thespell.currentCd then
						SpellsData[i][spell] = {
							currentCd = math.floor(currentcd),
							maxCd = math.floor(currentcd) > SpellsData[i][spell].maxCd and math.floor(currentcd) or SpellsData[i][spell].maxCd,
							level = thespell.level
						}
					end
				end
			end
		end
	end
	FirstTick = true
end

function DrawRectangleAL(x, y, w, h, color)
	local Points = {}
	Points[1] = D3DXVECTOR2(math.floor(x), math.floor(y))
	Points[2] = D3DXVECTOR2(math.floor(x + w), math.floor(y))
	DrawLines2(Points, math.floor(h), color)
end

function OnDraw()
	if (Menu.Enabled or Menu.Enabled2 or IsKeyDown(16)) and FirstTick and (Menu.Drawing.Always or Menu.Drawing.DrawKey) then
		for i=1, heroManager.iCount, 1 do
			local hero = heroManager:getHero(i)
			if ((ValidTarget(hero, math.huge,false)  and (Menu.Enabled2 or IsKeyDown(16))) or (ValidTarget(hero) and (Menu.Enabled or IsKeyDown(16)))) and not hero.isMe then
				local barpos = GetHPBarPos(hero)
				if OnScreen(barpos.x, barpos.y) and (SpellsData[i] ~= nil) then
					local pos = Vector(barpos.x, barpos.y, 0)
					local CDcolor = ARGB(Menu.Colors.cdcolor[1], Menu.Colors.cdcolor[2],Menu.Colors.cdcolor[3],Menu.Colors.cdcolor[4])
					local Readycolor = ARGB(Menu.Colors.readycolor[1],Menu.Colors.readycolor[2],Menu.Colors.readycolor[3],Menu.Colors.readycolor[4])
					local Textcolor = ARGB(Menu.Colors.textcolor[1],Menu.Colors.textcolor[2],Menu.Colors.textcolor[3],Menu.Colors.textcolor[4] )
					local Backgroundcolor = ARGB(Menu.Colors.backgroundcolor[1],Menu.Colors.backgroundcolor[2],Menu.Colors.backgroundcolor[3],Menu.Colors.backgroundcolor[4])
					local width = Menu.Appearance.width
					local height = Menu.Appearance.height
					local sep = 2
					--[[First 4 spells]]
					if Menu.Appearance.showh then
						pos.y =  pos.y + Menu.Appearance.vposition
						for j, Spells in ipairs (TrackSpells) do
							local currentcd = SpellsData[i][Spells].currentCd
							local maxcd = SpellsData[i][Spells].maxCd
							local level = SpellsData[i][Spells].level
							
							if j > 4 then
								CDcolor = ARGB(Menu.Colors.SSpells["TheRest"][1], Menu.Colors.SSpells["TheRest"][2], Menu.Colors.SSpells["TheRest"][3], Menu.Colors.SSpells["TheRest"][4])
								for _, spell in ipairs(SSpells) do
									if (Menu.Colors.SSpells[spell.Name] ~= nil) and (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
										CDcolor = ARGB(Menu.Colors.SSpells[spell.Name][1], Menu.Colors.SSpells[spell.Name][2], Menu.Colors.SSpells[spell.Name][3], Menu.Colors.SSpells[spell.Name][4])
									end
								end
								Readycolor = CDcolor
							else
								CDcolor = ARGB(Menu.Colors.cdcolor[1], Menu.Colors.cdcolor[2],Menu.Colors.cdcolor[3],Menu.Colors.cdcolor[4])
								Readycolor = ARGB(Menu.Colors.readycolor[1],Menu.Colors.readycolor[2],Menu.Colors.readycolor[3],Menu.Colors.readycolor[4])
							end
						
							DrawRectangleAL(pos.x-1, pos.y-1, width + sep , height+4, Backgroundcolor)
						
							if (currentcd ~= 0) then
								DrawRectangleAL(pos.x, pos.y, width - math.floor(width * currentcd) / maxcd, height, CDcolor)
							else
								DrawRectangleAL(pos.x, pos.y, width, height, Readycolor)
							end
						
							if (currentcd ~= 0) and (currentcd < 100) then
								DrawText(tostring(currentcd),Menu.Appearance.textsize, pos.x+6, pos.y+4, ARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),Menu.Appearance.textsize, pos.x+8, pos.y+6, ARGB(255, 0, 0, 0))
								DrawText(tostring(currentcd),Menu.Appearance.textsize, pos.x+7, pos.y+5, Textcolor)
							elseif IsKeyDown(16) then
								DrawText(tostring(level),Menu.Appearance.textsize, pos.x+6, pos.y+4, ARGB(255, 0, 0, 0))
								DrawText(tostring(level),Menu.Appearance.textsize, pos.x+8, pos.y+6, ARGB(255, 0, 0, 0))
								DrawText(tostring(level),Menu.Appearance.textsize, pos.x+7, pos.y+5, Textcolor)
							end

							pos.x = pos.x + width + sep
							if j == Menu.Appearance.n then break end
						end
					end
					pos.x = barpos.x + 25*5+3 + 2*4
					pos.y = barpos.y - 8
					--[[Last 2 spells]]
					if Menu.Appearance.showv then
						for j, Spells in ipairs (TrackSpells) do
							local currentcd = SpellsData[i][Spells].currentCd
							local maxcd = SpellsData[i][Spells].maxCd
							local width2 = Menu.Appearance.width2
							if j > 4 then
								CDcolor = ARGB(Menu.Colors.SSpells["TheRest"][1], Menu.Colors.SSpells["TheRest"][2], Menu.Colors.SSpells["TheRest"][3], Menu.Colors.SSpells["TheRest"][4])
								for _, spell in ipairs(SSpells) do
									if (Menu.Colors.SSpells[spell.Name] ~= nil) and (hero:GetSpellData(j == 5 and SUMMONER_1 or SUMMONER_2).name == spell.Name) then
										CDcolor = ARGB(Menu.Colors.SSpells[spell.Name][1], Menu.Colors.SSpells[spell.Name][2], Menu.Colors.SSpells[spell.Name][3], Menu.Colors.SSpells[spell.Name][4])
									end
								end
								DrawRectangleAL(pos.x, pos.y,width2+2,11,Backgroundcolor)
								if currentcd ~= 0 then
									DrawRectangleAL(pos.x+1, pos.y+1, width2 - width2 * currentcd / maxcd,9,CDcolor)
								
								else
									DrawRectangleAL(pos.x+1, pos.y+1, width2, 9, CDcolor)
								end
								if (currentcd ~= 0) and (currentcd < 100) then
									DrawText(tostring(currentcd),Menu.Appearance.textsize, pos.x-1, pos.y-1, ARGB(255, 0, 0, 0))
									DrawText(tostring(currentcd),Menu.Appearance.textsize, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
									DrawText(tostring(currentcd),Menu.Appearance.textsize, pos.x, pos.y, Textcolor)
								end
								Readycolor = CDcolor
								pos.y = pos.y - 12
							end
						end
					end
				end
			end
		end
	end
end
