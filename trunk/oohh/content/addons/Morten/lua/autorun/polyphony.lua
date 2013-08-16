

polyphony = polyphony or {}

if CLIENT then

	rawaudio.Open(0.1)

	event.AddListener("PostGameUpdate", "polyphony", function()
		rawaudio.Update()
	end)

	do
		local function sine(x)
			return math.sin(x % 1 * math.pi * 2)
		end

		local function pwm(x, y)
			return (x % 1 < y) and -1 or 1
		end

		local function square(x)
			return pwm(x, 0.5)
		end

		local function sawtooth(x)
			return -1 + ((x % 1) * 2)
		end

		local function sawtooth2(x)
			local wave = 0

			for i = -16, 16 do
				wave = wave + (x * (1 + i * 0.1)) % 1
			end

			return (-1 + wave * 2) / 17
		end

		local function fancy(x)
			return pwm(x + sine(x * 0.986) / 2, 0.75 + math.sin(x * 0.001) * 0.24)
		end

		local waveforms = {sine, square, sawtooth, fancy, sawtooth2}
		local sounds = {}

		print("rate " .. rawaudio.GetSampleRate())

		local position = 0
		local peak = 1

		local function now()
			return position / rawaudio.GetSampleRate()
		end

		polyphony.sounds = {}
		local sounds = polyphony.sounds

		function play(frequency, amplitude, waveform)
			local id = #sounds + 1

			sounds[id] = {
				waveform,
				math.random(),
				frequency / rawaudio.GetSampleRate(),
				amplitude
			}

			print("PLAYING SOUND " .. id)

			return id
		end

		function stop(id)
			sounds[id] = nil
			print("STOPPING SOUND " .. id)
		end

		event.AddListener("AudioSample", "polyphony", function(position, channels)
			local left, right = 0, 0

			for k, v in pairs(sounds) do
				local waveform = waveforms[v[1]]

				left = left + waveform(v[2]) * v[4]
				right = right + waveform(v[2]) * v[4]

				v[2] = v[2] + v[3]
				v[4] = v[4] * 0.999999

				if v[4] < 0.01 then
					stop(k)
				end
			end

			peak = math.max(math.max(math.max(math.abs(left), math.abs(right)), peak * 0.999), 1)

			return left / peak, right / peak
		end)
	end

	function polyphony.Start(instrument, key, pitch, volume, timestamp)
		polyphony.ModifyVoice(entities.GetLocalPlayer(), instrument, key, pitch, volume, timestamp)
		polyphony.NetSend(instrument, key, pitch, volume, timestamp)
	end

	function polyphony.Stop(instrument, key)
		polyphony.ModifyVoice(entities.GetLocalPlayer(), instrument, key, 0, 0, 0)
		polyphony.NetSend(instrument, key, 0, 0, 0)
	end

	polyphony.blah = {}

	function polyphony.ModifyVoice(ply, instrument, key, pitch, volume, timestamp)
		local mult = console.GetCVarNumber("s_GameMasterVolume") * math.max(-(ply:GetEyePos():Distance(entities.GetLocalPlayer():GetEyePos()) / 1000) + 1, 0) ^ 5

		if not window.IsFocused() then
		--	mult = 0
		end
		
		if pitch == 0 and volume == 0 or mult == 0 then
			if polyphony.blah[key] then
				stop(polyphony.blah[key])
				polyphony.blah[key] = nil
			end
		elseif not polyphony.blah[key] then
			local id = play(pitch * 440, (volume / 255) * mult, instrument)
			polyphony.blah[key] = id
		end
	end

	function polyphony.NetSend(instrument, key, pitch, volume, timestamp)
		message.Send("polyphony", instrument, key, pitch, volume, timestamp)
	end

	message.AddListener("polyphony", function(ply, instrument, key, pitch, volume, timestamp)
		if ply:IsValid() then
			polyphony.ModifyVoice(ply, instrument, key, pitch, volume, timestamp)
		end
	end)
end

if SERVER then
	message.AddListener("polyphony", function(ply, instrument, key, pitch, volume, timestamp)
		if ply:IsValid() then
			message.Send("polyphony", message.PlayerFilter():AddAllExcept(ply), ply, instrument, key, pitch, volume, timestamp)
			--print(ply, instrument, key, pitch, volume, timestamp)
		end
	end)

end