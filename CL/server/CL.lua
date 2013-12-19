-- Configuration
serverColour = Color(255, 200, 200, 200)	--ABGR
joinColour = Color(255, 10, 255, 10)
deathColour = Color(255, 10, 10, 255)
announceColour = Color(255, 0, 255, 255)

-- Globals
homes = {}	-- A Table to store home location
kills = {}	-- Track kills
settings = {}	-- Admin settings
admins = {}

-- Load admin settings
loadAdminSettings = function(path)
	-- Open file
	local file = io.open(path, "r")

	-- For whole file
	while true do
		-- Get next line
		local line = file:read("*line")

		-- While file has lines
		if line != nil then
			-- Get divider
			local s, e = string.find(line, "=")

			-- If found
			if s != nil and e != nil then
				local prefix = string.sub(line, 0, s - 1)
				local suffix = string.sub(line, e + 1)

				-- Any setting!
				if suffix == "true" then
					settings[prefix] = true
				elseif suffix == "false" then
					settings[prefix] = false
				elseif prefix == "admin" then
					table.insert(admins,suffix)
				else
					settings[prefix] = suffix	-- Plain text, such as MOTD
				end

				-- Show in console
				print(prefix, settings[prefix])
			else
				print("ERROR: Parsing line: " .. line)
			end			
		else
			break
		end
	end

	--Finally
	file:close()
end

-- When the module is loaded
onModuleLoad = function(args)
	print("Setting up...")

	-- Load file settings
	loadAdminSettings("settings.cfg")

	-- Setup kills table for all current players
	for player in Server:GetPlayers() do
		kills[player:GetName()] = 0
	end

	-- Notify
	Chat:Broadcast("CL Module Reloaded. Reset your homes!", announceColour)
	print("Module loaded")
end

-- When a player joins the game
onPlayerJoin = function(args)
	local player = args.player
	local name = args.player:GetName()
	
	Chat:Broadcast(name .. " joined the game.", joinColour)
	Chat:Send(player, settings["motd"], serverColour)

	-- Reset kill count
	kills[name] = 0
end

-- Player leaves
onPlayerQuit = function(args)
	Chat:Broadcast(args.player:GetName() .. " left the game.", joinColour)
end

