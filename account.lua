-- account.lua
-- Thanks for rubenwardy for these code.

account = {
	password = {},
	salt = {},
	counter = 1
}

function account.genSalt()
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

function account.init()
	local file = io.open(minetest.get_worldpath() .. "/password_chest_data.txt", "r")
	if file then
		local data = minetest.deserialize(file:read("*all"))
		file:close()
		if type(data) == "table" then
			account.password = data.password
			account.salt = data.salt
			account.counter = data.counter
		end
	end
end

function account.save()
	local file = io.open(minetest.get_worldpath() .. "/password_chest_data.txt", "w")
	if file then
		file:write(
			minetest.serialize({
				password = account.password,
				salt = account.salt,
				counter = account.counter
			})
		)
		file:close()
	end
end

function account.new(password)
	local salt = account.genSalt()
	account.password[account.counter] = minetest.get_password_hash(salt, password)
	account.salt[account.counter] = salt
	account.counter = account.counter + 1
	account.save()
	return account.counter - 1
end

function account.change(id, old_password, new_password)
	local salt = account.salt[id]
	local old_password_hashed = minetest.get_password_hash(salt, old_password)
	local new_password_hashed = minetest.get_password_hash(salt, new_password)
	if old_password_hashed ~= account.password[id] then
		return false
	end
	account.password[id] = new_password_hashed
	account.save()
	return true
end

function account.check(id, password)
	local salt = account.salt[id]
	local password_hashed = minetest.get_password_hash(salt, password)
	return password_hashed == account.password[id]
end