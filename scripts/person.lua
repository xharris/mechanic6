Image.animation("son.png", animation_info("son"))

Person = Entity("person",{
	z = 100,
	align = 'center',
	setup = function(self, args, spawn_args)
		if spawn_args.name then 
			args.animations = { spawn_args.name.."_stand", spawn_args.name.."_walk", spawn_args.name.."_dance" }
		end
	end,
	spawn = function(self)
		if Game.main_map then
			Game.main_map:addEntity(self, "entities")
		end
	end,
	setAnimation = function(self, name)
		self.animation = self.name.."_"..name
	end,
	moveTo = function(self, name)
		if Game.main_map then 
			local path = Game.main_map:getPaths("walk_path", "entities")[1]
			path:go(self, { speed=30, target={ tag=name } })
		end
	end,
	update = function(self, dt)
		if self.is_pathing then 
			self:setAnimation("walk")
			self.scalex = self.is_pathing.direction.x
		else 
			self:setAnimation("stand")
		end	
	end
})
