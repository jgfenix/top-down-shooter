showFPSOn = true
maxScoreFile = love.filesystem.getWorkingDirectory( ) .. '/data/savedData.txt'
print(maxScoreFile)

function love.load()
	maxScore = nil
	file = io.open(maxScoreFile, "w")
	maxScore = file:read()
	if not maxScore then
		file:write("0")
		maxScore = 0
	end
	print("maxScore="..maxScore)

	custom_font = love.graphics.newFont("fonts/ARCADECLASSIC.TTF", 50) --https://www.1001fonts.com/retro+pixel-fonts.html

	sprites = {}
	sprites.background = love.graphics.newImage("sprites/background.png")
	sprites.bullet = love.graphics.newImage("sprites/bullet.png")
	sprites.player = love.graphics.newImage("sprites/player.png")
	sprites.zombie = love.graphics.newImage("sprites/zombie.png")

	player =  {}
	player.x = love.graphics.getWidth() / 2
	player.y = love.graphics.getHeight() / 2
	player.speed = 180
	player.life = 3
	
	zombies = {}
	bullets = {}

	localScore = 0
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

	spawnZombie()

	for i, z in ipairs(zombies) do
		z.x = z.x + (math.cos(zombiePlayerAngle(z)) * z.speed * dt)
		z.y = z.y + (math.sin(zombiePlayerAngle(z)) * z.speed * dt)

		--colision between zombie and player
		if distanceBetween(z.x, z.y, player.x, player.y) < 30 then
			z.dead =  true
			if player.life > 0 then
				player.life = player.life - 1
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
				if distanceBetween(z.x, z.y, b.x, b.y) < 30 then
					b.dead = true
					z.dead = true
					localScore = localScore + 1
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

function love.mousepressed(x, y, button)
	if button == 1 then -- left
		spawnBullet()
	end 
end

function love.keypressed(key)
	if key == 'escape' then
		print("closing game...")
		love.event.quit()
	end

	if key == 'space' then
		player.gun.dispare()
	end

end

function love.draw()
	love.graphics.draw(sprites.background, 0, 0)

	love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth()/2, sprites.player:getHeight()/2)

	for i, z in ipairs(zombies) do
		love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth()/2, sprites.zombie:getHeight()/2)
	end

	for i, b in ipairs(bullets) do
		love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.5, 0.5, sprites.bullet:getWidth()/2, sprites.bullet:getHeight()/2)
	end

	local lifeOnScreen = love.graphics.newText(custom_font, {{1, 1, 1},  "Life     "..player.life })
    love.graphics.draw(lifeOnScreen, 5, 2)

	local scoreOnScreen = love.graphics.newText(custom_font, {{1, 1, 1},  "Score "..localScore })
    love.graphics.draw(scoreOnScreen, 5, 40)

	if showFPSOn then love.graphics.print("FPS: "..tostring(love.timer.getFPS( )), 5, 90) end

	local scoreOnScreen = love.graphics.newText(custom_font, {{1, 1, 1},  "Last Record "..maxScore })
	love.graphics.draw(scoreOnScreen, 380, 2)
end

function playerMouseAngle()
	return math.pi + math.atan2(player.y - love.mouse.getY(), player.x - love.mouse.getX())
end

function zombiePlayerAngle(z)
	return math.atan2(player.y - z.y, player.x - z.x)
end

function spawnZombie()
	if not zombies or #zombies > 10 then return end
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


	table.insert(zombies, zombie)
end

function spawnBullet()
	bullet = {}
	bullet.x = player.x
	bullet.y = player.y
	bullet.speed = 500
	bullet.direction = playerMouseAngle()
	bullet.dead = false
	table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end