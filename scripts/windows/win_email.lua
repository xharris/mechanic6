Email = Entity("Email",{
	spawn = function(self)
		local m = 30
		
		-- window
		self.win = UI.Window{
			x = m, y = m,
			width = Game.width - (m*2), height = Game.height - (m*2) - UI.titlebar_height,
			title = ("From: <$1>, Subject: <$2>"):expand(self.from, self.subject),
			background_color = "white",
			draw_fn = function()
				self.list:draw()
			end
		}
		
		-- list
		self.list = UI.List{
			width = Game.width - (m*2), height = Game.height - (m*2) - UI.titlebar_height
		}
		self.list.disabled = {
			["Quick reply:"] = true,
			[self.body] = true
		}
		
		-- quick replies
		self.list:add(self.body)
		self.list:add("Quick reply:")
		self.list:addItems(self.actions)
		
		self.win:add(self.list)
	end,
	on = function(self, ...)
		self.list:on(...)
	end
})

Email.gameOver = function(body)	
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
		body = "Hello,\n\n" .. (body or "?") .. "\n\n\tYou were only working for " .. Game.getPlayTime() .. email_end_key .. "\n\n"
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