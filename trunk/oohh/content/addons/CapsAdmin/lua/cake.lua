local function CharacterIterator (str)
	local i = 0
	return function ()
		if i >= #str then return nil end
		i = i + 1
		return str:sub (i, i)
	end
end

local function GetStringColumnCount (text)
	local columnCount = 0
	for c in CharacterIterator (text) do
		if c ~= "\n" then
			columnCount = columnCount + 1
		end
	end
	return columnCount
end

local v = GetStringColumnCount ("aa\n")
for i = 1, 10000 do
	local v1 = GetStringColumnCount ("aa\n")
	if v1 ~= v then
		print ("Value changed on i = " .. i .. " (" .. v .. " -> " .. v1 .. ")")
		v = v1
	end
end
print ("Done")