wait_timer = 8 -- how long a person will wait for an appliance
walk_speed = 20 -- generally how fast every walks
appliance_timer_mult = 1.2 -- # times how long appliances stay active

family = table.random{"johnson","smith","harris"}
	
-- setup family members
local members = { "son" } --, "daughter", "father", "mother" }
local os_margin = 5
	
Input.set({
	mouse = {'mouse1'},
	mouse_rpt = {'mouse1'}
},{ no_repeat={'mouse'} })

local camera_spots, appliances
local win_house, win_cameras, win_appliance
local list_camera, list_appliance

local setupGame = function()
	Audio.hearing(100)
	
	-- os background
	local bg = Image{file="windows_background_knockoff.png", draw=true}
	bg.z = -100
	
	-- house map
	Game.main_map = Map.load('main.map')
	
	-- change camera
	local camera_spots = Game.main_map:getEntityInfo("camera_spot")
		
	-- window: house monitor
	win_house = PCWindow{
		x = Game.width - 320 - os_margin, y = os_margin,
		width = 320, height = 320,
		title = (family.."_cam.exe"),
		use_cam = true, 
		switch_cam = function(self, name)
			-- show static
			Game.main_map.effect:enable("tv static")
			for _, spot in ipairs(camera_spots) do
				if spot.map_tag == name then
					print('use',name)
					self.cam.follow = spot
					Audio.position{ x = spot.x, z = spot.y}
				end
			end
			-- hide static
			Timer.after(table.random{0.2,0.3,1}, function()
				Game.main_map.effect:disable("tv static")
			end)
		end
	}		
	Game.main_map:setEffect("tv static")
	Game.main_map.effect:disable("tv static")
	win_house:add(Game.main_map)
	
	-- house map
	local floor_map = Map.load('floor_map.map')
	local minimap_spots = floor_map:getEntityInfo("map_spot")
	local img_map_info = Image.info("floor_map.png")
		
	-- window: camera list
	win_cameras = PCWindow{
		x = os_margin, y = Game.height - 160 - os_margin - TITLEBAR_HEIGHT,
		width = 320, height = 160,
		title = "Cam Manager 0.3",
		background_color = "white",
		use_cam = true, 
		hovering_label = '',
		update_fn = function(self, dt)
		end,
		draw_fn = function(self)
			local hover_info
			
			local mx, my = Camera.coords(self.cam.name, mouse_x - self.offx, mouse_y - self.offy)
		
			for _, info in ipairs(minimap_spots) do 
				local x = info.x - (info.width / 2)
				local y = info.y - (info.height / 2)
				if 	mx > x and mx < x + info.width and 
					my > y and my < y + info.height then
					
					hover_info = info
					
					if Input.pressed('mouse') then
						win_house:switch_cam(info.map_tag)
					end
				end
			end
			
			if hover_info then
				Draw{
					{'color','black'},
					{'print',
						("ROOM ID: $1\nX=$2 Y=$3"):expand(hover_info.map_tag, hover_info.x, hover_info.y),
						self.cam.offset_x + 3,
						self.cam.offset_y + 3
					},
					{'color','red',0.5},
					{'rect','fill',hover_info.x - (hover_info.width/2),hover_info.y - (hover_info.height/2),hover_info.width,hover_info.height},
					{'color'}
				}
			end
		end
	}
	win_cameras:add(floor_map)
	win_cameras.cam.follow = { x = img_map_info.width/2, y = img_map_info.height/2 }

	-- window: appliance list
	list_appliance = ButtonList{
		width = 320, height = 240 - TITLEBAR_HEIGHT
	}
	win_appliance = PCWindow{
		x = os_margin, y = os_margin,
		width = 320, height = 240,
		title = "congo_appliance_rootkit.exe",
		background_color = "white",
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
			list_appliance.color[item] = {"green", "white"}
			-- give the list item a different color
			-- while the appliance is active
			ent:on("finish", function()
				list_appliance.color[item] = nil
				return true
			end)
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
	if true or Game.isOver then return end
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