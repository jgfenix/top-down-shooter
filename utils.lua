local utils = {}

function utils.getMaxScore()
	local maxScore = 0
	local file = io.open(conf.maxScoreFile, "r+")

	if not file then
		file = io.open(conf.maxScoreFile, "w")
		file:write("0")
	else
		maxScore = file:read("*number")
		if not maxScore then
			maxScore = 0
		end
	end
	file:close()

	return maxScore
end

function utils.saveMaxScore(score)
	local file = io.open(conf.maxScoreFile, "w")
	file:write(score)
	file:close()
end

function utils.distanceBetween(x1, y1, x2, y2)
	return math.sqrt((x2-x1)^2 + (y2-y1)^2)
end

return utils