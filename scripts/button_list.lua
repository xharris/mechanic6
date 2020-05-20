SCROLL_WIDTH = 20
local margin = 4

ButtonList = Entity("ButtonList",{
	scroll_y = 0,
	scroll_max = 0,
	items={},
	entered={}, -- keep track of which item mouse is hovering over
	disabled={},
	color={}, -- { item = color }
	add = function(self, item)
		table.insert(self.items, item)
	end,
	addItems = function(self, list, key)
		for _, item in ipairs(list) do 
			if key then 
				table.insert(self.items, item[key])
			else 
				table.insert(self.items, item)
			end
		end
	end,
	update = function(self, dt)
		self.scroll_max = Math.max(0, ((#self.items) * Draw.textHeight()) - self.height)
		
		local offx, offy, mouse_in_window = 0, 0, true
			
		if self.window then 
			offx, offy = self.window.offx, self.window.offy
		end
		
		local mx, my = mouse_x - offx, mouse_y - offy
		local x, y, w, h
		
		x = margin
		y = -self.scroll_y + margin

		for i, item in ipairs(self.items) do
			w, h = self.width - (margin * 2) - SCROLL_WIDTH, Draw.textHeight()

			if not self.disabled[item] and (not self.window or self.window.hovering) and mx > x and mx < x + w and my > y and my < y + h then 
				-- mouse entered
				if not self.entered[item] then 
					self.entered[item] = true
					self:emit("enter", item)
				end

				-- clicking an item in list
				if Input.pressed('mouse') then
					self:emit("click", item)
				end
			elseif self.entered[item] then
				self.entered[item] = false
				self:emit("leave", item)
			end
			
			y = y + Draw.textHeight(item)
		end
			
		-- controlling the scrollbar with mouse
		if Input.pressed('mouse_rpt') then
			if mx > self.width - (SCROLL_WIDTH + margin) then
				self.scroll_y = Math.prel(0, self.height, my) * self.scroll_max
			end
		end

		-- controlling the scrollbar with wheel
		local wheel = Input('wheel')
		if wheel and wheel.y ~= 0 then 
			self.scroll_y = self.scroll_y - 100 * wheel.y * dt
		end
		
		self.scroll_y = Math.clamp(self.scroll_y, 0, self.scroll_max)
	end,
	draw = function(self, d)
		--Draw.crop(self.x + margin,self.y + margin,self.width - (margin*2),self.height + TITLEBAR_HEIGHT - (margin*2))
		
		local offx, offy = 0, 0
		if self.window then 
			offx, offy = self.window.offx, self.window.offy
		end
		
		local colors
		local x, y, w, h
		local mx, my = mouse_x - offx, mouse_y - offy
			
		-- draw items
		x, y = margin, - self.scroll_y + margin
		for i, item in ipairs(self.items) do
			w, h = self.width - (margin * 2) - SCROLL_WIDTH, Draw.textHeight(item)

			if not self.disabled[item] and (not self.window or self.window.hovering) and (mx > x and mx < x + w and my > y and my < y + h) or self.selected == item then 
				colors = {'blue','white'}
			else
				colors = {'white','black'}
				if self.color[item] then 
					colors = self.color[item]
				end	
			end
			
			Draw{
				{'color',colors[1]},
				{'rect',"fill",x,y,w,h},
				{'color',colors[2]},
				{'print',item,x+2,y+1},
				{'color'}
			}
			
			y = y + Draw.textHeight(item)
		end
		
		-- draw scrollbar
		local line_x = self.width - ((SCROLL_WIDTH + margin)/2)
		local line_y = margin * 2
		local radius = 6
		Draw{
			{'color','gray', 0.25},
			{'line',line_x, line_y, line_x, line_y + self.height}
		}
		if (#self.items) * Draw.textHeight() > self.height then 
			Draw{
				{'color', 'gray'},
				{'circle','fill', line_x, line_y + Math.lerp(0,self.height,self.scroll_y/self.scroll_max), radius}
			}
		end
	end
})