local win, floor_map, minimap_spots, img_map_info

WindowCameras = callable {	
	__call = function()
		if window then return end
		
		local cfg_os = Config("os")
		local os_margin = cfg_os:get("margin")
		
		floor_map = Map.load('floor_map.map')
		minimap_spots = floor_map:getEntityInfo("map_spot")
		img_map_info = Image.info("floor_map.png")

		win = UI.Window{
			x = os_margin, y = Game.height - 160 - os_margin - UI.titlebar_height,
			width = 320, height = 160,
			title = "Cam Manager 0.3",
			background_color = "white",
			use_cam = true, 
			hovering_label = '',
			draw_fn = function(self)
				local hover_info

				local mx, my = Camera.coords(self.cam.name, mouse_x - self.offx, mouse_y - self.offy)

				for _, info in ipairs(minimap_spots) do 
					local x = info.x - (info.width / 2)
					local y = info.y - (info.height / 2)
					if 	mx > x and mx < x + info.width and 
						my > y and my < y + info.height then

						hover_info = info

						if Input.pressed('mouse_rpt') then
							HouseMonitor.switchCam(info.map_tag)
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
		
		win:add(floor_map)
		win.cam.follow = { x = img_map_info.width/2, y = img_map_info.height/2 }
	end
}