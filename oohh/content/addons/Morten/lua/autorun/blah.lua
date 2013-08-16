

blah = blah or {}
local blah = blah

function blah.callback(self, opcode, channel, data1, data2, time)
	if opcode == 7 then return end

	print(opcode, data1, data2)

	if opcode == 0 or (opcode == 1 and data2 == 0) then
		--polyphony.Stop(5, data1)
		for k, v in ipairs(blah.outputs) do v:Send(0, 0, data1, 0) end
	elseif opcode == 1 then
		--polyphony.Start(5, data1, 2 ^ ((data1 - 52 - 5 - 12) / 12), 127, 0)
		for k, v in ipairs(blah.outputs) do v:Send(1, 0, data1, 127) end
	end
end

function blah.init()
	blah.shutdown()

	blah.inputs = {}
	blah.outputs = {}

	for k, v in ipairs(midi.GetInputs()) do
		local device, error = midi.OpenInput(k)
		if error then print("Opening '" .. v .. "' for input failed: " .. error) end
		blah.inputs[#blah.inputs + 1] = device
		device.OnReceive = blah.callback
	end

	for k, v in ipairs(midi.GetOutputs()) do
		local device, error = midi.OpenOutput(k)
		if error then print("Opening '" .. v .. "' for output failed: " .. error) end
		blah.outputs[#blah.outputs + 1] = device
	end
end

function blah.shutdown()
	if blah.inputs then
		for k, v in ipairs(blah.inputs) do utilities.SafeRemove(v) end
		blah.inputs = nil
	end

	if blah.outputs then
		for k, v in ipairs(blah.outputs) do utilities.SafeRemove(v) end
		blah.outputs = nil
	end
end

event.AddListener("LuaClose", 1, function()
	blah.shutdown()
end)
