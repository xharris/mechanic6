local os_margin = 5
local family = table.random{"johnson","smith","harris"}

animation_info = function(name)
	return {
		{ name = name.."_stand", frames = { 1 } },
		{ name = name.."_walk", frames = { 2, 3 } },
		{ name = name.."_dance", frames = { 2, 3 } }
	}, 
	{ rows=1, cols=3, speed=10 }
end
	
Input.set({
	mouse = {'mouse1'},
	mouse_rpt = {'mouse1'}
},{ no_repeat={'mouse'} })

Game{
	plugins = { "xhh-array", "xhh-effect" },
	effect = { 'curvature', 'scanlines' },
	background_color="gray",
	load = function()	
		Feature.disable("effect")
		
		Game.effect:set("curvature", "distortion", 0.05)
		Game.effect:set("scanlines", "edge", { 0.9, 0.95 })
		
		-- os background
		local bg = Image{file="windows_background_knockoff.png", draw=true}
		bg.z = -100
			
		-- house map
		Game.main_map = Map.load('main.map')
		Game.main_map:remDrawable()
		
				
		-- window: house monitor
		local win_house = PCWindow{
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
		local list_camera = ButtonList{
			width = 320, height = 160 - TITLEBAR_HEIGHT
		}
		local win_cameras = PCWindow{
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
		list_camera:on(function(item)
			win_house:switch_cam(item)
		end)
		local camera_spots = Game.main_map:getEntityInfo("camera_spot")
		list_camera:addItems(camera_spots, 'map_tag')
		
		-- window: appliance list
		local list_appliance = ButtonList{
			width = 320, height = 240 - TITLEBAR_HEIGHT
		}
		local win_appliance = PCWindow{
			x = os_margin, y = os_margin,
			width = 320, height = 240,
			title = "congo_appliance_rootkit.exe",
			background_color = "white",
			draw_fn = function()
				list_appliance:draw()
			end
		}
		win_appliance:add(list_appliance)
		local appliances = Game.main_map:getEntityInfo("appliance")
		list_appliance:addItems(appliances, 'map_tag')
				
		-- setup family members
		local members = { "son" }
		for _, name in ipairs(members) do
			local new_person = Person{name = name}
			local spawn_spot -- = table.random(camera_spots)
			for _, spot in ipairs(camera_spots) do 
				if spot.map_tag == "bedroom" then 
					spawn_spot = spot	
				end
			end
			new_person:use(spawn_spot, {'x', 'y'})
			new_person:moveTo("bd_desk")
			win_house:switch_cam(spawn_spot.map_tag)
		end
	end,
	update = function(dt)
		WindowManager.update(dt)
	end
}

