local gravity = minetest.settings:get("movement_gravity")
gravity = (gravity and tonumber(gravity) or 9.81) * -1

local charge_speed = minetest.settings:get("bow_full_charge_time")
charge_speed = (charge_speed and tonumber(charge_speed) or 3) / 3

local arrow_lifetime = minetest.settings:get("bow_lifetime_arrow")
arrow_lifetime = arrow_lifetime and tonumber(arrow_lifetime) or 60

local creative_mod = minetest.get_modpath("creative") ~= nil

local bow_load={}

local function drop(itemstack, dropper, pos)
	itemstack:set_name("bow:bow_dropped")
	minetest.item_drop(itemstack, dropper, pos)
	return ""
end

local function drop_loaded(itemstack, dropper, pos)
	local inv = dropper:get_inventory()
	if creative_mod and creative.is_enabled_for(dropper:get_player_name()) then
		if not inv:contains_item("main", "bow:arrow 1") then
			inv:add_item("main", "bow:arrow 1")
		end
		return drop(itemstack, dropper, pos)
	end
	local leftover_bow = drop(itemstack, dropper, pos) -- First drop bow to make space.
	local leftover_arrow = inv:add_item("main", "bow:arrow 1")
	if not leftover_arrow:is_empty() then
		minetest.item_drop(leftover_arrow, dropper, pos)
	end
	return leftover_bow
end

minetest.register_tool("bow:bow", {
	description = "Bow",
	inventory_image = "bow_inv.png",
	wield_scale = {x=2, y=2, z=1},
	on_drop = drop,
	range = 0,
	on_secondary_use = function(itemstack, user, pointed_thing)
		if not user or not user:is_player() then
			return itemstack
		end
		local player_name = user:get_player_name()
		local inv = user:get_inventory()
		local arrow_taken
		if creative_mod and creative.is_enabled_for(player_name) then
			arrow_taken = inv:contains_item("main", "bow:arrow 1")
		else
			arrow_taken = not inv:remove_item("main", "bow:arrow 1"):is_empty()
		end
		if not arrow_taken then
			return itemstack
		end
		bow_load[player_name] = 0
		user:set_physics_override({--[[jump=0.5, gravity=0.25, ]]speed=0.25})
		itemstack:set_name("bow:bow_1")
		return itemstack
	end,
})

minetest.register_tool("bow:bow_1", {
	description = "Bow",
	inventory_image = "bow_1.png",
	wield_scale = {x=2, y=2, z=1},
	groups = {not_in_creative_inventory=1},
	on_drop = drop_loaded,
	range = 0,
})

minetest.register_tool("bow:bow_2", {
	description = "Bow",
	inventory_image = "bow_2.png",
	wield_scale = {x=2, y=2, z=1},
	groups = {not_in_creative_inventory=1},
	on_drop = drop_loaded,
	range = 0,
})

minetest.register_tool("bow:bow_3", {
	description = "Bow",
	inventory_image = "bow_3.png",
	wield_scale = {x=2, y=2, z=1},
	groups = {not_in_creative_inventory=1},
	on_drop = drop_loaded,
	range = 0,
})

minetest.register_tool("bow:bow_dropped", {
	description = "Bow",
	inventory_image = "bow_inv.png",
	groups = {not_in_creative_inventory=1},
	range = 0,
	on_secondary_use = function(itemstack, ...)
		itemstack:set_name("bow:bow")
		return minetest.registered_tools["bow:bow"].on_secondary_use(itemstack, ...)
				or itemstack
	end,
})

minetest.register_craftitem("bow:arrow", {
	description = "Arrow",
	inventory_image = "bow_arrow.png"
})

