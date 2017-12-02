--[[
	Battle Royale - Abandoned Project
]]
if br == nil then br = {} end
br.version = 0.1
br.base = "sys/lua/battle-royale/"

--[[
	Config/Presets
]]
dofile(br.base.."vars.lua")
dofile(br.base.."preset.lua")

--[[
	Load Libraries
]]
dofile(br.base..'dmenu.lua')
dofile(br.base..'timerex.lua')

--[[
	Hook Calls
]]
addhook("join", "br.Join")
addhook("team", "br.Team")
addhook("leave", "br.Leave")
addhook("die", "br.Die")
addhook("use", "br.Use")
addhook("walkover", "br.Walkover")
addhook("serveraction", "br.Serveraction")
addhook("startround_prespawn", "br.Startround_Prespawn")
addhook("startround", "br.Startround")
addhook("endround", "br.Endround")
addhook("spawn", "br.Spawn")
addhook("break", "br.Break")
addhook("menu", "dmenu.Hook")

--[[
	Initialization
]]
br.player = dmenu.initArray(32)

--[[
	Hook Functions
]]
function br.Join(id)
	br.player[id] = {
		inventory = {},
		menuUseDelay = false,
		menuDoubleToggle = false,
		menuDoubleToggleCount = 0,
		spawnedOnce = false,
		connected = false,
		score = 0,
		deaths = 0,
	}
end
function br.Team(id)
	dmenu.Construct(id)
	br.player[id].connected = true
	dmenu:add(id, "Inventory")
end

function br.Leave(id)
	dmenu.Destruct(id)
	br.player[id] = nil
	br.player[id] = 0
end

function br.Die(id, kid, wep, x, y, koid)
	if kid == 0 and #player(0, "tableliving") == 0 then
		msg('suicide!')
		parse('restartround ')
	else
		local playerlist = player(0, "tableliving")
		if #playerlist <= 1 then
			if kid ~= 0 then
				msg(player(kid, "name").." is this match's survivor!")
				msg2(kid, "+10 score for being the match's survivor!")
				parse('setscore '..kid..' '..player(id, "score")+10)
			end
			br:saveTab()
			parse('restartround 0')
		end
	end
end

function br.Use(id, event, data, x, y)
	br.player[id].menuDoubleToggleCount = br.player[id].menuDoubleToggleCount + 1
	timerEx(600, function(id) br.player[id].menuDoubleToggleCount = 0 end, 1, id)
	if br.player[id].menuDoubleToggleCount >= 2 then
		if player(id, "health") > 0 and not br.player[id].menuUseDelay then
			dmenu:display(id, "Inventory")
		end
	end
	if entity(x, y, "trigger") == "container" then
		br:spawnLoot(id, x, y)
		for _, iid in pairs(item(0, "table")) do
			if item(iid, "droptimer") <= 2 then
				parse('setammo '..iid..' 0 1000 0')
			end
		end
	end
end

function br.Break(x, y, id)
	if entity(x, y, "exists") and entity(x, y, "trigger") == "container" then
		br:spawnLoot(id, x, y)
		for _, iid in pairs(item(0, "table")) do
			if item(iid, "droptimer") <= 2 then
				parse('setammo '..iid..' 0 1000 0')
			end
		end
	end
end

function br.Walkover(id, iid, type, ain, a, mode)
	local collect = 0
	if br.inventory[type] ~= nil then
		br:updateInventory(id, type)
		collect = 1
		timerEx(100, function(iid)
			parse('removeitem '..iid)
		end, 1, iid)
	end
	return collect
end

function br.Serveraction(id, action)
	if action == 1 then
		if player(id, "health") > 0 and not br.player[id].menuUseDelay then
			dmenu:display(id, "Inventory")
		end
	end
end

function br.Startround_Prespawn(mode)
	local playerlist = player(0, "table")
	for _, id in pairs(playerlist) do
		if br:isConnected(id) then
			br.player[id].spawnedOnce = false
		end
	end
end

function br.Startround(mode)
	br.round = br.round + 1
	msg('Round: '..br.round..'/'..br.roundLimit)
	if br.round >= br.roundLimit then
		msg('Round limit reached, Restarting battle royale')
		br:resetTab()
		br.round = 0
		parse('restartround 0')
	else
		if mode == 5 then
			br:restoreTab()
		end
		local playerslist = player(0, "table")
		for _,id in pairs(playerslist) do
			if player(id, "score") >= 75 then
				parse('setscore '..id..' 10')
				parse('setarmor '..id..' 202')
				msg(player(id, "name")..'\'s score has been maxed out!')
				msg2(id, "+10 score + armor bonus start!")
			end
		end
	end
end

function br.Endround(mode)
	local playerlist = player(0, "table")
	for _,id in pairs(playerlist) do
		if br.player[id] ~= nil then
			br.player[id].inventory = nil
			br.player[id].inventory = {}
			dmenu:empty(id, "Inventory")
		end
	end
end