-- When a player chats a message
onPlayerChat = function(args)
	local player = args.player
	local playerName = args.player:GetName()
	local position = args.player:GetPosition()
	local message = args.text

	-- Reset RNG
	math.randomseed(os.time())

	-- Issue help
	if message == "/help" then
		Chat:Send(player, "Available commands:", serverColour) 
		Chat:Send(player, "/help /kill /locate", serverColour)
		Chat:Send(player, "/getvehicle [car, plane, random] or <wikivalue 0 - 91>", serverColour)
		Chat:Send(player, "/getweapon [handgun, revolver, sawnoff, smg, assault, sniper, shotgun, rocket, grenade, sam, bubble, minigun, rocket2]", serverColour)
		Chat:Send(player, "/sethome /gohome ", serverColour)
		Chat:Send(player, "/gotoplayer <name>", serverColour)
		Chat:Send(player, "/scores /about /server /players", serverColour)
		
		return false -- Do not show the chat message
	end	

	-- Kill the player
	if message == "/kill" then
		player:SetHealth(0)
		
		return false
	end

	-- Get the player's location
	if message == "/locate" then
		Chat:Send(player, "XYZ: " .. tostring(player:GetPosition()), serverColour)
		
		return false
	end

	-- Spawn vehicles
	if string.find(message, "/getvehicle") then
		if settings["allowvehicles"] != nil then
			if settings["allowvehicles"] == true then
				createVehicle = function(id, position)
					Vehicle.Create(id, position, player:GetAngle())
				end

				-- Get type
				local type = string.sub(message, 13)

				--Off to the side
				position.x = position.x +  10 -- Northern offset

				-- Shortcut types
				if type == "car" then
					Vehicle.Create(91, position, player:GetAngle())
				elseif type == "plane" then
					Vehicle.Create(81, position, player:GetAngle())
				elseif type == "random" then
					local id = math.random(0, 91)
					Chat:Send(player, "Rolled vehicleId " .. id, serverColour)
					if pcall(createVehicle, id, position) then
						-- Success!
					else	
						Chat:Send(player, "Invalid vehicleId! Try again.", serverColour)
					end
				
				-- Numerical value
				else
					local id = tonumber(type)
					
					-- If it's a valid number
					if id != nil then
						-- It's a valid vehicleId
						if id >= 0 and id <= 91 then
							Vehicle.Create(id, position, player:GetAngle())
						else
							Chat:Send(player, "Valid range is 0 - 91", serverColour)
						end
					end
				end
			else
				Chat:Send(player, "Vehicle spawns are not allowed!", serverColour)
			end
		else
			print("ERROR: 'allowvehicles' setting not set!")
		end

		return false
	end
	
	if string.find(message, "/getweapon") then
		if settings["allowweapons"] != nil then
			if settings["allowweapons"] == true then
				-- Slots 0, 1 or 2 -> Left, Right or Primary
				giveWeapon = function(id, slot, number)
					if slot != 2 then
						if number == 1 then	-- Two-H
							player:GiveWeapon(0, Weapon(id))
						elseif number == 2 then	-- Duel wield!
							player:GiveWeapon(0, Weapon(id))
							player:GiveWeapon(1, Weapon(id))
						end
					else
						player:GiveWeapon(2, Weapon(id))
					end
				end

				-- Get type, then id
				local type = string.sub(message, 12)
				local id = 0
				local slot = 0	-- Primary
				local number = 2 -- Both hands

				-- Turn name into id
				if type == "handgun" then
					id = 2
				elseif type == "revolver" then
					id = 4
				elseif type == "smg" then
					id = 5
				elseif type == "sawnoff" then
					id = 6
				elseif type == "assault" then
					id = 11
					slot = 2
					number = 1
				elseif type == "shotgun" then
					id = 13
					slot = 2
					number = 1
				elseif type == "sniper" then
					id = 14
					slot = 2
					number = 1
				elseif type == "rocket" then
					id = 16
					slot = 2
					number = 1
				elseif type == "grenade" then
					id = 17
				elseif type == "sam" then
					id = 31
					slot = 2
					number = 1
				elseif type == "minigun" then
					id = 26
					slot = 2
					number = 1
				elseif type == "bubble" then
					id = 43
					slot = 2
					number = 1
				elseif type == "rocket2" then
					id = 66
					slot = 2
					number = 2
				end

				-- Give the weapon
				if id > 0 then
					if pcall(giveWeapon, id, slot, number) then
						Chat:Send(player, "Gave weapon: " .. type, serverColour)
					else
						Chat:Send(player, "Invalid weaponId", serverColour)
					end
				else
					Chat:Send(player, "Invalid weapon type. See /help for list.", serverColour)
				end
			else
				Chat:Send(player, "Weapons are not allowed!", serverColour)
			end
		else
			print("ERROR: 'allowweapons' setting not set!")
		end
		
		return false
	end

	-- Teleport to a player
	if string.find(message, "/gotoplayer") then
		if settings["allowteleports"] != nil then
			if settings["allowteleports"] == true then
				-- Get name
				local target = string.sub(message, 13)

				-- Get all players matching target description
				local results = Player.Match(target)

				-- For all matching players, find exact name match
				for index, otherplayer in ipairs(results) do -- May be redundant
					if otherplayer:GetName() == target then
						player:SetPosition(otherplayer:GetPosition())
						Chat:Broadcast("Teleported " .. playerName .. " to " .. otherplayer:GetName(), serverColour)

						return false
					end
				end

				-- No match
				Chat:Send(player, "No match found for player " .. target, deathColour)
			else
				Chat:Send(player, "Teleporting not allowed!", serverColour)
			end
		else
			print("ERROR: 'allowteleports' setting not set!")
		end

		return false
	end

	-- Set player home
	if message == "/sethome" then
		if settings["allowteleports"] != nil then
			if settings["allowteleports"] == true then
				homes[playerName] = player:GetPosition()
				Chat:Send(player, "Home set!", serverColour)
			else
				Chat:Send(player, "Teleporting not allowed!", serverColour)
			end
		else
			print("ERROR: 'allowteleports' setting not set!")
		end

		return false
	end

	--Go home
	if message == "/gohome" then
		if settings["allowteleports"] != nil then
			if settings["allowteleports"] == true then
				if homes[playerName] != nil then
					local pos = homes[playerName]

					-- Stop falling through terrain
					pos.y = pos.y + 5	
					
					-- Go there
					player:SetPosition(pos)
				else
					Chat:Send(player, "You have no home set. Use /sethome to set one.", serverColour)
				end
			else
				Chat:Send(player, "Teleporting not allowed!", serverColour)
			end
		else
			print("ERROR: 'allowteleports' setting not set!")
		end
		
		return false
	end

	-- About
	if message == "/about" then
		Chat:Send(player, "JC2-MP Module 'CL' by Chris Lewis and Adam Taylor", serverColour)
		Chat:Send(player, "Source available at http://github.com/C-D-Lewis/jc2-mp-cl", serverColour)

		return false
	end

	-- Server info
	if message == "/server" then
		Chat:Send(player, settings["serverinfo"], serverColour)

		return false
	end

	-- List players
	if message == "/players" then
		Chat:Send(player, "Current players online:", serverColour)
		for p in Server:GetPlayers() do
			Chat:Send(player, p:GetName(), serverColour)
		end

		return false
	end

	-- Scoreboard
	if message == "/scores" then
		Chat:Send(player, "Current Scores:", serverColour)

		for key, value in pairs(kills) do
			Chat:Send(player, key .. " - " .. value .. " kills", serverColour)
		end

		return false
	end

	--ADMIN COMMANDS
	if message == "!guid" then
		Chat:Send(player, tostring(player:GetSteamId()), serverColour)
		print(tostring(player:GetSteamId()))
		
		return false
	end
	
	return true -- Do show the message
