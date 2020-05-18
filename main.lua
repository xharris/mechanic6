wait_timer = 8
walk_speed = 20

family = table.random{"johnson","smith","harris"}
	
-- setup family members
local members = { "son", "daughter" }
local os_margin = 5
	
Input.set({
	mouse = {'mouse1'},
	mouse_rpt = {'mouse1'}
},{ no_repeat={'mouse'} })

local camera_spots, appliances
local win_house, win_cameras, win_appliance
local list_camera, list_appliance

local setupGame = function()
	-- os background
	local bg = Image{file="windows_background_knockoff.png", draw=true}
	bg.z = -100
	
	-- house map
	Game.main_map = Map.load('main.map')
	Game.main_map:remDrawable()		

	-- window: house monitor
	win_house = PCWindow{
		x = Game.width - 320 - os_margin, y = os_margin,
		width = 320, height = 320,
		title = (family.."_cam.exe"),
		use_cam = true, 
		eff_static = Effect("tv static"),
		draw_fn = function(self)
			self.eff_static:draw(function()
				Game.main_map:draw()
			end)	
		end,
		switch_cam = function(self, name)
			-- select in list
			list_camera.selected = name
			-- show static
			self.eff_static:enable("tv static")
			-- change camera
			local camera_spots = Game.main_map:getEntityInfo("camera_spot")
			for _, spot in ipairs(camera_spots) do
				if spot.map_tag == name then
					self.cam.follow = spot
				end
			end
			-- hide static
			Timer.after(table.random{0.2,0.3,1}, function()
				self.eff_static:disable("tv static")
			end)
		end
	}		
	win_house.eff_static:disable("tv static")

	-- window: camera list
	list_camera = ButtonList{
		width = 320, height = 160 - TITLEBAR_HEIGHT
	}
	win_cameras = PCWindow{
		x = os_margin, y = Game.height - 160 - os_margin - TITLEBAR_HEIGHT,
		width = 320, height = 160,
		title = "Cam Manager 0.3",
		background_color = "white",
		draw_fn = function()
			list_camera:draw()
		end
	}
	win_cameras:add(list_camera)
	-- setup camera list
	list_camera:on("click", function(item)
		win_house:switch_cam(item)
	end)
	camera_spots = Game.main_map:getEntityInfo("camera_spot")
	list_camera:addItems(camera_spots, 'map_tag')

	-- window: appliance list
	list_appliance = ButtonList{
		width = 320, height = 240 - TITLEBAR_HEIGHT
	}
	win_appliance = PCWindow{
		x = os_margin, y = os_margin,
		width = 320, height = 240,
		title = "congo_appliance_rootkit.exe",
		background_color = "white",
		draw_fn = function()
			list_appliance:draw()
		end
	}
	win_appliance:add(list_appliance)

	appliances = Game.main_map:getEntityInfo("Appliance")
	list_appliance:addItems(appliances, 'map_tag')
	list_appliance:on("enter", function(item)
		-- highlight all the appliances that match item name
		local ent = Appliance.get(item)
		if ent then 
			ent.hovered = true
		end
	end)
	list_appliance:on("leave", function(item)
		-- stop highlighting these items
		local ent = Appliance.get(item)
		if ent then 
			ent.hovered = false
		end
	end)
	list_appliance:on("click", function(item)
		local ent = Appliance.get(item)
		if ent then
			ent:activate()
		end
	end)
end

local startGame = function()
	for _, name in ipairs(members) do
		local new_person = Person{name = name}
		Game.main_map:add(new_person)
	end	
	win_house:switch_cam("bedroom")
end

Game{
	plugins = { "xhh-array", "xhh-effect", "xhh-tween" },
	effect = { 'curvature', 'scanlines', 'static' },
	background_color="gray",
	load = function()	
		Feature.disable("effect")
		
		Game.effect:set("curvature", "distortion", 0.05)
		Game.effect:set("scanlines", "edge", { 0.9, 0.95 })
		
		setupGame()
		if Game.restarting then 
			-- show rewind (static) effect for a second
			Game.effect:set("static", "strength", { 5, 0 })
			Timer.after(1, 
				function()
					-- then, start the game
					Game.effect:set("static", "strength", { 0, 0 })
					startGame()
				end
			)
		else 
			Game.effect:set("static", "strength", { 0, 0 })
			-- show splash screen then fade into game
			startGame()
		end
	end,
	update = function(dt)
		WindowManager.update(dt)
	end,
	draw = function(d)
		d()
		
	end
}

Game.isOver = false
Game.gameOver = function(body)
	if Game.isOver then return end
	Game.isOver = true 
	
	local email_ends = {
		["Perhaps you should take some time off?"] = {"No thanks, I'm fine", "Thanks, I could use a vacation"},
		["Did you have trouble reading the manual for this task?"] = {"I did and I'd like to try again", "What manual?"}
	}
	
	local email_end_key = table.random(table.keys(email_ends))
	local choices = Array.from(email_ends[email_end_key]):map(function(c) return "> "..c end)
	
	local end_email = Email{
		from = "boss@congo.com",
		subject = "Complaint from customer",
		actions = choices.table,
		body = "Hello,\n" .. (body or "?") .. "\n" .. email_end_key .. "\n"
	}
	end_email:on("click", function(item)
		if item == choices[1] then
			Game.restart()
		end
		if item == choices[2] then 
			Game.quit()
		end
	end)
end