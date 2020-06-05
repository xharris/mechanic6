local window, main_map, camera_spots, tmr_switch

HouseMonitor = callable{
	__call = function(_)
		if window then return end
		
		local cfg_os = Config("os")
		local os_margin = cfg_os:get("margin")

		-- window: house monitor
		window = UI.Window{
			x = Game.width - 320 - os_margin, y = os_margin,
			width = 320, height = 320,
			title = (family.."_cam.exe"),
			use_cam = true
		}

		-- map: house
		main_map = Map.load('main.map')
		main_map:setEffect("tv static")
		window:add(main_map)
		
		camera_spots = main_map:getEntityInfo("camera_spot")
	end,
	getWalkPaths = function()
		return main_map:getPaths("walk_path", "entities")[1]
	end,
	addToMap = function(...)
		main_map:add(...)
	end,
	getCameraSpots = function()
		return camera_spots
	end,
	switchCam = function(name)
		-- show static
		main_map.effect:enable("tv static")
		for _, spot in ipairs(camera_spots) do
			if spot.map_tag == name then
				window.cam.follow = spot
				Audio.position{ x = spot.x, z = spot.y}
			end
		end
		-- hide static
		local d = table.random{0.2,0.3,1}
		if tmr_switch then 
			tmr_switch.duration = tmr_switch.duration + d
		else
			if not driver_updating then Audio.volume(0.25) end
			tmr_switch = Timer.after(d, function()
				if not driver_updating then Audio.volume(1) end
				Audio.play("cam_switch")
				main_map.effect:disable("tv static")
				tmr_switch = nil
			end)
		end
	end,
	getEntityInfo = function(...)
		return main_map:getEntityInfo(...)
	end
}