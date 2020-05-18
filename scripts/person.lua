person_anim = function(name)
	return {
		{ name = name.."_stand", frames = { 1 } },
		{ name = name.."_walk", frames = { 2, 3 } },
		{ name = name.."_dance", frames = { 2, 3 } }
	}, 
	{ rows=1, cols=3, speed=10 }
end


local full_name = {
	son = { "Bobby", "Jimmy", "Timmy" },
}

local activity_list = {
	son = { "clock1", "lamp", "sink" },
	daughter = { "clock2", "lamp", "sink" }
}

local walk_speed_mult = {
	son = 1.35,
	daughter = 1.2,
	father = 0.7,
	mother = 0.8
}

local dest_taken = {}

Person = Entity("Person",{
	z = 100,
	align = 'center',
	setup = function(self, args, spawn_args)
		if spawn_args.name then
			Image.animation(spawn_args.name..".png", person_anim(spawn_args.name)) 
			args.animations = { spawn_args.name.."_stand", spawn_args.name.."_walk", spawn_args.name.."_dance" }
		end
	end,
	spawn = function(self)
		if Game.main_map then
			Game.main_map:addEntity(self, "entities")
		end
		if full_name[self.name] then 
			self.full_name = table.random(full_name[self.name])
		end
		
		local camera_spots = Game.main_map:getEntityInfo("camera_spot")
		
		local spawn_spot = table.random(camera_spots)
		self:use(spawn_spot, {'x', 'y'})
		
		self:findNewActivity()
	end,
	setAnimation = function(self, name)
		self.animation = self.name.."_"..name
	end,
	findNewActivity = function(self)
		-- find the next appliance to use
		-- one that is not already in use
		local spot
		Timer.every(0.25, function()
			spot = table.random(activity_list[self.name])
			if not dest_taken[spot] then 
				if self.last_dest then 
					-- mark the current activity as unused to allow other family members to use it
					dest_taken[self.last_dest] = false				
				end
				print(self.name,"going to",spot)
				self:moveTo(spot)
				return true
			else 
				print(self.name,"thinking about",spot)
			end
		end)
	end,
	moveTo = function(self, name)
		if Game.main_map then 
			local app = Appliance.request(name)
			local path = Game.main_map:getPaths("walk_path", "entities")[1]
			dest_taken[name] = true
			path:go(self, { 
				speed = walk_speed * walk_speed_mult[self.name], 
				target = { tag=app.path }, 
				onFinish = function()
					
				-- request appliance activation
				local alerts = {}
				local m = 20
				
				-- show an alert above the person
				local main_alert = Alert{
					x = self.x, 
					y = self.y - self.height,
					z = self.z - 1,
					fading = false
				}		
				app.needs_activation = true
								
				local tmr_lose = Timer.after(wait_timer, function()
					-- their patience ran out (game over)
					Game.gameOver(string.expand([[
It seems we have received a complaint from the ${family:capitalize()} family. Their
$1, $2, could not activate their $3 after $4 seconds of trying.
]], self.name, self.full_name, app.formal_name, wait_timer))
				end)
				local tmr_alert = Timer.every(1, function(timer)
					-- spawn a bunch of alerts based on how long person has waited
					Alert{
						x = self.x, 
						y = self.y - self.height,
						z = self.z - 2
					}
					
					timer.duration = Math.lerp(1, 0.1, tmr_lose.p)
				end)
				
				-- wait for activation
				app:on("activate", function()
					tmr_lose:destroy()
					tmr_alert:destroy()
					main_alert:destroy()
					
					app:on("finish", function()
						self.last_dest = name
						self:findNewActivity()
						return true
					end)
					
					return true 
				end)
			end})
		end
	end,
	update = function(self, dt)
		if self.is_pathing then 
			self:setAnimation("walk")
			self.scalex = self.is_pathing.direction.x
		else 
			self:setAnimation("stand")
		end	
	end
})

Alert = Entity("Alert",{
	images = { "alert.png" },
	align = "center",
	alpha = 1,
	fading = true,
	spawn = function(self)
		self.y = self.y - (self.height / 2)
		Game.main_map:add(self, "entities")
		if self.fading then
			Tween(1, self, { scalex = 3, alpha = 0 }, 'quadOut', function()
				self:destroy()
			end)
		end
	end,
	draw = function(self, d)
		Draw.color('white',self.alpha)
		d()
	end
})