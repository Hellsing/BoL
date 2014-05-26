local ItemsToBuy = {}
local ShopRange = 1250
local ShopLocation = Vector(GetShop().x, GetShop().y, GetShop().z)

function OnLoad()
	Menu = scriptConfig("Shopping Basket", "MSB")

	Menu:addParam("OnKeyPress", "Activade on pressing key:", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("P"))
	Menu:addParam("OnRecall", "Activate on recall", SCRIPT_PARAM_ONOFF, true)
	
	Menu:addParam("DrawN", "Draw items names", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("DrawS", "Draw item sprites", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("DrawG", "Draw items gold cost", SCRIPT_PARAM_ONOFF, true)

	Menu:addParam("Draw", "Draw shop range", SCRIPT_PARAM_ONOFF, true)
	Menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)

end

function GoToShop()
	if GetDistance(ShopLocation) > ShopRange then
		Packet('R_WAYPOINTS', {wayPoints = {[myHero.networkID] = {{x=ShopLocation.x, y=ShopLocation.z}}}}):receive()
	end
end

function OnGainBuff(unit, buff)
	if Menu.Enabled and Menu.OnRecall and unit.isMe and buff.name:lower():find("recall") then
		DelayAction(GoToShop, 0.3)
	end
end

function OnSendPacket(p)
	if not Menu.Enabled then return end
	if p.header == Packet.headers.PKT_BuyItemReq and not myHero.dead and (GetDistance(ShopLocation) > ShopRange or GetDistance(ShopLocation) < 400) then
		local packet = Packet(p)
		local itemId = packet:get("itemId") 
		if itemId then
			table.insert(ItemsToBuy, itemId)
		end
		p:Block()
	end
	
	if p.header == Packet.headers.PKT_RemoveItemReq and not myHero.dead then
		if GetDistance(ShopLocation) > ShopRange or GetDistance(ShopLocation) < 400 then
			p:Block()
		end
	end
end

function OnTick()
	if not Menu.Enabled then return end

	if Menu.OnKeyPress then
		GoToShop()
	end

	--[[Buy the queued items]]
	if GetDistance(ShopLocation) < ShopRange and GetDistance(ShopLocation) > 400 then
		local delay = 0
		while #ItemsToBuy > 0 do
			delay = delay + math.random(0,1000)
			delay = math.min(1500, delay)
			DelayAction(BuyItemByID, delay/1000, {ItemsToBuy[1]})
			table.remove(ItemsToBuy, 1)
		end
	end
end

function BuyItemByID(itemId)
	Packet("PKT_BuyItemReq", {itemId = itemId}):send()
end

function GetBasketGold()
	local result = 0
	if not Menu.DrawG then return result end 
		for i, item  in ipairs(ItemsToBuy) do
			local ditem = GetItem(item)
			if ditem then
				result = result + ditem.gold.total
			end	
		end
	return result
end

function OnDraw()
	
	if #ItemsToBuy > 0 then
		DrawText("Shopping Basket ("..GetBasketGold().."g)", 16, 10, 10, ARGB(255,255,255,255))
	end

	local xpos = 10
	local ypos = 20
	for i, item  in ipairs(ItemsToBuy) do
		local text = ""

		ypos = ypos +  20

		if Menu.DrawN or Menu.DrawS then
			local ditem = GetItem(item)
			local dsprite = ditem:GetSprite()
			local name = ditem:GetName()
			local gold = ditem.gold.total

			if Menu.DrawS then
				dsprite:SetScale(0.25, 0.25)
				dsprite:Draw(10, ypos - 6, 255)
			end
			if Menu.DrawN then
				text = name
			end
			if Menu.DrawG then
				text = text.." ("..gold.."g)"
			end
		else
			text = "ID "..item
		end

		
		local color = ARGB(255,255,255,255)
		if not CursorIsUnder(xpos, ypos, 100, 13) then
			color = ARGB(255, 255, 255, 255)
		else
			color = ARGB(255, 255, 0, 0)
		end
		DrawText(text, 13, xpos + 16, ypos, color)
	end

	if Menu.Draw and GetDistanceSqr(ShopLocation) < ShopRange * ShopRange * 4 then
		DrawCircle(ShopLocation.x, ShopLocation.y, ShopLocation.z, ShopRange, ARGB(255,255,255,255))
	end
end

function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local xpos = 10
		local ypos = 20
		local i = 1
		while i <= #ItemsToBuy do
			ypos = ypos +  20
			if not CursorIsUnder(xpos, ypos, 100, 13) then
				i = i + 1
			else
				table.remove(ItemsToBuy, i)
			end
		end
	end
end

--UPDATEURL=https://bitbucket.org/honda7/bol/raw/master/ShoppingBasket.lua
--HASH=7BE5EF059D4DC05E5A0C17BB8C366898
