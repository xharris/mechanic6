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
	daughter = { "Jessica", "Caitlyn", "Lisa" },
	mother = { "Sandra", "Louise" },
	father = { "John", "Hank", "Peter" }
}

local activity_list = {
	son = { "clock1", "lamp", "sink", "television" },
	daughter = { "clock2", "lamp", "sink", "television" },
	mother = { "sink", "television", "microwave", "window" },
	father = { "sink", "television", "microwave", "lamp" }
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
		HouseMonitor.addToMap(self, "entities")
		if full_name[self.name] then 
			self.full_name = table.random(full_name[self.name])
		end
		
		local camera_spots = HouseMonitor.getEntityInfo("camera_spot")
		
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
			if not Game.isOver and not self:moveTo(spot) then 
				-- appliance is being used
				if cheat then print(self.name,"thinking about",spot) end
			else
				-- end the search
				return true 
			end
		end)
	end,
	moveTo = function(self, name)
		if dest_taken[name] then return false end
		
		if cheat then print(self.name,"going to",name) end
		
		local app = Appliance.get(name)
		local path = HouseMonitor.getWalkPaths()

		-- free up the last appliance for other family members
		dest_taken[name] = self.name
		if self.last_dest then
			dest_taken[self.last_dest] = false
		end
		self.last_dest = name
		
		path:go(self, { 
			force = true,
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
				if cheat then print(self.name,'needs',app.formal_name) end
				
				local tmr_lose = Timer.after(wait_timer, function()
					-- their patience ran out (game over)
					
					Game.gameOver(string.expand(
						"It seems we have received a complaint from the ${family:capitalize()} family. Their "..
						"$1, $2, could not activate their $3 after $4 seconds of trying."
						, self.name, self.full_name, app.formal_name, wait_timer))

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
						if cheat then print(self.name,'finished',app.formal_name) end
						
						self:findNewActivity()
						return true
					end)

					return true 
				end)
			end
		})
		
		return true -- success
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
		HouseMonitor.addToMap(self)
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