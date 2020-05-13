TITLEBAR_HEIGHT = 16
BORDER_COLOR = Draw.hexToRgb("#6a717b")

local window_list = {}

WindowManager = {
	update = function(self, dt)
		local titlebar_focus, bg_focus
		
		for _, win in ipairs(window_list) do
			-- check window drag events
			if Input.pressed('mouse') then
				-- grabbing titlebar
				if mouse_x > win.x and mouse_x < win.x+win.width and mouse_y > win.y and mouse_y < win.y + TITLEBAR_HEIGHT then 
					titlebar_focus = win
				end
				-- touching anywhere in window
				if mouse_x > win.x and mouse_x < win.x + win.width and mouse_y > win.y and mouse_y < win.y + win.height + TITLEBAR_HEIGHT then
					-- put this window on top of others
					if bg_focus == nil or titlebar_focus ~= bg_focus then
						bg_focus = win
					end
				end
			end
			if Input.released('mouse') then 
				win.dragging = false
			end
		end
		
		if titlebar_focus and titlebar_focus == bg_focus then 
			-- grabbing titlebar
			titlebar_focus.dragging = { x = mouse_x-titlebar_focus.x, y = mouse_y-titlebar_focus.y }
			
			-- put this window on top of others
			for _, window in ipairs(window_list) do 
				window.z = 0
			end
			titlebar_focus.z = 1
			Game.sortDrawables()
			
		elseif bg_focus then
			-- put this window on top of others
			for _, window in ipairs(window_list) do 
				window.z = 0
			end
			bg_focus.z = 1
			Game.sortDrawables()
		end
	end
}

PCWindow = Entity("PCWindow",{
	background_color="black",
	spawn = function(self)
		self.cam_id = "pcwindow-"..self.uuid
		self.cam = Camera(self.cam_id, { auto_use=false, width=self.width, height=self.height })
		self.canvas = Canvas{auto_draw=false}
		self.dragging = false
		
		table.insert(window_list, self)
	end,
	update = function(self, dt)
		-- dragging window
		if self.dragging then 
			self.x = mouse_x - self.dragging.x
			self.y = mouse_y - self.dragging.y
		end
		
		-- window bounds
		if self.x < 0 then self.x = 0 end 
		if self.x + self.width > Game.width then self.x = Game.width - self.width end
		if self.y < 0 then self.y = 0 end 
		if self.y + self.height + TITLEBAR_HEIGHT > Game.height then self.y = Game.height - self.height - TITLEBAR_HEIGHT end
				
		if self.update_fn then 
			self:update_fn(dt)
		end
	end,
	draw = function(self)
		Draw.crop(self.x,self.y,self.width,self.height + TITLEBAR_HEIGHT)
		
		self.canvas:drawTo(function()	
			Camera.attach(self.cam_id)
			
			-- window background
			Draw{
				{'reset'},
				{'color', self.background_color},
				{'rect','fill',0,0,self.width,self.height+TITLEBAR_HEIGHT}
			}
			-- draw contents
			if self.draw_fn then
				Draw.push()		  
				Draw.reset() -- draw at global positions
				self:draw_fn(self.x, self.y + TITLEBAR_HEIGHT)
				Draw.pop()
			end
				 
			Camera.detach() 
		end)
		
		self.canvas.x = self.x
		self.canvas.y = self.y + TITLEBAR_HEIGHT
		self.canvas:draw()
		
		Draw.lineJoin("bevel")
		
		-- window border
		Draw.color(BORDER_COLOR)
		Draw.lineWidth(2)
		Draw.rect("line",0,0,self.width,self.height+TITLEBAR_HEIGHT,2)
		
		-- title bar
		if self.z == 1 then
			Draw.color("blue")
		else 
			Draw.color("gray")
		end
		Draw.rect("line",0,0,self.width,TITLEBAR_HEIGHT,2)
		Draw.rect("fill",0,0,self.width,TITLEBAR_HEIGHT,2)
		
		-- window title
		if self.title then
			Draw.color('white')
			Draw.print(self.title,2,1)
		end
	end
})