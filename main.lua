local os_margin = 5
local family = table.random{"johnson","smith","harris"}

	
Game{
	plugins = { "xhh-array", "xhh-effect" },
	effect = { 'curvature', 'scanlines' },
	background_color="gray",
	load = function()	
		Game.effect:set("curvature", "inputSize", {Game.width, Game.height})
		Game.effect:set("curvature", "textureSize", {Game.width, Game.height})
		Game.effect:set("curvature", "distortion", 0.05)
		Game.effect:set("scanlines", "edge", { 0.9, 0.95 })
		
		Input.set({
			mouse = {'mouse1'},
			mouse_rpt = {'mouse1'}
		},{ no_repeat={'mouse'} })
		
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
			draw_fn = function()
				Game.main_map:draw()
			end,
			switch_cam = function(self, name)
				local camera_spots = Game.main_map:getEntityInfo("camera_spot")
				for _, spot in ipairs(camera_spots) do
					if spot.map_tag == name then
						self.cam.follow = spot
					end
				end
			end
		}		
		win_house:switch_cam("bathroom")
		
		-- window: camera list
		local list_appliance = ButtonList{
			width = 320, height = 160 - TITLEBAR_HEIGHT
		}
		local win_cameras = PCWindow{
			x = os_margin, y = Game.height - 160 - os_margin - TITLEBAR_HEIGHT,
			width = 320, height = 160,
			title = "Cam Manager 0.3",
			background_color = "white",
			draw_fn = function()
				list_appliance:draw()
			end
		}
		win_cameras:add(list_appliance)
		-- setup camera list
		list_appliance:on(function(item)
			win_house:switch_cam(item)
		end)
		local camera_spots = Game.main_map:getEntityInfo("camera_spot")
		for _, cam_spot in ipairs(camera_spots) do 
			table.insert(list_appliance.items, cam_spot.map_tag)
		end
		
		-- window: appliance list
		local win_appliance = PCWindow{
			x = os_margin, y = os_margin,
			width = 320, height = 240,
			title = "congo_appliance_rootkit.exe",
			background_color = "white"
		}
	end,
	update = function(dt)
		WindowManager.update(dt)
	end
}

