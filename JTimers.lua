local Saved = GetSave("Honda7Timers")
local LastPing = 0
local LastChat = 0
local ID = myHero.networkID..myHero.charName
	for i, enemy in ipairs(GetEnemyHeroes()) do
			ID =  ID..enemy.networkID
	end

	if not tostring(Saved["gameid"]):find(ID) then

		Saved["gameid"] = ID
		Saved["camps"] = 
		{
			--BLUE ["side"]
			{["cname"] = "Wraiths", ["side"] = TEAM_BLUE, ["position"] = {["x"] = 6423, ["z"] =  5208}, ["Id"] = 3, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},
			{["cname"] = "Wolves", ["side"] = TEAM_BLUE, ["position"] = {["x"] = 3317, ["z"] =  6215}, ["Id"] = 2, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},
			{["cname"] = "Golems", ["side"] = TEAM_BLUE, ["position"] = {["x"] = 8024, ["z"] =   2433}, ["Id"] = 5, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},
			{["cname"] = "Wight", ["side"] = TEAM_BLUE, ["position"] = {["x"] = 1688, ["z"] =   8248}, ["Id"] = 13, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},

			{["cname"] = "Red", ["side"] = TEAM_BLUE, ["position"] = {["x"] = 7420, ["z"] =   3733}, ["Id"] = 4, ["Rate"] = 5*60, ["NextRespawn"] = 0, ["FirstSpawn"] = 115},
			{["cname"] = "Blue", ["side"] = TEAM_BLUE, ["position"] = {["x"] = 3647, ["z"] =  7572}, ["Id"] = 1, ["Rate"] = 5*60, ["NextRespawn"] = 0, ["FirstSpawn"] = 115},

			--RED ["side"]
			{["cname"] = "Wraiths", ["side"] = TEAM_RED, ["position"] = {["x"] = 7491,["z"] =  9264}, ["Id"] = 9, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},
			{["cname"] = "Wolves", ["side"] = TEAM_RED, ["position"] = {["x"] = 10517,["z"] =  8119}, ["Id"] = 8, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},
			{["cname"] = "Golems", ["side"] = TEAM_RED, ["position"] = {["x"] = 5974,["z"] =  12012}, ["Id"] = 11, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},
			{["cname"] = "Wight", ["side"] = TEAM_RED, ["position"] = {["x"] = 12266,["z"] =  6215}, ["Id"] = 14, ["Rate"] = 50, ["NextRespawn"] = 0, ["FirstSpawn"] = 125},

			{["cname"] = "Red", ["side"] = TEAM_RED, ["position"] = {["x"] = 6436,["z"] =  10524}, ["Id"] = 10, ["Rate"] = 5*60, ["NextRespawn"] = 0, ["FirstSpawn"] = 115},
			{["cname"] = "Blue", ["side"] = TEAM_RED, ["position"] = {["x"] = 10480,["z"] =  6860}, ["Id"] = 7, ["Rate"] = 5*60, ["NextRespawn"] = 0, ["FirstSpawn"] = 115},

			--BARON & DRAGON
			{["cname"] = "Dragon", ["side"] = TEAM_NEUTRAL, ["position"] = {["x"] = 9455,["z"] =  4272}, ["Id"] = 6, ["Rate"] = 6*60, ["NextRespawn"] = 0, ["FirstSpawn"] = 2*60+30},
			{["cname"] = "Baron", ["side"] = TEAM_NEUTRAL, ["position"] = {["x"] = 4490,["z"] =  10153}, ["Id"] = 12, ["Rate"] = 7*60, ["NextRespawn"] = 0, ["FirstSpawn"] = 15*60},
		}

		NewGame = true
	end

