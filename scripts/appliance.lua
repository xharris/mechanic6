app_anim = function(name)
	return {
		{ name = name, frames = { 1, 2 } }
	}, 
	{ rows=1, cols=2, speed=0 }
end

local config_app = Config{
	clock1 = {
		path = 'bed1',
		formal = 'clock',
		time = 12,
		active_sound = "clock_tick.mp3",
		finish_sound = "alarm_clock_ring.mp3",
		room = "bedroom"
	},
	clock2 = {
		path = 'bed2',
		formal = 'clock',
		time = 8,
		active_sound = "clock_tick.mp3",
		finish_sound = "alarm_clock_ring.mp3",
		room = "bedroom"
	},
	lamp = {
		path = 'bd_desk',
		active_anim = true,
		time = 5,
		room = "bedroom"
	},
	sink = {
		active_anim = true,
		time = 6,
		room = "bathroom"
	},
	television = {
		active_anim = true,
		time = 20,
		room = "living_room"
	},
	window = {
		active_anim = true,
		time = 10,
		room = "bedroom"
	},
	microwave = {
		active_anim = true,
		time = 30,
		room = "living_room"
	}
}

config_app:iterateKeys(function(key, info)
	info.formal = info.formal or key
	
	if info.active_sound then
		Audio(info.active_sound, {
			name = info.formal,
			looping = true,
			type = 'static'
		})
	end
	if info.finish_sound then
		Audio(info.finish_sound, {
			name = info.formal.."_finish",
			type = 'static'
		})
	end
end)

local app_list = {}

ActiveCircle = Entity("ActiveCircle",{
	r = 0,
	spawn = function(self)
		Game.main_map:add(self, "entities")
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
		local cam_spots = Game.main_map:getEntityInfo("camera_spot")
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
			
			self.activated = true
			
			-- was a user asking for activation?
			if not self.needs_activation then 
				Timer.after(0.5, function()
					Game.gameOver(string.expand([[
It seems we have received a complaint from the ${family:capitalize()} family. Their 
$1 turns on by itself. They believe it is broken and will be returning their Congo 
products.
]], self.formal_name))
				end)
			else 
				self.needs_activation = false
				self:emit("activate")
			end
			
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
	return app_list[path_name] or {}
end

Appliance.request = function(name)
	local ent = Appliance.get(name)
	if ent then 
		ent.needs_activation = true
		return ent
	end
end