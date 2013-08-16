

local SOUNDS = {
	sine = 1, 
	square = 2, 
	sawtooth = 3, 
	fancy = 4, 
	sawtooth2 = 5,
}

local MODIFIERS = {
	["=="] = {
		args = {
			function(time) return tonumber(time) or 1 end
		},
		
		init = function(self, time)
			self.duration = time
		end,	
	},
	["--"] = {
		args = {
			function(stop_percent) return tonumber(stop_percent) or 100 end
		},
		
		init = function(self, stop_percent)
			self.duration = self.duration * (stop_percent / 100)
		end,	
	},
	["="] = {
		args = {
			function(time) return tonumber(time) or 0 end
		},
		
		init = function(self, time)
			self.duration = time
		end,
	},
	["%"] = {
		args = {
			function(pitch) return tonumber(pitch / 100)  end,
		},
		
		init = function(self, pitch)			
			self.pitch = pitch
		end,
		
		think = function(self, pitch, time)			
			polyphony.Start(self.path, self.path, pitch, self.volume, 0)
		end,
	},
	["^"] = {
		args = {
			function(volume) return tonumber(volume) / 100 end,
		},
		
		think = function(self, volume)
			polyphony.Start(self.path, self.path, self.pitch, volume, 0)
		end,
	}
}

local function PLAY_SOUND(self)
	polyphony.Start(self.path, self.path, self.pitch, self.volume, 0)
end

local function STOP_SOUND(self)
	polyphony.Stop(self.path, self.path)
end

--
local cache = {}

local function parse(str)
	if cache[str] then return cache[str] end
	
	local out = {}
	
	-- lowercase it so we don't have to deal with case sensitivity
	str = str:lower()
	
	-- add a last space so it matches the end as well
	str = str .. " "
	
	-- split the input by either space or ;
	for line in str:gmatch("(.-)%s") do
		local key, mods = line:match("([a-z_]+)([%p%d]+)")
				
		-- if it doesn't have a modifier, use the whole line
		if not key then
			key = line
		end
		
		local modifiers = {}
		
		if mods then			
			for mod, args in mods:gmatch("(%p+)([%d%.,]+)") do			
				if args then
					-- add a last . so it matches the end as well
					args = args .. ","
					
					local temp = {}
					
					-- split the args by .
					for arg in args:gmatch("(.-),") do
						
						-- if it's a number make it a number, otherwise leave it as string
						arg = tonumber(arg) or arg
						
						table.insert(temp, arg)
					end		
					
					table.insert(modifiers, {mod = mod, args = temp})
				end			
			end
		end
			
		table.insert(out, {key = key, modifiers = modifiers})
	end
		
	cache[str] = out
	
	return out
end

local function play(sounds) 
	local id = "LOL_" ..tostring(sounds)
	local active_sounds = {}
	
		event.AddListener("PostGameUpdate", id, function()
		for key, data in pairs(active_sounds) do
			if data.stop_time < os.clock() then
				if data.last_sound then
					print(data.active_sounds[key])
					data.active_sounds[key]:stop()
					hook.Remove("PostGameUpdate", id)
				end
				active_sounds[key] = nil
			else
				data:think()
			end
		end
	end)
	
	-- copy the table since we're going to modify it
	sounds = table.copy(sounds)
	
	for i, sound in ipairs(sounds) do
		local path = SOUNDS[sound.key]
		
		if path then
			sound.volume = 100
			sound.pitch = 100
			sound.path = path
			sound.duration = 1
			sound.id = math.random(1000)
			
			sound.play = function(self) 
				for i, data in pairs(self.modifiers) do
					local mod = MODIFIERS[data.mod]						
					if mod and mod.start then
						mod.start(self, unpack(data.args))
					end
				end
				PLAY_SOUND(self)
			end
			
			sound.remove = function(self)
				for i, data in pairs(self.modifiers) do
					local mod = MODIFIERS[data.mod]						
					if mod and mod.stop then
						mod.stop(self, unpack(data.args))
					end
				end
				STOP_SOUND(self)
			end
			
			-- only add a think function if the modifier exists
			if sound.modifiers then				
				
				-- if args is defined use it to default and clamp the arguments
				for i, data in pairs(sound.modifiers) do
					local mod = MODIFIERS[data.mod]
					if mod and mod.args then
						for i, func in pairs(mod.args) do
							data.args[i] = func(data.args[i])
						end
					end
				end
				
				sound.think = function(self) 
					for i, data in pairs(self.modifiers) do
						local mod = MODIFIERS[data.mod]						
						if mod and mod.think then
							mod.think(self, unpack(data.args))
						end
					end
				end
			end
		end
	end
		
	-- play it
	local duration = 0
	local last
	
	for i, sound in ipairs(sounds) do
		
		if sound.play then
						
			-- let it be able to think once first so we can modify duration and such when changing pitch
			if sound.think then
				sound:think()
			end
			
			for mod, data in pairs(sound.modifiers) do
				local mod = MODIFIERS[data.mod]						
				if mod and mod.init then
					mod.init(sound, unpack(data.args))
				end
			end
			
			
					
			timer.Simple(duration, function()
				if last then
					last:remove()	
				end
					
				sound.stop_time = os.clock() + sound.duration		
					
				sound:play()
									
				if sound.think then
					table.insert(active_sounds, sound)
				end
					
				if i == #sounds then
					sound.last_sound = true
				end
					
				last = sound
			end)
						
			duration = duration + sound.duration			
		end
		
	end
end

play(parse[[
fancy%100=0.1
fancy%125=0.1
fancy%150=0.1
fancy%125=0.1
fancy%150=0.1
fancy%125=0.1
fancy%150--0
]])