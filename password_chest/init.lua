-- Mod: Password Chest
-- Created by ynong123

password_chest = {}

-- Thanks for rubenwardy for this function.
function password_chest.genSalt()
	local chars = {}
	for loop = 0, 255 do
		chars[loop + 1] = string.char(loop)
	end
	local str = table.concat(chars)
	local built = {["."] = chars}
	
	local AddLookup = function(charset)
		local substitute = string.gsub(str, "[^" .. charset .. "]", "")
		local lookup = {}
		for loop = 1, string.len(substitute) do
			lookup[loop] = string.sub(substitute, loop, loop)
		end
		built[charset] = lookup
		
		return lookup
	end

	local function srandom(length, charset)
		local charset = charset or "."
		if CharSet == "" then
			return ""
		else
			local result = {}
			local lookup = built[charset] or AddLookup(charset)
			local range = table.getn(lookup)
			for loop = 1, length do
				result[loop] = lookup[math.random(1, range)]
			end
			
			return table.concat(result)
		end
	end

	return srandom(32, "%l%d")
end

local function password_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local formspec =
		"size[8,10]" ..
		default.gui_bg ..
		default.gui_bg_img ..
		default.gui_slots ..
		"list[nodemeta:" .. spos .. ";main;0,0.3;8,4;]" ..
		"list[current_player;main;0,4.85;8,1;]" ..
		"list[current_player;main;0,6.08;8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,4.85) ..
		"button[0,9;8,1;change_password;Change Password]"
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
		meta:set_string("salt", "")
		meta:set_int("locked", 0)
		meta:set_string("owner", "")
		local inv = meta:get_inventory()
		inv:set_size("main", 8 * 4)
	end,
	
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
	    local meta = minetest.get_meta(pos)
		if meta:get_int("locked") == 0 then
		    minetest.show_formspec(player:get_player_name(), "password_chest:setup", 
				"size[8, 4]" ..
				"label[0, 0;Password Chest Setup]" ..
				"pwdfield[0.5,2;7.5,1;password;Password:]" ..
				"button_exit[0,3;2,1;lock;Lock]"
		    )
			minetest.register_on_player_receive_fields(
			    function(player, formname, fields)
			        if formname ~= "password_chest:setup" then
				        return false
				    end
					if fields.password == "" then
						return false
					end
					if fields.password == nil then
						return false
					end
					local salt = password_chest.genSalt()
					meta:set_string("infotext", "Password Chest (owned by " .. player:get_player_name() .. ")")
					meta:set_string("password", minetest.get_password_hash(salt, fields.password))
					meta:set_string("salt", salt)
					meta:set_int("locked", 1)
					meta:set_int("id", id)
					meta:set_string("owner", player:get_player_name())
					minetest.chat_send_player(player:get_player_name(), "Your chest has been locked.")
					return true
			    end
			)
		else
		    minetest.show_formspec(player:get_player_name(), "password_chest:unlock",
			    "size[4, 4]" ..
				"label[0, 0;Unlock Chest]" ..
				"pwdfield[0.5, 2;3.5, 1;password;Password:]" ..
				"button_exit[0, 3;2, 1;open;Open]"
			)
			minetest.register_on_player_receive_fields(
			    function(player, formname, fields)
				    if formname ~= "password_chest:unlock" then
					    return false
					end
					if fields.password == nil then
						return false
					end
					if fields.password == "" then
						return false
					end
					if minetest.get_password_hash(meta:get_string("salt"), fields.password) == meta:get_string("password") then
					    minetest.show_formspec(
						    player:get_player_name(),
							"password_chest:password_chest_formspec",
							password_chest_formspec(pos)
						)
						minetest.register_on_player_receive_fields(
							function(player, formname, fields)
								if formname ~= "password_chest:password_chest_formspec" then
									return false
								end
								if fields.change_password then
									minetest.show_formspec(player:get_player_name(), "password_chest:change_password", 
										"size[5,8]" ..
										"label[0,0;Change Password]" ..
										"pwdfield[0.5,2;4.5,1;old_password;Old Password:]" ..
										"pwdfield[0.5,4;4.5,1;new_password;New Password:]" ..
										"pwdfield[0.5,6;4.5,1;confirm_password;Confirm Password:]" ..
										"button_exit[0,7;2,1;save;Save]"
									)
									minetest.register_on_player_receive_fields(
										function(player, formname, fields)
											if formname ~= "password_chest:change_password" then
												return false
											end
											if fields.old_password == nil then
												return false
											end
											if fields.new_password ~= fields.confirm_password then
												minetest.chat_send_player(player:get_player_name(), "Could not confirm password. Please try again.")
												return false
											end
											if minetest.get_password_hash(meta:get_string("salt"), fields.old_password) ~= meta:get_string("password") then
												minetest.chat_send_player(player:get_player_name(), "Your password is incorrect. Please type again.")
												return false
											end
											meta:set_string("password", minetest.get_password_hash(meta:get_string("salt"), fields.new_password))
											minetest.chat_send_player(player:get_player_name(), "Your chest password has been changed.")
											return true
										end
									)
								end
								return true
							end
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
		local inv = minetest.get_inventory(pos)
		return inv:is_empty() and player:get_player_name() == meta:get_string("owner")
	end,
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		oldmetadata:set_string("infotext", "")
		oldmetadata:set_string("password", "")
		oldmetadata:set_string("salt", "")
		oldmetadata:set_string("owner", "")
		oldmetadata:set_int("locked", 0)
	end
})

minetest.register_craft({
	output = "password_chest:password_chest 1",
	recipe = {
		{"group:wood", "default:mese", "group:wood"},
		{"group:wood", "default:gold_ingot", "group:wood"},
	    {"group:wood", "group:wood", "group:wood"}
	}
})
