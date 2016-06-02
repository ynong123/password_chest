-- Mod: Password Chest
-- Created by: ynong123
local function chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,9]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,4.85)
	return formspec
end

minetest.register_node("password_chest:password_chest", {
    description = "Password Chest",
	tiles = {
	"password_chest_top.png",
	"password_chest_top.png",
	"password_chest_side.png",
	"password_chest_side.png",
	"password_chest_side.png",
	"password_chest_front.png"
	},
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	paramtype2 = "facedir",
	legacy_facedir_simple = true,
	is_ground_content = false,
	on_construct = function(pos)
	    local meta = minetest.get_meta(pos)
		meta:set_string("infotext", "Password Chest (unconfigured)")
		meta:set_string("password", "")
		meta:set_string("locked", "false")
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8 * 4)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
	    local meta = minetest.get_meta(pos)
		if meta:get_string("locked") == "false" then
		    minetest.show_formspec(player:get_player_name(), "password_chest:config", 
		    "size[8, 3]" ..
		"label[0, 0;Please provide a password for your chest:]" ..
		"pwdfield[0.5,1;7.5,1;pwd;]" ..
		"button_exit[0,2;2,1;btnlock;Lock]"
		    )
			minetest.register_on_player_receive_fields(
			    function(player, formname, fields)
			        if formname ~= "password_chest:config" then
				        return false
				    end
					if fields.pwd == nil then
						return false
					end
					if fields.pwd == "" then
					  return false
					end
				    meta:set_string("password", fields.pwd)
					meta:set_string("infotext", "Password Chest (owned by " .. player:get_player_name() .. ")")
					meta:set_string("locked", "true")
					meta:set_string("owner", player:get_player_name())
					minetest.chat_send_player(player:get_player_name(), "Your chest has been locked.")
					return true
			    end
			)
		else
		    minetest.show_formspec(player:get_player_name(), "password_chest:unlock",
			    "size[4, 3]" ..
				"label[0, 0;Password:]" ..
				"pwdfield[0.75, 1;3, 1;pwd;]" ..
				"button_exit[0, 2;2, 1;btnopen;Open]"
			)
			minetest.register_on_player_receive_fields(
			    function(player, formname, fields)
				    if formname ~= "password_chest:unlock" then
					    return false
					end
					if fields.pwd == meta:get_string("password") then
					    minetest.show_formspec(
						    player:get_player_name(),
							"password_chest:password_chest_formspec",
							chest_formspec(pos)
						)
					else
						minetest.chat_send_player(player:get_player_name(), "Your password is incorrect. Please type again.")
					end
					return true
				end
			)
		end
	end,
	can_dig = function(pos, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return inv:is_empty("main") and player:get_player_name() == meta:get_string("owner")
	end,
})

minetest.register_craft({
	output = "password_chest:password_chest 1",
	recipe = {
		{"group:wood", "default:steel_ingot", "group:wood"},
		{"group:wood", "default:mese_crystal", "group:wood"},
	    {"group:wood", "group:wood", "group:wood"}
	}
})