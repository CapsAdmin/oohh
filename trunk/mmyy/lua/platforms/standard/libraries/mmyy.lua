local mmyy = _G.mmyy or {}

if WINDOWS then
	ffi.cdef("int SetConsoleTitleA(const char* blah);")

	function mmyy.SetWindowTitle(...)
		return ffi.C.SetConsoleTitleA(...)
	end
end

if LINUX then
	function mmyy.SetWindowTitle(title)
		return io.write('-ne "\033]0;'..title..'\007"')
	end
end

if mmyy.lua_environment_sockets then
	for key, val in pairs(mmyy.lua_environment_sockets) do
		utilities.SafeRemove(val)
	end
end

mmyy.lua_environment_sockets = {}

function mmyy.CreateLuaEnvironment(title, globals, id)	
	check(globals, "table", "nil")
	id = id or title
	
	local socket = mmyy.lua_environment_sockets[id] or NULL
	
	if socket:IsValid() then 
		socket:Send("exit")
		socket:Remove()
	end
	
	local socket = luasocket.Server()
	socket:Host("*", 0)
					
	mmyy.lua_environment_sockets[id] = socket
	
	local arg = ""
		
	globals = globals or {}
	
	globals.MMYY_PLATFORM = _G.MMYY_PLATFORM or globals.MMYY_PLATFORM
	globals.PORT = socket:GetPort()
	globals.CREATED_ENV = true
	globals.TITLE = tostring(title)

	for key, val in pairs(globals) do
		arg = arg .. key .. "=" .. luadata.ToString(val) .. ";"
	end	
	
	arg = arg:gsub([["]], [[']])	
	arg = ([[-e %sloadfile('%sinit.lua')()]]):format(arg, e.LUA_FOLDER)
	
	if WINDOWS then
		os.execute([[start "" "luajit" "]] .. arg .. [["]])
	elseif LINUX then
		os.execute([[luajit "]] .. arg .. [[" &]])
	end
	
	local env = {}
	
	function env:OnReceive(line)
		local func, msg = loadstring(line)
		if func then
			local ok, msg = pcall(func) 
			if not ok then
				print("runtime error:", client, msg)
			end
		else
			print("compile error:", client, msg)
		end
	end
	
	local queue = {}
		
	function env:Send(line)
		if not socket:HasClients() then
			table.insert(queue, line)
		else
			socket:Broadcast(line, true)
		end
	end
	
	function env:Remove()
		self:Send("os.exit()")
		socket:Remove()
	end
	
	socket.OnClientConnected = function(self, client)	
		for k,v in pairs(queue) do
			socket:Broadcast(v, true)
		end
		
		queue = {}
		
		return true 
	end
		
	socket.OnReceive = function(self, line)
		env:OnReceive(line)
	end
		
	env.socket = socket
	
	return env
end

function mmyy.CreateConsole(title)
	local env = mmyy.CreateLuaEnvironment(title, {CONSOLE = true})
	
	env:Send([[
		local __stop__
		
		local function clear() 
			print(("\n"):rep(1000)) -- lol
		end
				
		local function exit()
			__stop__ = true
		end
		
		clear()
		
		ENV_SOCKET.OnClose = function() exit() end

		event.AddListener("OnConsoleEnvReceive", TITLE, function()
			::again::
			
			local str = io.read()
			
			if str == "exit" then
				exit()
			elseif str == "clear" then
				clear()
			end
						
			if str and #str:trim() > 0 then
				ENV_SOCKET:Send(str, true)
			else
				goto again
			end
		end)
		
		event.AddListener("ShutDown", TITLE, function()
			ENV_SOCKET:Remove()
		end)
	]])	
		
	event.AddListener("OnPrint", title .. "_console_output", function(...)
		local line = tostring_args(...)
		env:Send(string.format("print(%q)", line))
	end)
	
		
	function env:Remove()
		self:Send("os.exit()")
		utilities.SafeRemove(self.socket)
		event.RemoveListener("OnPrint", title .. "_console_output")
	end
	
	
	return env
end

return mmyy