function OnLoad()	
	local Camps = Saved["camps"]
	Menu = scriptConfig("JungleTimers", "JungleTimers")
	Menu:addSubMenu("Camps", "Camps")
	for i, camp in ipairs(Camps) do
		Menu.Camps:addParam(camp["side"]..camp["cname"], (camp["side"] == TEAM_RED and "RED" or camp["side"] == TEAM_BLUE and "BLUE" or "NEUTRAL").." - "..camp["cname"], SCRIPT_PARAM_ONOFF, true)
	end
	Menu:addSubMenu("Ping", "Ping")
		Menu.Ping:addSubMenu("Type", "S")
			Menu.Ping.S:addParam("N", "Number of pings", SCRIPT_PARAM_SLICE, 3, 0, 10)
			Menu.Ping.S:addParam("I", "Time between pings", SCRIPT_PARAM_SLICE, 1000, 0, 1000)
			Menu.Ping.S:addParam("T", "Time between pings", SCRIPT_PARAM_LIST, 1, {"Normal", "Danger" })

		Menu.Ping:addParam("Time", "Time", SCRIPT_PARAM_SLICE, 60, 0, 60)
		Menu.Ping:addParam("Baron", "Baron", SCRIPT_PARAM_ONOFF, true)
		Menu.Ping:addParam("Dragon", "Dragon", SCRIPT_PARAM_ONOFF, true)
		Menu.Ping:addParam("Blue", "Blue buff", SCRIPT_PARAM_ONOFF, true)
		Menu.Ping:addParam("Red", "Red buff", SCRIPT_PARAM_ONOFF, true)
		Menu.Ping:addParam("Enabled", "Ping before respawn", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("Chat", "Chat")
		Menu.Chat:addParam("Time", "Time", SCRIPT_PARAM_SLICE, 60, 0, 60)
		Menu.Chat:addParam("Baron", "Baron", SCRIPT_PARAM_ONOFF, true)
		Menu.Chat:addParam("Dragon", "Dragon", SCRIPT_PARAM_ONOFF, true)
		Menu.Chat:addParam("Blue", "Blue buff", SCRIPT_PARAM_ONOFF, true)
		Menu.Chat:addParam("Red", "Red buff", SCRIPT_PARAM_ONOFF, true)
		Menu.Chat:addParam("Enabled", "Chat before respawn", SCRIPT_PARAM_ONOFF, true)

	Menu:addSubMenu("Appearance", "Appearance")
		Menu.Appearance:addParam("size", "Font size", SCRIPT_PARAM_SLICE, 13, 0, 20)
		Menu.Appearance:addParam("color", "Font color", SCRIPT_PARAM_COLOR, {255,0,255,0})
		Menu.Appearance:addParam("Border", "Border", SCRIPT_PARAM_ONOFF, true)
		Menu.Appearance:addParam("bcolor", "Border color", SCRIPT_PARAM_COLOR, {255,0,0,0})
end

function RecPing(X, Y)
	local type = 0
	if Menu.Ping.S.T == 1 then
		type = PING_NORMAL
	else
		type = PING_FALLBACK
	end
	Packet("R_PING", {x = X, y = Y, type = type}):receive()
end

function OnTick()
	local Camps = Saved["camps"]

	for i, camp in ipairs(Camps) do
		if math.floor(camp["NextRespawn"] - os.clock()) ==  Menu.Chat.Time then
			if Menu.Chat.Enabled and Menu.Ping[camp["cname"]] and Menu.Ping.Enabled and (os.clock() - LastChat) > 2 then
				PrintChat("<font color=\"#FF0000\">"..camp["cname"].." will respawn in "..Menu.Chat.Time.." seconds")
			end
			LastChat = os.clock()
		end

		if math.floor(camp["NextRespawn"] - os.clock()) ==  Menu.Ping.Time then
			if Menu.Ping[camp["cname"]] and Menu.Ping.Enabled and (os.clock() - LastPing) > 2then
				for i = 1, Menu.Ping.S.N do
					DelayAction(RecPing, Menu.Ping.S.I * i/1000, {camp["position"]["x"], camp["position"]["z"]})
				end
				LastPing = os.clock()
			end
		end
	end
end

Packet.headers.PKT_S2C_Neutral_Camp_Empty = 194
function OnRecvPacket(p)
	local Camps = Saved["camps"]
	if p.header == Packet.headers.PKT_S2C_Neutral_Camp_Empty then
		local packet = Packet(p)
		--print(packet)
		if packet:get("emptyType") ~= 3 then--3 found empty
			for i, camp in ipairs(Camps) do
				if camp["Id"] == packet:get("campId") then
					Camps[i]["NextRespawn"] = os.clock() + camp["Rate"]
				end
			end
		end
	end
end

function OnReady()
	if NewGame then
		local Camps = Saved["camps"]
		for i, camp in ipairs(Camps) do
			Camps[i]["NextRespawn"] = os.clock() + Camps[i]["FirstSpawn"]
		end
	end
end

function TimeToText(t)
	local m = 0
	while t > 60 do
		m = m + 1
		t = t - 60
	end
	if t < 10 then
		t = "0"..t
	end
	return m..":"..t
end

function OnDraw()
	local Camps = Saved["camps"]
	for i, camp in ipairs(Camps) do
		if os.clock() - (camp["NextRespawn"]) < 0 and Menu.Camps[camp["side"]..camp["cname"]] then
			local t = TimeToText(- math.floor(os.clock() - camp["NextRespawn"]))
			local Point = GetMinimap(camp["position"].x - 500, camp["position"].z+500)
			DrawText(tostring(t), Menu.Appearance.size, Point.x, Point.y, ARGB(Menu.Appearance.color[1],Menu.Appearance.color[2],Menu.Appearance.color[3],Menu.Appearance.color[4]))
			if Menu.Appearance.Border then
				DrawText(tostring(t), Menu.Appearance.size, Point.x+1, Point.y+1, ARGB(Menu.Appearance.bcolor[1],Menu.Appearance.bcolor[2],Menu.Appearance.bcolor[3],Menu.Appearance.bcolor[4]))
			end
		end
	end
end

