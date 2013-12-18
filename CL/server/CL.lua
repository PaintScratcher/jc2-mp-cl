-- Configuration
serverColour = Color(255, 200, 200, 200)	--ABGR
joinColour = Color(255, 10, 255, 10)
deathColour = Color(255, 10, 10, 255)

-- Globals
homes = {} -- A Table to store home location

-- When a player joins the game
onPlayerJoin = function(args)
	local name = args.player:GetName()
	Chat:Broadcast(name .. " joined the game.", joinColour)
end

-- Player leaves
onPlayerQuit = function(args)
	Chat:Broadcast(args.player:GetName() .. " left the game.", joinColour)
end

-- When a player chats a message
onPlayerChat = function(args)
	local player = args.player
	local message = args.text

	-- Issue help
	if message == "/help" then
		Chat:Send(player, "Available commands:", serverColour) 
		Chat:Send(player, "/help /about /kill /locate", serverColour)
		Chat:Send(player, "/getvehicle [car, plane, random] or <wikivalue 0 - 91>", serverColour)
		Chat:Send(player, "/sethome /gohome ", serverColour)
		Chat:Send(player, "/gotoplayer <name>", serverColour)
		
		return false -- Do not show the chat message
	end	

	-- Kill the player
	if message == "/kill" then
		player:SetHealth(0)
--		Chat:Broadcast(player:GetName() .. " chose the easy way out...", deathColour)	-- Conflicts with onPlayerDeath
		
		return false
	end

	-- Get the player's location
	if message == "/locate" then
		Chat:Send(player, "XYZ: " .. tostring(player:GetPosition()), serverColour)
		
		return false
	end

	-- Spawn vehicles
	if string.find(message, "/getvehicle") then
		-- Get type
		local type = string.sub(message, 13)

		-- Shortcut types
		if type == "car" then
			Vehicle.Create(91, player:GetPosition(), player:GetAngle())
		elseif type == "plane" then
			Vehicle.Create(81, player:GetPosition(), player:GetAngle())
		elseif type == "random" then
			Vehicle.Create(math.random(0, 91), player:GetPosition(), player:GetAngle())
		end
		
		-- Numerical value
		else
			local id = tonumber(type)
			
			-- If it's a valid number
			if id != nil then
				-- It's a valid vehicleId
				if id >= 0 and id <= 91 then
					Vehicle.Create(id, player:GetPosition(), player:GetAngle())
				else
					Chat:Send(player, "Valid range is 0 - 91", serverColour)
				end
			end
		end

		return false
	end

	-- Teleport to a player
	if string.find(message, "/gotoplayer") then
		-- Get name
		local target = string.sub(message, 13)

		-- Get all players matching target description
		local results = Player.Match(target)

		-- For all matching players, find exact name match
		for index, otherplayer in ipairs(results) do
			if otherplayer:GetName() == target then
				player:SetPosition(otherplayer:GetPosition())
				Chat:Broadcast("Teleported " .. player:GetName() .. " to " .. otherplayer:GetName(), serverColour)

				return false
			end
		end

		-- No match
		Chat:Send(player, "No match found for player " .. target, deathColour)

		return false
	end

	-- Set player home
	if message == "/sethome" then
		local key = player:GetName()
		homes[key] = player:GetPosition()
		Chat:Send(player, "Home set!", serverColour)

		return false
	end

	--Go home
	if message == "/gohome" then
		local key = player:GetName()
		player:SetPosition(homes[key])
		
		return false
	end

	-- About
	if message == "/about" then
		Chat:Send(player, "JC2-MP Module by Chris Lewis", serverColour)
		Chat:Send(player, "Source available at http://github.com/C-D-Lewis/jc2-mp-cl", serverColour)

		return false
	end

	return true -- Do show the message
end

-- When a player dies
onPlayerDeath = function(args)
	local player = args.player:GetName()
	local reason = args.reason

	local msg = player .. " is no more."

	-- If it was murder
	if args.killer then
		local killer = args.killer:GetName()

		if reason == 1 then
			msg = killer .. " smashed " .. player .. "."
		elseif reason == 2 then
			msg = killer .. " filled " .. player .. " full o' lead."
		elseif reason == 3 then
			msg = killer .. " detonated " .. player .. "."
		elseif reason == 4 then
			msg = player .. " was caught in " .. killer .. "'s headlights."
		end
	else
		if reason == 1 then
			msg = player .. " doesn't even lift."
		elseif reason == 2 then
			msg = player .. " ran too fast into a bullet."
		elseif reason == 3 then
			msg = player .. " failed at fireworks."
		elseif reason == 4 then
			msg = player .. " didn't look both ways."
		end
	end

	Chat:Broadcast(msg, deathColour)
end

-- Subscribe to game events
Events:Subscribe("PlayerJoin", onPlayerJoin)
Events:Subscribe("PlayerQuit", onPlayerQuit)
Events:Subscribe("PlayerChat", onPlayerChat)
Events:Subscribe("PlayerDeath", onPlayerDeath)

--------------- Lua Notes ---------------
-- A comment is preceded by '--'
-- Type is inferred
-- print() can have multiple arguments for long messages
-- '..' is the string concatenation operator
-- ':' is the call operator for objects
-- '.' is the call operator for static methods