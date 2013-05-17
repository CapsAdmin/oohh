function StartRemoteControl()
	local server = luasocket.Server()
	server:Bind("0.0.0.0", 27000)

	server.OnClientConnected = function(self, client, ip, port)
		client.buffer = {}
		client.args = {}
		return true
	end

	server.OnReceive = function(self, data, client)
		if not client.protocol then
			if data:find("^POST /") or data:find("^GET /") then
				client.protocol = "http"
				client.state = 1
				client.headers = {}
				client.body = ""
			else
				client.protocol = "blah"
			end
		end

		if client.protocol == "http" then
			local pos = data:find("\r\n")

			if not pos then
				table.insert(client.buffer, data)
				break
			else
				if client.state == 1 then
					local line = table.concat(client.buffer) .. data:sub(1, pos - 1)
					data = data:sub(pos + 2, -1)

					if line == "" then
						client.state = 2
					else
						print("line: " .. line)
					end
				elseif client.state == 2 then
					client.body = client.body .. data
				end
			end
		elseif client.protocol == "blah" then
			while true do
				local pos = data:find("\0")
			
				if not pos then
					table.insert(client.buffer, data)
					break
				else
					local message = table.concat(client.buffer) .. data:sub(1, pos - 1)
					
					if message == "" then							
						if client.args[1] then 
							console.CallCommand(client.args[1], table.concat(client.args, " ", 2), client, select(2, unpack(client.args))) 
						end
						client.args = {}
					else
						table.insert(client.args, message)
					end

					client.buffer = {}
					data = data:sub(pos + 1, -1)
				end
			end
		end
	end

end

StartRemoteControl()

console.AddCommand("l", function(client, line, ...)
	local func, msg = loadstring(line)
	if func then
		local ok, msg = pcall(func) 
		if not ok then
			print("runtime error:", client, msg)
		end
	else
		print("compile error:", client, msg)
	end
end)