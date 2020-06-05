local config_chat = Config("chat",{
	from = {
		"Dylan", "Samantha", "Justin", "Derek", "Jess", "Riddick", "Jotaro", "Jolyne", "Jason", "May"
	},
	starters = {
		"Hey! Sorry to bother you right now, but I have a quick question...",
		"yo, my PC is acting up..",
		"Hey, how's it going?",
		"Sup, I need ur help with something...",
		"hi, sorry I just started my internship and I have a question..."
	},
	ignored = {
		"Hello?",
		"pls respond :(",
		"You there?",
		"r u there??"
	},
	thanks = {
		"Awesome, thanks :)",
		"Sounds about right, ty!",
		"thank you very much!"
	},
	nothanks = {
		"Well that didn't work...",
		"What?",
		"ummm, no? :\\"
	},
	-- first answer is the correct one
	prompts = {
		["Can you send me the Cam Manager coordinates for the bedroom?"]={ "24,25", "45,64", "25,24", "52,42", "01,02" },
		["How many cameras are there?"]={ "5", "6", "3", "4"},
		["Which bedroom window am I supposed to open?"]={ "right", "left", "both" },
		["Who uses clock1?"]={ "Son", "Mother", "Daughter", "Father" }
	}
})

Audio('notification.mp3',{
	name = 'notification',
	volume = 0.5
})

-- print_r(table.keys(config_chat:get('prompts')))

Chat = Entity("Chat",{
	spawn = function(self)		
		self.from = table.random(config_chat:get('from'))
		self.starter = table.random(config_chat:get('starters'))
		
		local prompts = config_chat:get('prompts')
		self.question = table.random(table.keys(prompts))
		self.choices = Array.from(prompts[self.question])
		self.correct_choice = self.choices[1]
		
		self.choices:shuffle()
		
		-- UI.List
		self.list = UI.List{
			width = 320, height = 350	
		}
		
		-- UI.Window
		self.win = UI.Window{
			width = 320, height = 400,
			title = ("$1 - Congo Teams"):expand(self.from),
			background_color = "white",
			draw_fn = function()
			end
		}
		self.win:focus()
		self.win:add(self.list)
		
		self.win.x = Math.random(50, Game.width - self.win.width - 50)
		self.win.y = Math.random(50, Game.height - self.win.height - 50)
		
		local m = 10
		
		local draw_typing = function()
			local txt = self.from.." is typing..."
			local h = Draw.textHeight(txt)
			local y = self.win.height - m - h
			
			if self.choice_label then 
				y = self.choice_label.y - h
			end
			Draw{
				{'color','gray'},
				{'print', txt, m, y}
			}
		end
		
		-- messaging timeline
		self.tline = Timeline({
			{3000, draw = draw_typing},
			{3000, fn = function() self:receive(self.starter) end},
			{500},
			{1500, draw = draw_typing},
			{7000, fn = function()
				-- pop the question
				self:receive(self.question)
				
				-- UI: Choices
				local last_btn
				self.choices:forEach(function(choice, i)
					local btn = UI.Button{text = choice}
					btn.y = self.win.height - btn.height - m

					-- position it after the last button
					if last_btn then 
						btn.x = last_btn.x + last_btn.width
					end
					btn.x = btn.x + m

					-- click: send message
					btn:on('click', function(text)
						if not self.answered then -- so you can't answer multiple times and bug it out
							self.answered = tr
							self:send(text)
							if text == self.correct_choice then 
								self.tline:step('correct')
							else 
								self.tline:step('wrong')
							end	
						end
					end)

					self.win:add(btn)
					last_btn = btn
				end)
				self.choice_label = UI.Label{
					x = m, text = "Quick reply:"	
				}
				self.choice_label.y = self.win.height - last_btn.height - m - 3 - self.choice_label.height
				self.win:add(self.choice_label)
			end},
			{2000, draw = draw_typing},
			
			-- didnt answer in time
			{1000, name = 'miss', fn = function() self:receive(table.random(config_chat:get('ignored'))) end},
			{'wait', fn = function()
				Game.gameOver([[
	It has been brough to my attention that you have not been completely focused on your work lately. 
	Has something or someone been distracting you lately?
	]])
			end},
			
			-- answered incorrectly
			{1000, name = 'wrong', fn = function() self:receive(table.random(config_chat:get('nothanks'))) end},
			{'wait', fn = function()
				Game.gameOver(string.expand([[
	Your coworker, $1, claims that a recent incident was caused by you giving them bad information. 
	Has something or someone been distracting you lately?
	]], self.from))
			end},
			
			-- correct answer
			{1000, name = 'correct', draw = draw_typing},
			{2000, fn = function() self:receive(table.random(config_chat:get('thanks'))) end},
			{'wait', fn = function() self:destroy() end}
		})
		self.win:add(self.tline)
		self.tline:play()
	end,
	receive = function(self, msg)
		Audio.play('notification')
		self.list:add(("$1: $2"):expand(self.from, msg), { disabled = true })
	end,
	send = function(self, msg)
		self.list:add(("You: $1"):expand(msg), { disabled = true })
	end,
	ondestroy = function(self)
		self.win:destroy()
	end
})

local chat_timer

Signal.on("game_start", function()
	Timer.after(Time.ms{min=1},function()
		-- start chat messages
		Timer.every(Math.random(1000,1500), function()
			if not Game.isOver then Chat() end
			return Math.random(15,40)
		end)
	end)
end)