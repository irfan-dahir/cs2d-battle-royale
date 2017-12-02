if dmenu == nil then dmenu = {} end
dmenu.author = "Nighthawk"
dmenu.authorUSGN = 116310
dmenu.version = 0.2

--[[
	Logging
]]
dmenu.log = true
dmenu.debug = true
dmenu.error = true

--[[
	Initialization
]]
function dmenu.initArray(endset,value) if value == nil then value = 0 end local array = {} for i=1, endset do array[i] = value end return array end

dmenu.object = dmenu.initArray(32)
dmenu.pageString = dmenu.initArray(32)

--[[
	Hook Functions
]]

function dmenu.Construct(id) --addhook("join", "dmenu.Construct")
	dmenu.object[id] = {}
	dmenu.pageString[id] = {}
	dmenu:log("debug", "[#"..id.."] constructed")
	return true
end

function dmenu.Destruct(id) --addhook("leave", "dmenu.Destruct")
	dmenu.object[id] = nil
	dmenu.pageString[id] = nil
	dmenu.object[id] = 0
	dmenu.pageString[id] = 0
	dmenu:log("debug", "[#"..id.."] destructed")
	return true
end

function dmenu.Hook(id, menuName, button) --addhook("menu", "dmenu.Hook")
	page = tonumber(menuName:sub(2,2))
	menuName = menuName:sub(5)
	if dmenu:exists(id, menuName) then
		if button < 8 and button > 0 then
			local sid = button + (7*(page-1))
			dmenu:callFunc(id, menuName, sid)
		else
			if button == 8 then
				dmenu:display(id, menuName, (page+1))
			elseif button == 9 then
				dmenu:display(id, menuName, (page-1))
			end
		end
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
end

--[[
	Functions
]]

function dmenu:display(id, menuName, page)
	if page == nil or page < 1 then page = 1 end
	local pages = 0
	local itemCount = 0
	if dmenu:exists(id, menuName) then
		itemCount = #dmenu.object[id][menuName].items
		pages = math.ceil(itemCount/7)
		if itemCount == 0 then
			dmenu:log("error", "[#"..id.."] Can not display \""..menuName.."\", it's empty!")
			return false
		end
		dmenu.pageString[id][menuName] = {}
		for i=1, pages do
			--local page_string = i.." - "..dmenu.object[id][menuName].title..","
			local page_string = "["..i.."] "..dmenu.object[id][menuName].title..","
			for ii=1, 7 do
				local iii = ii+(7*(i-1))
				local button = ""
				if dmenu.object[id][menuName].items[iii] ~= nil and type(dmenu.object[id][menuName].items[iii]) == "table" then
					local buttonName = dmenu.object[id][menuName].items[iii][1]
					local buttonDesc = dmenu.object[id][menuName].items[iii][2]
					local buttonState = dmenu.object[id][menuName].items[iii][4]
					if buttonState == nil then buttonState = true end
					local button = buttonName
					if buttonDesc ~= nil then
						button = button.." | "..buttonDesc
					end
					if buttonState == false then
						button = "("..button..")"
					end
					page_string = page_string..button..","
				else
					page_string = page_string..","
				end
			end
			if i < pages then page_string = page_string.."Next" end
			if i > 1 then page_string = page_string..",Back" end
			dmenu.pageString[id][menuName][i] = page_string
		end
		menu(id, dmenu.pageString[id][menuName][page])
		return true
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
		return false
	end
end

function dmenu:add(id, menuName)
	dmenu.object[id][menuName] = {
		title = menuName,
		items = {}
	}
	dmenu:log("debug", "[#"..id.."] added \""..menuName.."\"")
	return true
end

function dmenu:remove(id, menuName)
	if dmenu:exists(id, menuName) then
		dmenu.object[id][menuName] = nil
		dmenu:log("debug", "[#"..id.."] removed \""..menuName.."\"")
		return true
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:push(id, menuName, itemArr)
	if dmenu:exists(id, menuName) then
		local pushed = 0
		if itemArr == nil then
			dmenu:log("error", "[#"..id.."] Can't push a nil array into \""..menuName.."\"")
			return false
		end
		if #itemArr <= 0 then
			dmenu:log("error", "[#"..id.."] Can't push an empty array into \""..menuName.."\"")
			return false
		end
		for i=1, #itemArr do
			table.insert(dmenu.object[id][menuName].items, itemArr[i])
			pushed = pushed + 1
		end
		return true
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:link(id, menuName, itemArrPointer)
	if dmenu:exists(id, menuName) then
		if itemArrPointer == nil then
			dmenu:log("error", "[#"..id.."] Can't link a nil array into \""..menuName.."\"")
			return false
		end
		if #itemArrPointer <= 0 then
			dmenu:log("error", "[#"..id.."] Can't link an empty array into \""..menuName.."\"")
			return false
		end
		dmenu.object[id][menuName].items = itemArrPointer
		dmenu:log("debug", "[#"..id.."] linked "..tostring(itemArrPointer).." to \""..menuName.."\"")
		return true
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:empty(id, menuName)
	if dmenu:exists(id, menuName) then
		dmenu.object[id][menuName].items = nil
		dmenu.object[id][menuName].items = {}
		return true
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:exists(id, menuName)
	if dmenu.object[id][menuName] ~= nil and type(dmenu.object[id][menuName]) == "table" then
		return true
	end
	return false
