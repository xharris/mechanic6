local tline_intro

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

Intro = {
	load = function(setupGame, startGame)
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
		
		-- restarting or fresh start?
		if Game.restarting or skip_intro then
			Intro.skip()
		else 
			Intro.play()
		end	
	end,
	skip = function()
		tline_intro.restarting = true
		tline_intro:play('static') -- go to last step
	end,
	play = function()
		tline_intro:play( ) -- 'static'  )
	end
}