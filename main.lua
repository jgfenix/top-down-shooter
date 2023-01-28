showFPS = true

conf = require "conf"
utils = require "utils"

--globals
currentGameScore = 0
sprites = {}
player =  {}
zombies = {}
bullets = {}

mouseButtons = {
	LEFT = 1
}

gameStates = {
	WAITING   = 0,
	GAMMING   = 1,
	GAME_OVER = 2
}

currentGameState = gameStates.WAITING

custom_font = nil

function love.load()
	love.window.setTitle("Kill the Zombies!")

	custom_font = love.graphics.newFont("fonts/ARCADECLASSIC.TTF", 50) --https://www.1001fonts.com/retro+pixel-fonts.html

	sprites.background = love.graphics.newImage("sprites/background.png")
	sprites.bullet = love.graphics.newImage("sprites/bullet.png")
	sprites.player = love.graphics.newImage("sprites/player.png")
	sprites.zombie = love.graphics.newImage("sprites/zombie.png")

	local cursor = love.mouse.newCursor("sprites/crosshair068.png", 0, 0) --https://kenney.nl/assets/crosshair-pack
	love.mouse.setCursor(cursor)

	player.x = love.graphics.getWidth() / 2
	player.y = love.graphics.getHeight() / 2
	player.speed = 180
	player.life = 2

	maxScore = utils.getMaxScore()
end

function love.update(dt)
	if love.keyboard.isDown('d') and
		player.x + player.speed * dt < love.graphics.getWidth() then
			player.x = player.x + player.speed * dt
	end
	if love.keyboard.isDown('a') and
		player.x - player.speed * dt > 0 then
			player.x = player.x - player.speed * dt
	end
	if love.keyboard.isDown('w') and
		player.y - player.speed * dt > 0 then
			player.y = player.y - player.speed * dt
	end
	if love.keyboard.isDown('s') and
		player.y + player.speed * dt < love.graphics.getHeight() then
			player.y = player.y + player.speed * dt
	end

	if currentGameState == gameStates.WAITING then return end

	if zombies and #zombies < 10 then
		table.insert(zombies, createZombie())
	end

	for i, z in ipairs(zombies) do
		z.x = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
		z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)

		--colision between zombie and player
		if utils.distanceBetween(z.x, z.y, player.x, player.y) < 30 then
			z.dead =  true
			if player.life > 1 then
				player.life = player.life - 1
				player.speed = 300
			else
				player.life = 0
				currentGameState = gameStates.GAME_OVER
			end
		end
	end

	for i, b in ipairs(bullets) do
		b.x = b.x + (math.cos(b.direction) * b.speed * dt)
		b.y = b.y + (math.sin(b.direction) * b.speed * dt)
	end

	--bullets and zombies collision
	if #bullets and #zombies then
		for i, b in ipairs(bullets) do
			for j, z in ipairs(zombies) do
				if utils.distanceBetween(z.x, z.y, b.x, b.y) < 30 then
					b.dead = true
					z.dead = true
					currentGameScore = currentGameScore + 1
					--updating max score
					if maxScore and currentGameScore > maxScore then
						utils.saveMaxScore(currentGameScore)
						maxScore = currentGameScore
					end
					break
				end
			end
		end
	end

	-- removing bullets out of screen or if hits a zombie
	for i=#bullets,1, -1 do
		b = bullets[i]
		if b.x < 0 or b.x > love.graphics.getWidth() or
			b.y < 0 or b.y > love.graphics.getHeight() or b.dead then
				table.remove(bullets, i)
		end
	end

	-- removing dead zombies
	for i=#zombies,1, -1 do
		z = zombies[i]
		if z.dead then
			table.remove(zombies, i)
		end
	end
end

function love.mousepressed(x, y, mouseButton)
	if mouseButton == mouseButtons.LEFT then
		if bullets then
			table.insert(bullets, spawnBullet())
		end

		if currentGameState == gameStates.WAITING then currentGameState = gameStates.GAMMING
		elseif currentGameState == gameStates.GAME_OVER then
			player.life = 2
			player.speed = 180
			currentGameScore = 0
			currentGameState = gameStates.GAMMING
			zombies = {}
			bullets = {}
		end
	end
end

function love.keypressed(key)
	if key == 'escape' then love.event.quit() end
end

function love.draw()
	love.graphics.draw(sprites.background, 0, 0)

	if player.life > 1 then
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)
	else
		love.graphics.setColor(.8, 0, 0, 1)
		love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)
		love.graphics.setColor(1, 1, 1, 1)
	end

	local lifeStr = love.graphics.newText(custom_font, {{1, 1, 1},  "Life     "..player.life })
	love.graphics.draw(lifeStr, 5, 2)

	local scoreStr = love.graphics.newText(custom_font, {{1, 1, 1},  "Score "..currentGameScore })
	love.graphics.draw(scoreStr, 5, 40)

	if showFPS then love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 5, 90) end

	local maxSavedRecordStr = love.graphics.newText(custom_font, {{1, 1, 1},  "Last Record "..maxScore })
	love.graphics.draw(maxSavedRecordStr, 380, 2)

	if currentGameState == gameStates.WAITING then
		local beginMessage = love.graphics.newText(custom_font, {{1, 1, 1},  "Click anywhere to begin!" })
			love.graphics.draw(beginMessage, 100, love.graphics.getHeight()/2 - love.graphics.getHeight()/3)
		return
	end

	if currentGameState == gameStates.GAME_OVER then
		local gameOverMessage = love.graphics.newText(custom_font, {{1, 0, 0},  "GAME OVER!" })
			love.graphics.draw(gameOverMessage, 24, love.graphics.getHeight()/2 - love.graphics.getHeight()/3, nil, 3, 3)

		local beginMessage = love.graphics.newText(custom_font, {{1, 1, 1},  "Click anywhere to begin!" })
			love.graphics.draw(beginMessage, 100, love.graphics.getHeight()/2.5)
		return
	end

	for i, z in ipairs(zombies) do
		love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
	end

	for i, b in ipairs(bullets) do
		love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, 0.5, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
	end

end

function playerMouseAngle()
	return math.pi + math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX())
end

function zombiePlayerAngle(z)
	return math.atan2(player.y - z.y, player.x - z.x)
end

function createZombie()
	math.randomseed(love.timer.getTime())

	local zombie = {}
	zombie.speed = 50
	zombie.dead = false

	local side = math.random(1, 4) --four sides of scren
	if side == 1 then --left side of screen
		zombie.x = -10
		zombie.y = math.random(0, love.graphics.getHeight())
	
	elseif side == 2 then
		zombie.x = 10 + love.graphics.getWidth()
		zombie.y = math.random(0, love.graphics.getHeight())
	
	elseif side == 3 then
		zombie.x = math.random(0, love.graphics.getWidth())
		zombie.y = -10

	elseif side == 4 then
		zombie.x = math.random(0, love.graphics.getWidth())
		zombie.y = 10 + love.graphics.getHeight()
	end

	return zombie
end

function spawnBullet()
	bullet = {}
	bullet.x = player.x
	bullet.y = player.y
	bullet.speed = 500
	bullet.direction = playerMouseAngle()
	bullet.dead = false

	return bullet
end