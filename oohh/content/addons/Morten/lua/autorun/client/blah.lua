utilities.MonitorFileInclude()

blah = blah or {}
local blah = blah

if blah.inputs then
	for k, v in ipairs(blah.inputs) do
		v:Close()
	end
end

if blah.outputs then
	for k, v in ipairs(blah.outputs) do
		v:Close()
	end
end

local function callback(self, opcode, channel, data1, data2, time)
	if opcode == 7 then return end

	if opcode == 3 or opcode == 6 then
		for k, v in ipairs(blah.outputs) do
			v:Send(opcode, channel, data1, data2)
		end
	end
	
	if WELL then
		WELL(opcode, channel, data1, data2)
	end
end

blah.inputs = {}
blah.outputs = {}

for k, v in ipairs(midi.GetInputs()) do
	local device, error = midi.OpenInput(k)
	if error then print(error) end
	blah.inputs[#blah.inputs + 1] = device
	device.OnReceive = callback
end

for k, v in ipairs(midi.GetOutputs()) do
	local device, error = midi.OpenOutput(k)
	if error then print(error) end
	blah.outputs[#blah.outputs + 1] = device
end

do
	local counter = 0
	local length = 256
	local buffer = {}

	for i = 1, length do
		buffer[i] = {}
	end

	WELL = function(opcode, channel, data1, data2)
		if opcode ~= 1 or data2 == 0 then return end

		for i = 1, 4 do
			local index = 1 + ((counter + (i - 1) * 12) % length)
			local events = buffer[index]
			local vol = math.floor(127 - i * 24)
			
			if i == 4 then vol = 0 end
			
			events[#events + 1] = {opcode, channel, data1, vol}
		end
	end

	event.AddListener("PostGameUpdate", 1, function()
		local index = 1 + counter % length
		local events = buffer[index]

		for _, event in ipairs(events) do
			for k, v in ipairs(blah.outputs) do
				v:Send(unpack(event))
			end
		end

		for i = 1, #events do events[i] = nil end
		counter = counter + 1
	end)

	--[=[local count = 1
	local delay = 16
	local buffer = {}
	for i = 1, delay do buffer[i] = {} end

	WELL = function(self, opcode, channel, data1, data2, time)
		for i = 1, 3 do
			local index = 1 + ((count - (i - 1) * 3) % #buffer)
			buffer[index][#buffer[index]] = {opcode, channel, data1 - (i - 1) * 3, math.floor(data2 / i)}
		end
	end

	event.AddListener("PostGameUpdate", 1, function()
		local cough = buffer[1 + count % delay]

		for k, v in ipairs(cough) do
			for kk, vv in ipairs(blah.outputs) do
				vv:Send(unpack(v))
			end
		end

		cough[1] = nil
		count = count + 1
	end)]=]
end
