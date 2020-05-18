app_anim = function(name)
	return {
		{ name = name, frames = { 1, 2 } }
	}, 
	{ rows=1, cols=2, speed=0 }
end

local name2path = {	
	clock1 = 'bed1',
	clock2 = 'bed2',
	lamp = 'bd_desk'
}

local name2formal = {
	clock1 = 'clock',
	clock2 = 'clock',
	lamp = 'lamp'
}

local no_active = {
	clock = true
}

local active_time = {
	clock1 = 12,
	clock2 = 8,
	lamp = 5,
	sink = 6
}

local app_list = {}

Appliance = Entity("Appliance",{
	align = "center",
	needs_activation = false,
	setup = function(self, args, spawn_args)
		if spawn_args.map_tag then
			self.name = spawn_args.map_tag
			local name = name2formal[spawn_args.map_tag] or spawn_args.map_tag
			
			args.animations = { name }
			
			Image.animation(
				name..'.png', 
				app_anim(name)
			)
			
			-- active animation
			if not no_active[name] then 
				Image.animation(
					name.."_active.png", 
					app_anim(name.."_active")
				)			
				table.insert(args.animations, name.."_active")
			end
		end
	end,
	spawn = function(self)
		app_list[self.map_tag] = self
		self.path = name2path[self.map_tag] or self.map_tag
		self.formal_name = name2formal[self.name] or self.name
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
		if not self.activated then 
			if not no_active[self.formal_name] then
				self.animation = self.name.."_active"
			end
			self.activated = true
			Timer.after(active_time[self.name], function()
				self.activated = false 
				self.animation = self.formal_name
				self:emit("finish")
			end)
			-- was a user asking for activation?
			if not self.needs_activation then 
				Game.gameOver(string.expand([[
It seems we have received a complaint from the ${family:capitalize()} family. Their 
$3 turns on by itself. They believe it is broken and will be returning their Congo 
products.
]], self.formal_name))
			else 
				self.needs_activation = false
				self:emit("activate")
			end
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