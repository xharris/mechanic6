local win, list_appliance

WindowAppliance = callable {
	__call = function()
		if window then return end
		
		local cfg_os = Config("os")
		local os_margin = cfg_os:get("margin")
		
		-- window
		win = UI.Window{
			x = os_margin, y = os_margin,
			width = 320, height = 240,
			title = "congo_appliance_rootkit.exe",
			background_color = "white",
		}
		
		win:add(list_appliance)
		
		-- appliance list 
		list_appliance = UI.List{
			width = 320, height = 240 - UI.titlebar_height
		}
		win = UI.Window{
			x = os_margin, y = os_margin,
			width = 320, height = 240,
			title = "congo_appliance_rootkit.exe",
			background_color = "white",
		}
		win:add(list_appliance)
		
		-- add appliances to the list + events
		appliances = HouseMonitor.getEntityInfo("Appliance")
		list_appliance:addItems(appliances, 'map_tag')
		list_appliance:on("enter", function(item)
			-- highlight all the appliances that match item name
			local ent = Appliance.get(item)
			if ent then 
				ent.hovered = true
			end
		end)
		list_appliance:on("leave", function(item)
			-- stop highlighting these items
			local ent = Appliance.get(item)
			if ent then 
				ent.hovered = false
			end
		end)
		list_appliance:on("click", function(item)
			local ent = Appliance.get(item)
			if ent then
				ent:activate()
				list_appliance.color[item] = {"green", "white"}
				-- give the list item a different color
				-- while the appliance is active
				ent:on("finish", function()
					list_appliance.color[item] = nil
					return true
				end)
			end
		end)
	end
}