function br.Spawn(id)
	if br.player[id].spawnedOnce ~= true then
		br.player[id].spawnedOnce = true
	else
		timerEx(100, function(id)
			parse('killplayer '..id)
			msg2(id, 'You can only spawn once a round, please wait till the match ends')
		end, 1, id)
	end
	return "x"
end

--[[
	Functions
]]
function br:updateInventory(id, itemID)
	if br.player[id].inventory[itemID] == nil then
		br.player[id].inventory[itemID] = 1
	else
		br.player[id].inventory[itemID] = br.player[id].inventory[itemID] + 1
	end
	br:updateInventoryMenu(id)
end

function br:useItem(id, itemID)
	if br.inventory[itemID].func(id) then
		if br.player[id].inventory[itemID] > 1 then
			br.player[id].inventory[itemID] = br.player[id].inventory[itemID] - 1
		elseif br.player[id].inventory[itemID] == 1 then
			br.player[id].inventory[itemID] = nil
		end
		br:updateInventoryMenu(id)
		br.player[id].menuUseDelay = true
		timerEx(1500, function(id)
			br.player[id].menuUseDelay = false
		end, 1, id)
	else
		msg2(id, br.inventory[itemID].error)
	end
end

function br:updateInventoryMenu(id)
	dmenu:empty(id, "Inventory")
	for itemID, itemCount in pairs(br.player[id].inventory) do
		print(itemID..' x'..itemCount)
		dmenu:addButton(id, "Inventory", br.inventory[itemID].name, "x"..br.player[id].inventory[itemID], function(id, itemID)
			br:useItem(id, itemID)
		end, true, id, itemID)
	end
end

function br.player_text(id, text, color)
	if player(id, "health") > 0 then
		if color == nil then color = br.color.white end
		if text ~= nil then
			local x = 300
			local y = 220
			local y_move = y - 20
			parse('hudtxtalphafade '..id..' 1 0 1.0')
			parse('hudtxtmove '..id..' 1 1500 '..x..' '..y)
			br.hudtxt2(id, 1, text, color, x, y, 0)
			parse('hudtxtalphafade '..id..' 1 1500 0.0')
			parse('hudtxtmove '..id..' 1 1000 '..x..' '..y_move)
		end
	end
end

function br.hudtxt(id,msg,color,x,y,align)
	parse('hudtxt '..id..' "'..color..''..msg..' " '..x..' '..y..' '..align)
end

function br.hudtxt2(id,id2,msg,color,x,y,align)
	parse('hudtxt2 '..id..' '..id2..' "'..color..''..msg..' " '..x..' '..y..' '..align)
end

function br:spawnLoot(id, x, y)
	local t = br:getLootTable(player(id, "score"))
	local combination = br.loot[t][math.random(1,#br.loot[t])]
	for i=1, #combination do
		parse('spawnitem '..combination[i]..' '..x..' '..y)
	end
end

function br:getLootTable(score)
	if score >= 0 and score < 5 then return 1
	elseif score >= 5 and score < 10 then return 2
	elseif score >= 10 and score < 15 then return 3
	elseif score >= 15 and score < 20 then return 4
	elseif score >= 20 and score < 25 then return 5
	elseif score >= 25 and score < 30 then return 6
	elseif score >= 30 and score < 35 then return 7
	elseif score >= 35 and score < 40 then return 8
	elseif score >= 40 and score < 45 then return 9
	elseif score >= 45 then return 10 end
end

function br:isPrimary(type)
	if br.weaponType[type] == "primary" then return true else return false end
end

function br:isSecondary(type)
	if br.weaponType[type] == "secondary" then return true else return false end
end

function br:isConnected(id) return br.player[id].connected end

function br:saveTab(id)
	msg('saved tab')
	if id == nil then
		local playerlist = player(0, "table")
		for _, id in pairs(playerlist) do
			br.player[id].score = player(id, "score")
			br.player[id].deaths = player(id, "deaths")
		end
	else
		br.player[id].score = player(id, "score")
		br.player[id].deaths = player(id, "deaths")
	end
end

function br:restoreTab(id)
	msg('restore tab')
	if id == nil then
		local playerlist = player(0, "table")
		for _, id in pairs(playerlist) do
			parse('setscore '..id..' '..br.player[id].score)
			parse('setdeaths '..id..' '..br.player[id].deaths)
		end
	else
		parse('setscore '..id..' '..br.player[id].score)
		parse('setdeaths '..id..' '..br.player[id].deaths)
	end
end	

function br:resetTab(id)
	msg('reset tab')
	if id == nil then
		local playerlist = player(0, "table")
		for _, id in pairs(playerlist) do
			br.player[id].score = 0
			br.player[id].deaths = 0
			parse('setscore '..id..' 0')
			parse('setdeaths '..id..' 0')
		end
	else
		br.player[id].score = 0
		br.player[id].deaths = 0
		parse('setscore '..id..' 0')
		parse('setdeaths '..id..' 0')
	end
end