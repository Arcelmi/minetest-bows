local gravity = -9.81
if minetest.settings:get("movement_gravity") then
	gravity = minetest.settings:get("movement_gravity")*-1
end
local charge_speed = 1
if minetest.settings:get("bow_full_charge_time") then
	charge_speed = tonumber(minetest.settings:get("bow_full_charge_time"))/3
end
local arrow_lifetime = 60
if minetest.settings:get("bow_lifetime_arrow") then
	arrow_lifetime = tonumber(minetest.settings:get("bow_lifetime_arrow"))
end
	

minetest.register_tool("bow:bow", {
	description = "Bow",
	inventory_image = "bow_inv.png",
	wield_scale = {x=2, y=2, z=1},
	on_drop = function(itemstack, dropper, pos)
		itemstack:set_name("bow:bow_dropped")
		minetest.item_drop(itemstack, dropper, pos)
		return ""
	end,
	range = 0
})

minetest.register_tool("bow:bow_1", {
	description = "Bow",
	inventory_image = "bow_1.png",
	wield_scale = {x=2, y=2, z=1},
	groups = {not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		itemstack:set_name("bow:bow_dropped")
		minetest.item_drop(itemstack, dropper, pos)
		return ""
	end,
	range = 0
})

minetest.register_tool("bow:bow_2", {
	description = "Bow",
	inventory_image = "bow_2.png",
	wield_scale = {x=2, y=2, z=1},
	groups = {not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		itemstack:set_name("bow:bow_dropped")
		minetest.item_drop(itemstack, dropper, pos)
		return ""
	end,
	range = 0
})

minetest.register_tool("bow:bow_3", {
	description = "Bow",
	inventory_image = "bow_3.png",
	wield_scale = {x=2, y=2, z=1},
	groups = {not_in_creative_inventory=1},
	on_drop = function(itemstack, dropper, pos)
		itemstack:set_name("bow:bow_dropped")
		minetest.item_drop(itemstack, dropper, pos)
		return ""
	end,
	range = 0
})

minetest.register_tool("bow:bow_dropped", {
	description = "Bow",
	inventory_image = "bow_inv.png",
	groups = {not_in_creative_inventory=1},
	range = 0
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
	on_step = function(self, dtime)
		if not self.start_timer then self.object:remove() return end
		if not self.charge then self.object:remove() return end
		local pos = self.object:getpos()
		if minetest.registered_nodes[minetest.get_node(pos).name] and minetest.registered_nodes[minetest.get_node(pos).name].walkable and minetest.registered_nodes[minetest.get_node(pos).name].drawtype~="nodebox" and self.charge>0 then
			self.object:setvelocity({x=0, y=0, z=0})
			self.object:setacceleration({x=0, y=0, z=0})
			self.charge = 0
			self.timer = 0
		end
		if self.charge==0 and self.timer>=arrow_lifetime then
			self.object:remove()
		elseif self.charge==0 then
			self.timer = self.timer+dtime
			local objects = minetest.get_objects_inside_radius(pos, 3)
			for _,obj in ipairs(objects) do
				if obj:is_player() then
					local inv = minetest.get_inventory({type="player", name=obj:get_player_name()})
					inv:add_item("main", "bow:arrow")
					self.object:remove()
				end
			end
		end
		if self.start_timer<=0.1 then
			self.start_timer=self.start_timer+dtime
		end
		if self.charge>0 and self.start_timer>=0.1 then
			local objects = minetest.get_objects_inside_radius(pos, 2)
			for _,obj in ipairs(objects) do
				if obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().name ~= "bow:arrow_ent") then
					obj:punch(self.player, nil, {damage_groups={fleshy=self.charge*2}}, self.object:getvelocity())
					self.object:remove()
				end
			end
		end
	end
})
local timer = 0
local bow_load={}

minetest.register_globalstep(function(dtime)
	for _, player in pairs(minetest.get_connected_players()) do
		local wielditem = player:get_wielded_item()
		if wielditem:get_name()=="bow:bow_dropped" then
			wielditem:set_name("bow:bow")
			player:set_wielded_item(wielditem)
		end
		local controls = player:get_player_control()
		timer = timer+dtime
		local inv = minetest.get_inventory({type="player", name=player:get_player_name()})
		if (wielditem:get_name()=="bow:bow_1" or wielditem:get_name()=="bow:bow_2" or wielditem:get_name()=="bow:bow_3") and not controls.RMB then
			local yaw = player:get_look_yaw()
			local dir = player:get_look_dir()
			local pos = vector.add(player:getpos(),{x=dir.x*2, y=dir.y*2+1.5, z=dir.z*2})
			local obj = minetest.add_entity(pos, "bow:arrow_ent")
			obj:setyaw(yaw + math.pi)
			local charge = 1
			if wielditem:get_name()=="bow:bow_1" then
				charge = 1
			elseif wielditem:get_name()=="bow:bow_2" then
				charge = 2
			elseif wielditem:get_name()=="bow:bow_3" then
				charge = 3
			end
			obj:setvelocity({x=dir.x*charge*18,055566667, y=dir.y*charge*18,055566667, z=dir.z*charge*18,055566667})
			obj:setacceleration({x=0, y=gravity, z=0})
			obj:get_luaentity().charge = charge
			obj:get_luaentity().player = player
			obj:get_luaentity().start_timer = 0
			player:set_physics_override({jump=1, gravity=1, speed=1})
			wielditem:set_name("bow:bow")
			wielditem:add_wear(charge*100)
			player:set_wielded_item(wielditem)
			inv:remove_item("main", "bow:arrow 1")
			bow_load[player:get_player_name()]=false
		end
		if bow_load[player:get_player_name()]==true and (wielditem:get_name()~="bow:bow_1" and wielditem:get_name()~="bow:bow_2" and wielditem:get_name()~="bow:bow_3") then
			local list = inv:get_list("main")
			for place, stack in pairs(list) do
				if stack:get_name()=="bow:bow_1" or stack:get_name()=="bow:bow_2" or stack:get_name()=="bow:bow_3" then
					stack:set_name("bow:bow")
					list[place]=stack
					break
				end
			end
			inv:set_list("main", list)
			player:set_physics_override({jump=1, gravity=1, speed=1})
			bow_load[player:get_player_name()]=false
		end 
		if timer>=charge_speed then
			wielditem = player:get_wielded_item()
			timer=0
			if wielditem:get_name()=="bow:bow" and controls.RMB and inv:contains_item("main", "bow:arrow") then
				player:set_physics_override({jump=0.5, gravity=0.25, speed=0.25})
				wielditem:set_name("bow:bow_1")
				bow_load[player:get_player_name()]=true
			elseif wielditem:get_name()=="bow:bow_1" and controls.RMB then
				wielditem:set_name("bow:bow_2")
			elseif wielditem:get_name()=="bow:bow_2" and controls.RMB then
				wielditem:set_name("bow:bow_3")
			end
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
