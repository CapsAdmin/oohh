dofile("header_parse.lua")

addons.AutorunAll()

local MS = 16

MS = MS / 1000

for key, val in pairs(_G) do print(key) end

function main()
	event.Call("Initialize")
			
	local next_update = 0
		
	while true do
		local time = os.clock()
		
		if next_update < time then
			event.Call("OnUpdate")
			timer.Update()
			
			--print((time - os.clock()) * 1000)
		
			next_update = time + MS
		end
	end
	
	event.Call("ShutDown")
end

event.AddListener("Initialized", "main", main)