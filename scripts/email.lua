Email = Entity("Email",{
	spawn = function(self)
		local m = 30
		
		-- window
		self.win = PCWindow{
			x = m, y = m,
			width = Game.width - (m*2), height = Game.height - (m*2) - TITLEBAR_HEIGHT,
			title = ("From: <$1>, Subject: <$2>"):expand(self.from, self.subject),
			background_color = "white",
			draw_fn = function()
				self.list:draw()
			end
		}
		
		-- list
		self.list = ButtonList{
			width = Game.width - (m*2), height = Game.height - (m*2) - TITLEBAR_HEIGHT
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