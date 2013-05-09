local min = {175, 45, 176, 0}
local max = {175, 45, 179, 255}

local ip = {min[1], min[1], min[1], min[1]}

local i = 1

local data = {}
local try_ip

local function get_ip()
	local ip = ""
	
	for _i = 1, 4 do	
		ip = ip .. (min[_i] + (max[_i] - min[_i])%i)
		if _i ~= 4 then
			ip = ip .. "."
		end
	end
	
	return ip
end

try_ip = function(ip)
	printf("trying ip %q", ip)

	local socket = luasocket.Client("tcp")

	socket:Connect(ip, 80)
	socket:SetMaxTimeouts(100)
	socket:Send("hello?")

	function socket:OnReceive(line)
		data[ip] = (data[ip] or "") .. line .. "\n"
	end

	function socket:OnClose()
		i = i + 1
			
		try_ip(get_ip())
		
		luadata.WriteFile("north_korean_data.txt", data)
	end
end

try_ip(get_ip())

print("!??!")