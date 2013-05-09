-- config

local library_path = "lua/platforms/asdfml/bin32/"
local headers_path = "lua/platforms/asdfml/headers/"

local make_library_globals = true
local library_global_prefix = "sf"
local lowerHigher_case = false

local parse_headers = false
local cache_parse = false

-- this is needed for some types
local translate = 
{
	Window = "window",
	Context = "window",
	Thread = "system",
	Mutex = "system",
	Clock = "system",
	Joystick = "window",
	Mouse = "window",
	Keyboard = "window",
}

local function lib_translate(str)
	if translate[str] then return translate[str] end
	
	if str:find("RenderWindow") then	
		return "graphics"
	end
end

-- internal

if CAPSADMIN then
	parse_headers = true
	cache_parse = true
end

local libraries = {}
local headers = {}
local included = {}

local function load_libraries()
	for file_name in pairs(file.Find(library_path .. "*")) do
		local lib_name = file_name:match("sfml%-(.-)%-2.dll")
		libraries[lib_name] = ffi.load("../" .. library_path .. file_name)
		
		if make_library_globals then 
			_G[library_global_prefix .. lib_name] = libraries[lib_name]
		end
	end
end

local function process_include(str)
	local out = ""
	
	for line in str:gmatch("(.-)\n") do
		if not included[line] then
			if line:find("#include") then
				included[line] = true
				
				local file = line:match("#include <(.-)>")
				file = file:gsub("SFML/", "")
				
				out = out .. process_include(_G.file.Read(headers_path .. file) or (" // missing header " .. file))
			elseif not line:find("#") then
				out = out .. line
			end
		end
		
		out = out .. "\n"
	end
	
	return out
end

local function remove_definitions(str)
	str = str:gsub("CSFML_.- ", "")
	return str
end

local function remove_comments(str)
	str = str:gsub("//.-\n", "")
	return str
end

local function remove_whitespace(str)
	str = str:gsub("%s+", " ")
	str = str:gsub(";", ";\n")
	return str
end

local function process_header(header)
	local str = file.Read(headers_path .. header) or ""

	local out = process_include(str)
	out = remove_definitions(out)
	out = remove_comments(out)
	out = remove_whitespace(out)
	
	return out
end
	
local function generate_headers()
	for file_name in pairs(file.Find(headers_path .. "*")) do
		if file_name:find(".h", nil, true) then
			local header = process_header(file_name)
			ffi.cdef(header)
			headers[file_name] = header
		end
	end
end

