local driver_updating = false
local snd_driver_timer

WinUpdate = Entity("WinUpdate",{
	spawn = function(self)
		
		self.tmr_update = Timer.after(Math.random(2000,3000), function()
			self:startUpdate()
		end)
		
		-- UI.Window
		self.win = UI.Window{
			width = 250, height = 100,
			title = "Sound driver update",
			background_color = 'white',
			draw_fn = function(win)
				if self.updating then 
					local m = 5
					Draw{
						{'color','black'},
						{'print',self.update_msg,m,5,win.width-(m*2)},
						{'lineWidth',2},
						{'rect','line',m,30,win.width - (m*2),20},
						{'color','blue'},
						{'rect','fill',m + 2,32,(win.width - ((m + 2) * 2)) * self.updating,16},
					}
				else
					Draw{
						{'color','black'},
						{'print',("A sound driver update is now available. Would you"..
						" like to update in $1 sec?"):expand(Math.floor(self.tmr_update.t)),
						0,5,win.width-10,'center'}
					}
				end
			end
		}
		self.win:focus()
		
		self.yes = UI.Button{text = 'Yes', window = self.win}
		self.no = UI.Button{text = 'No', window = self.win}
		
		self.win:add(self.yes, self.no)
				
		self.yes.x = (self.win.width / 4) - (self.yes.width / 2)
		self.yes.y = self.win.height - self.yes.height - 10
		
		self.no.x = (self.win.width - (self.win.width / 4)) - (self.no.width / 2)
		self.no.y = self.win.height - self.no.height - 10
		
		self.yes:on('click', function() 
			self.tmr_update.t = self.tmr_update.t - 1 
		end)
		self.no:on('click', function() 
			self:startUpdate("Ok, updating now then...") 
		end)
	end,
	startUpdate = function(self, msg)
		self.update_msg = msg or "Updating..."
		
		self.yes:destroy()
		self.no:destroy()
		
		self.tmr_update.paused = true
		
		-- get rid of sounds
		Audio.volume(0)

		self.updating = 0

		local finished = false
		local tmr_finish = Timer.after(Math.random(5000,2500), function()
			Audio.volume(1)
			finished = true
			driver_updating = false
			
			self.update_msg = "Update complete!"
			Timer.after(1000, function()
				self:destroy()
			end)
		end)

		-- progress bar
		Timer.every(1000, function()
			self.updating = (tmr_finish.duration - tmr_finish.t) / tmr_finish.duration
			return finished
		end) 
	end
})

Signal.on("game_start", function()
	if snd_driver_timer then 
		snd_driver_timer:destroy()
		snd_driver_timer = nil 
	end
end)

Signal.on("update", function()
	-- sound driver update 
	if not snd_driver_timer and (Game.time * 1000) > Time.ms{min=2} then 
		snd_driver_timer = Timer.after(Math.random(1000,1500), function()
			if not Game.isOver then 
				-- start the update
				if not driver_updating then 
					driver_updating = WinUpdate()
				end
			end 
			return Math.random(30,40)
		end)
	end 
end)