minetest.register_entity("bow:arrow_ent", {
	physical = false,
	visual = "mesh",
	mesh = "arrow.obj",
	visual_size = {x=1, y=1},
    collisionbox = {-0.1,-0.1,-0.1, 0.1,0.1,0.1},
	textures = {"bow_arrow_uv.png"},
	on_activate = function(self, staticdata, dtime_s)
		if staticdata == "" then
			self.object:remove()
			return
		end
		self.player, self.charge = unpack(staticdata:split(","))
		self.player = minetest.get_player_by_name(self.player)
		self.charge = tonumber(self.charge)
		if not self.player or not self.charge then
			self.object:remove()
			return
		end
		self.start_timer = 0
	end,
	on_step = function(self, dtime)
		local pos = self.object:get_pos()
		local node_def = minetest.registered_nodes[minetest.get_node(pos).name]
		if node_def and node_def.walkable and node_def.drawtype~="nodebox" and self.charge>0 then
			self.object:setvelocity({x=0, y=0, z=0})
			self.object:setacceleration({x=0, y=0, z=0})
			self.charge = 0
			self.timer = 0
		end
		if self.charge == 0 then
			if self.timer >= arrow_lifetime then
				self.object:remove()
				return
			end
			self.timer = self.timer + dtime
			local objects = minetest.get_objects_inside_radius(pos, 3)
			for _,obj in ipairs(objects) do
				if obj:is_player() then
					local inv = obj:get_inventory()
					if creative_mod and creative.is_enabled_for(obj:get_player_name()) then
						if not inv:contains_item("main", "bow:arrow 1") then
							inv:add_item("main", "bow:arrow 1")
						end
					else
						inv:add_item("main", "bow:arrow 1")
					end
					self.object:remove()
					return
				end
			end
		end
		if self.start_timer <= 0.1 then
			self.start_timer = self.start_timer + dtime
		end
		if self.charge > 0 and self.start_timer >= 0.1 then
			local objects = minetest.get_objects_inside_radius(pos, 2)
			for _,obj in ipairs(objects) do
				if obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().name ~= "bow:arrow_ent") then
					obj:punch(self.player, nil, {damage_groups={fleshy=self.charge*2}}, self.object:get_velocity())
					self.object:remove()
					return
				end
			end
		end
	end
})

minetest.register_globalstep(function(dtime)
	for player_name, timer in pairs(bow_load) do
		bow_load[player_name] = timer + dtime
		local player = minetest.get_player_by_name(player_name)
		local button = player:get_player_control().RMB
		local wielditem = player:get_wielded_item()
		local wielditem_name = wielditem:get_name()
		local charge = (wielditem_name:sub(1, 7) == "bow:bow" and (tonumber(wielditem_name:sub(9)) or 0)) or -1
		local inv = player:get_inventory()
		if charge > 0 and not button then -- Shoot.
			local yaw = player:get_look_horizontal()
			local dir = player:get_look_dir()
			local pos = vector.add(player:get_pos(), vector.multiply(dir, 2))
			pos = vector.add(pos, player:get_eye_offset())
			pos.y = pos.y + 1.5
			local obj = minetest.add_entity(pos, "bow:arrow_ent", player_name..","..charge)
			obj:set_yaw(yaw + math.pi/2)
			obj:set_velocity(vector.multiply(dir, charge * 18))
			obj:set_acceleration(vector.new(0, gravity, 0))
			player:set_physics_override({jump=1, gravity=1, speed=1})
			wielditem:set_name("bow:bow")
			wielditem:add_wear(charge*100)
			player:set_wielded_item(wielditem)
			bow_load[player_name]=nil
		elseif charge <= 0 then -- Wielditem was swapped.
			local list = inv:get_list("main")
			local changed = false
			for place, stack in pairs(list) do
				if stack:get_name() == "bow:bow_1" or
						stack:get_name() == "bow:bow_2" or
						stack:get_name() == "bow:bow_3" then
					stack:set_name("bow:bow")
					list[place] = stack
					changed = true
					break
				end
			end
			if changed then
				inv:set_list("main", list)
				if creative_mod and creative.is_enabled_for(player_name) then
					if not inv:contains_item("main", "bow:arrow 1") then
						inv:add_item("main", "bow:arrow 1")
					end
				else
					local leftover_arrow = inv:add_item("main", "bow:arrow 1")
					if not leftover_arrow:is_empty() then
						minetest.item_drop(leftover_arrow, player, player:get_pos())
					end
				end
			end
			player:set_physics_override({jump=1, gravity=1, speed=1})
			bow_load[player_name] = nil
		elseif timer >= charge_speed and charge < 3 then -- Charge the bow.
			bow_load[player_name] = 0
			wielditem:set_name("bow:bow_"..charge+1)
			player:set_wielded_item(wielditem)
		end
	end
end)

minetest.register_craft({
	output = "bow:bow",
	recipe = {
		{"", "default:stick", "farming:cotton"},
		{"default:stick", "", "farming:cotton"},
		{"", "default:stick", "farming:cotton"},
	}
})

minetest.register_craft({
	output = "bow:arrow",
	recipe = {
		{"default:flint"},
		{"default:stick"},
		{"default:paper"},
	}
})
