local input = _G.input or {}

input.PressedThreshold = 0.2

function input.SetupAccessorFunctions(tbl, name, up_id, down_id)
	up_id = up_id or name .. "_up_time"
	down_id = down_id or name .. "_down_time"

	local self
	tbl["Is" .. name .. "Down"] = function(self, ...)
		local args
		if not hasindex(self) then args = {self, ...} self = tbl else args = {...} end
		if not self[down_id] then self[down_id] = {} end

		for _, val in ipairs(args) do
			if not self[down_id][val] then
				return false
			end
		end
		 
		return true
	end
	
	tbl["Get" .. name .. "UpTime"] = function(self, key)
		if not hasindex(self) then key = self self = tbl end
		if not self[up_id] then self[up_id] = {} end
		return os.clock() - (self[up_id][key] or 0)
	end
	
	tbl["Was" .. name .. "Pressed"] = function(self, key)
		if not hasindex(self) then key = self self = tbl end
		if not self[down_id] then self[down_id] = {} end
		return os.clock() - (self[down_id][key] or 0) < input.PressedThreshold
	end

	tbl["Get" .. name .. "DownTime"] = function(self, key)
		if not hasindex(self) then key = self self = tbl end
		if not self[down_id] then self[down_id] = {} end
		return os.clock() - (self[down_id][key] or 0)
	end
end

function input.CallOnTable(tbl, name, key, press, up_id, down_id, skip_event)
	if not tbl then return end
	if not key then return end
	
	up_id = up_id or name .. "_up_time"
	down_id = down_id or name .. "_down_time"
	
	tbl[up_id] = tbl[up_id] or {}
	tbl[down_id] = tbl[down_id] or {}
		
	local b
		
	if type(key) == "string" then
		local byte = string.byte(key)		
		
		if byte >= 65 and byte <= 90 then -- Uppercase letters
			key = string.char(byte+32)
		end
	end
			
	if key then	
		if press and not tbl[down_id][key] then
		
			if input.debug then
				print("key", key, "pressed")
			end
		
			if not skip_event then
				b = event.Call("On" .. name .. "Input", key, press)
			end
			
			tbl[up_id][key] = nil
			tbl[down_id][key] = os.clock()
		elseif not press and tbl[down_id][key] and not tbl[up_id][key] then

			if input.debug then
				print("key", key, "released")
			end
		
			if not skip_event then
				b = event.Call("On" .. name .. "Input", key, press)
			end

			tbl[up_id][key] = os.clock()
			tbl[down_id][key] = nil
		end
	end
		
	return b
end

function input.SetupInputEvent(name)
	local down_id = name .. "_down_time"
	local up_id = name .. "_up_time"
	
	input[down_id] = {}
	input[up_id] = {}
	
	input.SetupAccessorFunctions(input, name)
	
	return function(key, press)
		return input.CallOnTable(input, name, key, press, up_id, down_id, false) 
	end
end

return input