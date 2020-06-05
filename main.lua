cheat = false
skip_intro = true -- false

Config("os",{
	margin = 50,
	wait_timer = Time.ms{sec=8}, -- how long a person will wait for an appliance
	walk_speed = 20, -- generally how fast every walks
	appliance_timer_mult = 1.2, -- # times how long appliances stay active
	search_freq = 250
})
	
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

local setupGame = function()
	Audio.hearing(100)
	
	-- os background
	Background{
		file = "windows_background_knockoff.png",
		size = "cover"
	}
	
	HouseMonitor()
	WindowCameras()	
	WindowAppliance()
end

local startGame = function()
	Game.isOver = false
	HouseMonitor.switchCam("bedroom")
	Family.addMembers()
	
	Signal.emit("game_start")	
end

Game{
	plugins = { "xhh-array", "xhh-effect", "xhh-tween" , "xhh-ui" },
	effect = { 'curvature', 'scanlines', 'static' },
	background_color="gray",
	load = function()	
		--Feature.disable("effect")
		Intro.load(setupGame, startGame)
	end,
	update = function(dt)
		if Input.pressed("leave") then 
			Game.quit()
		end	
	end
}

Game.gameOver = function(body)
	if Game.isOver then return end
	Game.isOver = true 
		
	-- Email.gameOver(body)
end

Game.getPlayTime = function()
	local game_time = Math.floor(Game.time * 1000)
	return Time.format("%hhr %mmin %ssec. \n\n", game_time)
end