end

-- When a player dies
onPlayerDeath = function(args)
	local playerName = args.player:GetName()
	local reason = args.reason

	local msg = playerName .. " is no more."

	-- If it was murder
	if args.killer then
		local killerName = args.killer:GetName()

		-- Can't get a point from suicide
		if killerName != playerName then
			if reason == 1 then
				msg = killerName .. " smashed " .. playerName .. "."
			elseif reason == 2 then
				msg = killerName .. " filled " .. playerName .. " full o' lead."
			elseif reason == 3 then
				msg = killerName .. " detonated " .. playerName .. "."
			elseif reason == 4 then
				msg = playerName .. " was caught in " .. killerName .. "'s headlights."
			end

			-- Award points
			if kills[killerName] != nil then 
				kills[killerName] = kills[killerName] + 1
			else
				kills[killerName] = 1
			end
		else
			msg = playerName .. " hurt itself in its confusion!"
		end

	-- No killer
	else
		if reason == 1 then
			msg = playerName .. " doesn't even lift."
		elseif reason == 2 then
			msg = playerName .. " ran too fast into a bullet."
		elseif reason == 3 then
			msg = playerName .. " failed at fireworks."
		elseif reason == 4 then
			msg = playerName .. " didn't look both ways."
		end
	end

	if settings["showdeaths"] == true then
		Chat:Broadcast(msg, deathColour)
	end
end

-- Subscribe to game events
Events:Subscribe("PlayerJoin", onPlayerJoin)
Events:Subscribe("PlayerQuit", onPlayerQuit)
Events:Subscribe("PlayerChat", onPlayerChat)
Events:Subscribe("PlayerDeath", onPlayerDeath)
Events:Subscribe("ModuleLoad", onModuleLoad)

--------------- Lua Notes ---------------
-- A comment is preceded by '--'
-- Type is inferred
-- print() can have multiple arguments for long messages
-- '..' is the string concatenation operator
-- ':' is the call operator for objects
-- '.' is the call operator for static methods
-- World instance is DefaultWorld
