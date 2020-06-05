app_anim = function(name)
	return {
		{ name = name, frames = { 1, 2 } }
	}, 
	{ rows=1, cols=2, speed=0 }
end

local config_app = Config('appliance',{
	clock1 = {
		path = 'bed1',
		formal = 'clock',
		haywire_desc = 'sets its alarm too early',
		time = 12,
		active_sound = "clock_tick.mp3",
		finish_sound = "alarm_clock_ring.mp3",
		looping = true,
		room = "bedroom"
	},
	clock2 = {
		path = 'bed2',
		formal = 'clock',
		haywire_desc = 'sets its alarm too early',
		time = 8,
		active_sound = "clock_tick.mp3",
		finish_sound = "alarm_clock_ring.mp3",
		looping = true,
		room = "bedroom"
	},
	lamp = {
		path = 'bd_desk',
		active_anim = true,
		haywire_desc = 'turns on by itself',
		time = 5,
		room = "bedroom",
		active_sound = "clickon.mp3",
		finish_sound = "clickoff.mp3"
	},
	sink = {
		active_anim = true,
		time = 6,
		room = "bathroom",
		haywire_desc = 'is leaking too much water',
		active_sound = "bathroom_faucet.mp3",
		finish_sound = "faucet_off.mp3",
		volume = 0.2
	},
	television = {
		active_anim = true,
		time = 20,
		room = "living_room",
		haywire_desc = 'turns on when no one is watching it',
		active_sound = "fakenewsreport.mp3",
		finish_sound = "tv_switch_off.mp3",
		volume = 0.2
	},
	window = {
		active_anim = true,
		time = 10,
		room = "bedroom",
		haywire_desc = 'opens randomly',
		active_sound = "nature.mp3",
		finish_sound = "window_close.mp3"	
	},
	microwave = {
		active_anim = true,
		time = 30,
		room = "living_room",
		haywire_desc = 'is running without food in it',
		active_sound = "microwave_start_n_run.mp3",
		finish_sound = "microwave_beep.mp3",
		volume = 0.2	
	}
})

local aud_filter = {
	type = "lowpass",
	volume = 1.25,
	highgain = .1,
}

Signal.on("Game.load",function()
	config_app:iterateKeys(function(key, info)
		info.formal = info.formal or key

		if info.active_sound then
			Audio(info.active_sound, {
				name = info.formal,
				looping = info.looping,
				type = 'static',
				volume = info.volume,
				filter = aud_filter
			})
		end
		if info.finish_sound then
			Audio(info.finish_sound, {
				name = info.formal.."_finish",
				type = 'static',
				volume = info.volume,
				filter = aud_filter
			})
		end
	end)
end)

local app_list = {}

ActiveCircle = Entity("ActiveCircle",{
	r = 0,
	spawn = function(self)
		HouseMonitor.addToMap(self)
	end,
	update = function(self, dt)
		self.r = self.r + 10 * dt
		if self.r > 25 then self:destroy() end
	end,
	draw = function(self)
		Draw{
			{'color','white',Math.lerp(1,0,self.r/25)},
			{'circle','line',0,0,self.r},
			{'color'}
		}
	end
})

Appliance = Entity("Appliance",{
	align = "center",
	needs_activation = false,
	setup = function(self, args, spawn_args)
		if spawn_args.map_tag then
			self.name = spawn_args.map_tag

			local config = config_app:get(spawn_args.map_tag)
			local name = config.formal or spawn_args.map_tag
			
			args.animations = { name }
			
			-- idle animation
			Image.animation(
				name..'.png', 
				app_anim(name)
			)
			
			-- active animation
			if config.active_anim then 
				Image.animation(
					name.."_active.png", 
					app_anim(name.."_active")
				)			
				table.insert(args.animations, name.."_active")
			end
		end
	end,
	spawn = function(self)
		local config = config_app:get(self.map_tag)

		app_list[self.map_tag] = self

		self.path = config.path or self.map_tag
		self.formal_name = config.formal or self.name
		
	end,
	getRoom = function(self)
		-- get info about which room this is in
		local cam_spots = HouseMonitor.getCameraSpots()
		local config = config_app:get(self.map_tag)
		for _, info in ipairs(cam_spots) do 
			if info.map_tag == config.room then 
				return info
			end
		end
	end,
	draw = function(self, d)
		if self.hovered then 
			Draw{
				{'color','white',0.25},
				{'circle','fill',0,0,50},
				{'color'}
			}
			self.anim_frame = 2
		else 
			self.anim_frame = 1
		end
		d()
	end,
	activate = function(self)
		local config = config_app:get(self.map_tag)

		-- was a person actually asking for activation?
		if not self.needs_activation then 
			Timer.after(0.5, function()
				Game.gameOver(string.expand(
					"It seems we have received a complaint from the ${family:capitalize()} family."..
					"Their $1 $2. They believe it is broken and will be returning their Congo products "..
					"for a refund.", self.formal_name, config.haywire_desc))
			end)
		end

		if not self.activated then 
			if config.active_anim then
				-- change to active animation
				self.animation = self.name.."_active"
			end
			if config.active_sound then
				-- play active sound
				local room_info = self:getRoom()
				self.aud_active = Audio.play(config.formal, {
					position = { x = room_info.x, z = room_info.y } 
				})
			end
			
			
			self:emit("activate")
			
			self.needs_activation = false
			self.activated = true
			
			-- circle effect timer
			Timer.after(1, function()
				if self.activated then 
					ActiveCircle{x = self.x, y = self.y, z = self.z - 1}
					return true
				end
			end)

			-- timer: appliance turns off
			Timer.after(config.time * appliance_timer_mult, function()
				self.activated = false 
				self.animation = self.formal_name
				-- play finish sound
				if self.aud_active then self.aud_active:stop() end
				if config.finish_sound then
					local room_info = self:getRoom()
					Audio.play(config.formal.."_finish", {
						position = { x = room_info.x, z = room_info.y } 
					})
				end
				self:emit("finish")
			end)
		end
	end
})

Appliance.get = function(path_name)
	return assert(app_list[path_name], "No appliance found: "..path_name)
end