local function generate_objects()
	local objects = {}
	local structs = {}
	local static = {}
	local enums = {}
	
	if parse_headers then
		for file_name, header in pairs(headers) do
			for line in header:gmatch("(.-)\n") do
				
				local type
				
				if line:find("}") then
					type = line:match("} (.-);")
				else
					type = line:match(" (.-) sf")
				end
				
				-- enum parse
				if line:find("^ sf(%u%l-) sf(%u%l-);") then
					enums[line:match("%l (sf%u%l-);")] = file_name:gsub("%.h", ""):lower()
				end
				
				if line:find("enum") then
					line = line:gsub(" typedef", "")
					local i = 0
					for enum in (line:match(" enum {(.-)}") .. ","):gmatch(" (.-),") do
						if enum:find("=") then
							local left, operator, right = enum:match(" = (%d) (.-) (%d)")
							enum = enum:match("(.-) =")
							if not operator then
								enums[enum] = enum:match(" = (%d)")
							elseif operator == "<<" then
								enums[enum] = bit.lshift(left, right)
							elseif operator == ">>" then
								enums[enum] = bit.rshift(left, right)
							end
						else
							enums[enum] = i
							i = i + 1
						end
					end
				end
				
				-- struct parse
				if type then
					type = type:gsub("%*", "")
					if not type:find("%s") and type:find("%u%l", 0) then
						type = type:sub(3)
						if not objects[type] then
							local data = structs[type] or {}
							local func_name = line:match(" (sf" .. type .. "_.-)%(")
							table.insert(data, func_name)
							structs[type] = data
						end
					end
				end
			end
		end
		
		-- object parse
		for file_name, header in pairs(headers) do
			for line in header:gmatch("(.-)\n") do
				if line:find("_create") then
					local type = line:match(" (sf.-)%*")
					if type then
						type = type:sub(3)
						
						local lib = file_name:gsub("%.h", ""):lower()
						lib = lib_translate(type) or lib
						
						local tbl = objects[type] or {ctors = {}, lib = lib, funcs = {}}
						local ctor = line:match("_createFrom(.-)%(")
						
						if ctor then
							table.insert(tbl.ctors, ctor)
						end
						
						-- asdasd
						if not type:find("_") then
							objects[type] = tbl
							structs[type] = nil
						end
					end
				end
			end
		end
		
		-- static parse
		for file_name, header in pairs(headers) do
			for line in header:gmatch("(.-)\n") do
				local type = line:match(".+(sf%u.-)_")
				if type then
					type = type:sub(3)
					if not objects[type] and not structs[type] and not type:find("%s") then
						if not objects[type] then
							local data = static[type] or {funcs = {}}
							local func_name = line:match(" (sf" .. type .. "_.-)%(")
							local lib = file_name:gsub("%.h", ""):lower()
							
							lib = lib_translate(type) or lib
												
							data.lib = lib
							table.insert(data.funcs, func_name)
							static[type] = data
						end
					end
				end
			end
		end
		
		-- object function parse
		for type, data in pairs(objects) do	
			for file_name, header in pairs(headers) do
				for line in header:gmatch("(.-)\n") do
					if line:find(" sf" .. type .. "_") then
						local func_name = line:match(" (sf" .. type .. "_.-)%(")
						table.insert(data.funcs, func_name)
					end
				end
			end
		end
	else
		objects = luadata.ReadFile(headers_path .. "../cached_parse/objects.dat")
		structs = luadata.ReadFile(headers_path .. "../cached_parse/structs.dat")
		static = luadata.ReadFile(headers_path .. "../cached_parse/static.dat")
		enums = luadata.ReadFile(headers_path .. "../cached_parse/enums.dat")
	end
	
	if cache_parse then
		if luadata then
			luadata.WriteFile(headers_path .. "../cached_parse/objects.dat", objects)
			luadata.WriteFile(headers_path .. "../cached_parse/structs.dat", structs)
			luadata.WriteFile(headers_path .. "../cached_parse/static.dat", static)
			luadata.WriteFile(headers_path .. "../cached_parse/enums.dat", enums)
		end
	end
	
	-- enum creation
	for k,v in pairs(enums) do
		local name = k:sub(3):gsub("%u", "_%1"):upper():sub(2)
		if type(v) == "number" then
			_G[name] = v
		else
			_G[name] = libraries[v][k]
		end
	end
	
	-- static creation
	for lib_name, data in pairs(static) do
		local lib = _G[lib_name:lower()] or {}
		
		for key, func in pairs(data.funcs) do
			--sfMouse_isButtonPressed
			local func_name = func:gsub("sf"..lib_name.."_", "")
			
			if not lowerHigher_case then
				func_name = func_name:sub(1,1):upper() .. func_name:sub(2)
			end
			
			lib[func_name] = libraries[lib_translate(func) or data.lib][func]
		end
		
		_G[lib_name:lower()] = lib
	end
	
	-- struct ctors
	for type, func_name in pairs(structs) do
		local declaration = "sf"..type
		_G[type] = function(...)
			return ffi.new(declaration, ...)
		end
	end

	-- object ctors
	for type, data in pairs(objects) do
		local META = {}
		META.__index = META
		
		local ctors = {}		
			
		_G[type] = function(typ, ...)
			local ctor = _G.type(typ) == "string" and typ:lower()
			
			if ctor then
				return ctors[ctor](...)
			elseif typ and ctors[""] then
				return ctors[""](typ, ...)
			else
				return ctors[""]()
			end
		end
		
		function META:__tostring()
			return ("%s [%p]"):format(type, self)
		end
		
		-- object functions
		for _, func_name in pairs(data.funcs) do
			if func_name == "sf"..type.."_create" then
				ctors[""] = libraries[data.lib][func_name]
			end
			local name = func_name:gsub("sf"..type.."_", "")
			
			if not lowerHigher_case then
				name = name:sub(1,1):upper() .. name:sub(2)
			end			
			
			META[name] = function(self, ...)
				return libraries[data.lib][func_name](self, ...)
			end
		end
		
		for _, ctor in pairs(data.ctors) do
			ctors[ctor:lower()] = libraries[data.lib]["sf"..type .. "_createFrom" .. ctor]
		end
				
		ffi.metatype("sf" .. type, META)
	end
end

load_libraries()
generate_headers()
generate_objects()