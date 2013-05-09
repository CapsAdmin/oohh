local smoothfps = 0
local color = aahh.GetSkinColor("light")

event.AddListener("PostDrawMenu", "FPS", function()
	local fps = 1 / FT
	if tonumber(tostring(fps)) then 
		smoothfps = smoothfps + ((fps - smoothfps) * FT)
		graphics.DrawText("FPS: "..math.round(smoothfps), Vec2() + 10, nil, nil, color)
	end
end)