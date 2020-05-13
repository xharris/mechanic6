local TITLEBAR_HEIGHT = 16
local BORDER_COLOR = Draw.hexToRgb("#6a717b")

PCWindow = Entity("PCWindow",{
	spawn = function(self)
		self.cam_id = "pcwindow-"..self.uuid
		self.cam = Camera(self.cam_id, { auto_use=false, width=self.width, height=self.height })
		self.canvas = Canvas{auto_draw=false}
		self.dragging = false
		self.background_color = "black"
	end,
	update = function(self, dt)
		-- check window drag events
		if Input.pressed('mouse') and mouse_x > self.x and mouse_x < self.x+self.width and mouse_y > self.y and mouse_y < self.y + TITLEBAR_HEIGHT then 
			self.dragging = { x=mouse_x-self.x, y=mouse_y-self.y }
		end
		if Input.released('mouse') then 
			self.dragging = false 
		end
		-- dragging window
		if self.dragging then 
			self.x = mouse_x - self.dragging.x
			self.y = mouse_y - self.dragging.y
		end
		
		if self.update_fn then 
			self:update_fn(dt)
		end
	end,
	draw = function(self)
		Draw.crop(self.x,self.y,self.width,self.height + TITLEBAR_HEIGHT)
		
		
		if self.draw_fn then 
			self.canvas:drawTo(function()
				Camera.use(self.cam_id, function()
					-- window background
					Draw.color(self.background_color)
					Draw.rect("fill",0,0,self.width,self.height+TITLEBAR_HEIGHT)
					Draw.color()
					self:draw_fn()
				end)
			end)
		end
		
		self.canvas.x = self.x
		self.canvas.y = self.y + TITLEBAR_HEIGHT
		self.canvas:draw()
		
		Draw.lineJoin("bevel")
		
		-- window border
		Draw.color(BORDER_COLOR)
		Draw.lineWidth(2)
		Draw.rect("line",0,0,self.width,self.height+TITLEBAR_HEIGHT,2)
		
		-- title bar
		Draw.color("blue")
		Draw.rect("line",0,0,self.width,TITLEBAR_HEIGHT,2)
		Draw.rect("fill",0,0,self.width,TITLEBAR_HEIGHT,2)
		
		-- window title
		if self.title then
			Draw.color('white')
			Draw.print(self.title,2)
		end
	end
})