end

function dmenu:addButton(id, menuName, buttonName, buttonDesc, buttonFunc, buttonState, ...)
	if dmenu:exists(id, menuName) then
		if buttonState == nil then buttonState = true end
		table.insert(dmenu.object[id][menuName].items, {buttonName, buttonDesc, buttonFunc, buttonState, {...}})
		local offset = #dmenu.object[id][menuName].items
		dmenu:log("debug", "[#"..id.."] added button \""..buttonName.."\" to \""..menuName.."\" at offset "..offset)
		return true
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:removeButton(id, menuName, offset)
	if dmenu:exists(id, menuName) then
		if dmenu:buttonExists(id, menuName, offset) then
			dmenu.object[id][menuName].items[offset] = nil
			dmenu:log("debug", "[#"..id.."] removed button from \""..menuName.."\" from offset "..offset)
			return true
		else
			dmenu:log("error", "[#"..id.."] button at offset "..offset.." does not exist in \""..menuName.."\"")
		end
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:editButton(id, menuName, offset, buttonName, buttonDesc, buttonFunc, buttonState, ...)
	print(id, menuName, offset, buttonName, buttonDesc)
	if dmenu:exists(id, menuName) then
		if dmenu:buttonExists(id, menuName, offset) then
			dmenu.object[id][menuName].items[offset] = nil
			dmenu.object[id][menuName].items[offset] = {buttonName, buttonDesc, buttonFunc, buttonState, {...}}
			local offset = #dmenu.object[id][menuName].items
			dmenu:log("debug", "[#"..id.."] added button to \""..menuName.."\" at offset "..offset)
			return true
		else
			dmenu:log("error", "[#"..id.."] button at offset "..offset.." does not exist in \""..menuName.."\"")
		end
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:switchButton(id, menuName, offset, state)
	if dmenu:exists(id, menuName) then
		if dmenu:buttonExists(id, menuName, offset) then
			dmenu.object[id][menuName].items[offset][4] = state
			return true
		else
			dmenu:log("error", "[#"..id.."] button at offset "..offset.." does not exist in \""..menuName.."\"")
		end
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:getButtonPropertyByOffset(id, menuName, offset)
	if dmenu:exists(id, menuName) then
		if dmenu:buttonExists(id, menuName, offset) then
			return dmenu.object[id][menuName].items[offset]
		else
			dmenu:log("error", "[#"..id.."] button at offset "..offset.." does not exist in \""..menuName.."\"")
		end
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:buttonExists(id, menuName, offset)
	if dmenu:exists(id, menuName) then
		if dmenu.object[id][menuName].items[offset] ~= nil then
			return true
		end
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:getButtonCount(id, menuName)
	if dmenu:exists(id, menuName) then
		return #dmenu.object[id][menuName].items
	else
		dmenu:log("error", "[#"..id.."] \""..menuName.."\" does not exist")
	end
	return false
end

function dmenu:callFunc(id, menuName, offset)
	if dmenu.object[id][menuName].items[offset][3] ~= nil and type(dmenu.object[id][menuName].items[offset][3]) == "function" then
		dmenu.object[id][menuName].items[offset][3](unpack(dmenu.object[id][menuName].items[offset][5]))
	end
end

function dmenu:log(logType, text) -- <private function> logs eror/debug stuff
	if dmenu.log then
		local __callerFunc = debug.getinfo(2).name or "unknown"
		if logType == "debug" then
			if dmenu.debug then
				print("["..logType.."]["..__callerFunc.."]"..text)
			end
		elseif logType == "error" then
			if dmenu.error then
				print("["..logType.."]["..__callerFunc.."]"..text)
			end
		end
	end
end