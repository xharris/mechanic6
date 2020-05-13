local os_margin = 5
local family = table.random{"johnson","smith","harris"}

Game{
	background_color="gray",
	load = function()		
		
		Input.set({
			mouse = {'mouse1'}
		},{ no_repeat={'mouse'} })
		
		-- os background
		local bg = Image{file="windows_background_knockoff.jpg", draw=true}
			
		-- house map
		Game.main_map = Map.load('main.map')
		Game.main_map:remDrawable()
		
		-- window: house monitor
		
		local win_house = PCWindow{
			x=Game.width - 320 - os_margin, y=os_margin,
			width=320, height=320,
			title=(family.."_cam.exe"),
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
		win_house:switch_cam("bedroom")
		
				
	end
}
