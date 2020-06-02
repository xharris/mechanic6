wait_timer = 8 -- how long a person will wait for an appliance
walk_speed = 20 -- generally how fast every walks
appliance_timer_mult = 1.2 -- # times how long appliances stay active
cheat = false
skip_intro = false

family = table.random{"johnson","smith","harris"}
	
-- setup family members
local members = { "son", "daughter", "father", "mother" }
local os_margin = 50
	
Input.set({
	mouse = {'mouse1'},
	mouse_rpt = {'mouse1'},
	leave = { 'escape' },
	continue = { 'space' }
},{ no_repeat={'mouse'} })

Audio("camera_switch.mp3",{
	name = "cam_switch",
	type = 'static',
	relative = true,
})

local camera_spots, appliances
local list_camera, list_appliance

local windows = {}

local setupGame = function()
	windows = {}
	Audio.hearing(100)
	
	-- os background
	Background{
		file = "windows_background_knockoff.png",
		size = "cover"
	}
	
	-- house map
	Game.main_map = Map.load('main.map')
	
	-- change camera
	local camera_spots = Game.main_map:getEntityInfo("camera_spot")
		
	-- window: house monitor
	windows.house = UI.Window{
		x = Game.width - 320 - os_margin, y = os_margin,
		width = 320, height = 320,
		title = (family.."_cam.exe"),
		use_cam = true, 
		switch_cam = function(self, name)
			-- show static
			Game.main_map.effect:enable("tv static")
			for _, spot in ipairs(camera_spots) do
				if spot.map_tag == name then
					self.cam.follow = spot
					Audio.position{ x = spot.x, z = spot.y}
				end
			end
			-- hide static
			local d = table.random{0.2,0.3,1}
			if self.tmr_switch then 
				self.tmr_switch.duration = self.tmr_switch.duration + d
			else
				if not driver_updating then Audio.volume(0.25) end
				self.tmr_switch = Timer.after(d, function()
					if not driver_updating then Audio.volume(1) end
					Audio.play("cam_switch")
					Game.main_map.effect:disable("tv static")
					self.tmr_switch = nil
				end)
			end
		end
	}		
	Game.main_map:setEffect("tv static")
	windows.house:add(Game.main_map)
	
	-- house map
	local floor_map = Map.load('floor_map.map')
	local minimap_spots = floor_map:getEntityInfo("map_spot")
	local img_map_info = Image.info("floor_map.png")
		
	-- window: camera list
	windows.camera = UI.Window{
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
						windows.house:switch_cam(info.map_tag)
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
	windows.camera:add(floor_map)
	windows.camera.cam.follow = { x = img_map_info.width/2, y = img_map_info.height/2 }

	-- window: appliance list
	list_appliance = UI.List{
		width = 320, height = 240 - UI.titlebar_height
	}
	windows.appliance = UI.Window{
		x = os_margin, y = os_margin,
		width = 320, height = 240,
		title = "congo_appliance_rootkit.exe",
		background_color = "white",
	}
	windows.appliance:add(list_appliance)

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
	
	
	Game.sortDrawables()
end

game_time = 0
local startGame = function()
	-- add family members to the house
	for _, name in ipairs(members) do
		local new_person = Person{name = name}
		Game.main_map:add(new_person)
	end	
	windows.house:switch_cam("bedroom")
	
	if Game.chat_timer then 
		Game.chat_timer:destroy()
		Game.chat_timer = nil 
	end
	
	if Game.snd_driver_timer then 
		Game.snd_driver_timer:destroy()
		Game.snd_driver_timer = nil 
	end
		
	Game.isOver = false
	game_time = 0
	-- start playtime timer
	Timer.every(1, function()
		game_time = game_time + 1000
		return Game.isOver
	end)
end
	
local bios_msg = table.random{
	{"Preparing system","Fastening seatbelts","Launching demo"},
	{"Loading system","Turning tables","Tables turned"},
	{"Starting demo","","Demo started"}
}


local intro_ctrls = "Press ALT+ENTER to toggle fullscreen, ESC to leave the game"
local intro_instr= "Welcome to CongoOS!\n\n"..
	"Use the camera manager to monitor the family of FOUR and activate their household appliances.\n"..
	"Only activate an appliance when they want to use it. No sooner! But don't wait either or\n"..
	"they will get impatient and file a complaint. You only have one chance, so don't mess up!\n\n"..
	"Good luck\n\n"..
	"Press SPACE to boot normally"
local img_congo = Image{auto_draw = false, file = "congo.png" }
local draw_bios = function(str, a)
	Draw{
		{'color','black', a or 1},
		{'rect','fill',0,0,Game.width,Game.height},
		{'color','white', a or 1},
		{'print',str,5,5},
		{'print',intro_ctrls,5,Game.height - Draw.textHeight(intro_ctrls) - 5}
	}
	img_congo.x = Game.width - img_congo.width - 5
	img_congo.y = 5
	img_congo:draw()
end

local tline_intro
Game{
	plugins = { "xhh-array", "xhh-effect", "xhh-tween" , "xhh-ui" },
	effect = { 'curvature', 'scanlines', 'static' },
	background_color="gray",
	load = function()	
		--Feature.disable("effect")
		
		Game.effect:set("curvature", "distortion", 0.05)
		Game.effect:set("scanlines", "edge", { 0.9, 0.95 })
		
		tline_intro = Timeline({
			{ 
				1500, 
				fn = function()
					-- show static effect for a second
					Game.effect:set("static", "strength", { 1, 0 })
				end,
				draw = function() 
					draw_bios(bios_msg[1])
				end 
			},
			{
				1000,
				draw = function()
					draw_bios(bios_msg[1].."\n"..bios_msg[2])
				end
			},
			{
				500,
				draw = function()
					draw_bios(bios_msg[1].."\n"..bios_msg[2].."\n"..bios_msg[3])
				end
			},
			{
				'wait',
				draw = function(tline)
					draw_bios(bios_msg[1].."\n"..bios_msg[2].."\n"..bios_msg[3].."\n\n"..intro_instr)
					
					if Input.pressed("continue") then
						setupGame()
						tline:step()
					end
				end
			},
			{
				'wait',
				name = 'static',
				fn = function(tline)
					-- show static effect for a second
					Game.effect:set("static", "strength", { 5, 0 })

					-- then, start the game
					if tline.restarting then 
						setupGame()
					end

					tline.v = { a = 1, static = 5 }
					Tween(1, tline.v, { a=0, static=0 }, nil, function()
						startGame()	
						tline:step()
					end)
				end,
				update = function(tline)
					Game.effect:set("static", "strength", { tline.v.static, 0 })
				end,
				draw = function(tline)
					if not tline.restarting then 
						draw_bios(bios_msg[1].."\n"..bios_msg[2].."\n"..bios_msg[3], tline.v.a)
					end
				end
			}
		}, { z = 1000 })
		
		if Game.restarting or skip_intro then 
			tline_intro.restarting = true
			tline_intro:play('static') -- go to last step
		else 
			tline_intro:play( ) -- 'static'  )
		end	
	end,
	update = function(dt)
		if Input.pressed("leave") then 
			Game.quit()
		end	

		-- start chat messages
		if not Game.chat_timer and game_time > Time.ms{min=1} then 
			Game.chat_timer = Timer.after(Math.random(10,15), function()
				if not Game.isOver then Chat() end
				return Math.random(15,40)
			end)
		end
		-- sound driver update 
		if not Game.snd_driver_timer and game_time > Time.ms{min=2} then 
			Game.snd_driver_timer = Timer.after(Math.random(10,15), function()
				if not Game.isOver then updateDriver() end 
				return Math.random(30,40)
			end)
		end 
	end
}

Game.gameOver = function(body)
	if Game.isOver then return end
	Game.isOver = true 
		
	local email_ends = {
		["Perhaps you should take some time off?"] = {"No thanks, I'm fine. Put me back in boss!", "Thanks, I could use a vacation"},
		["Did you have trouble reading the manual for this task?"] = {"Yes, but I would like to try again", "What manual?"}
	}
	
	local email_end_key = table.random(table.keys(email_ends))
	local choices = Array.from(email_ends[email_end_key]):map(function(c) return "> "..c end)
	
	local end_email = Email{
		from = "boss@congo.com",
		subject = "Complaint from customer",
		actions = choices.table,
		body = "Hello,\n\n" .. (body or "?") .. "\n\n\tYou were only working for " .. Time.format("%hhr %mmin %ssec. \n\n", game_time) .. email_end_key .. "\n\n"
	}
	end_email:on("click", function(item, i)
		if item == choices[1] then
			Game.restart()
		end
		if item == choices[2] then 
			Game.quit()
		end
	end)
end