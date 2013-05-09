directx.Open()

local font = directx.LoadFont("Arial", false, 15)

print(directx.MeasureText(font, "hWWWWello"))

do return end

event.AddListener("PostGameUpdate", "test", function() 
	render.EndFrame()
	render.RenderEnd()
	
	render.BeginFrame()
	render.RenderBegin()
	
	directx.BeginContext()
	directx.Begin()
		directx.SetDrawColor(255, 255, 255, 255)
		directx.RenderText(font, 300, 300, "HHHHHHHHHHHHHHHHHHHHHASIDJASIDJIAS DJASDIJOIODJ IASD")
		local x,y = mouse.GetPos() 
		directx.DrawFilledRect(x,y,100,100)
	directx.End()
	directx.EndContext()
	
	render.EndFrame()
	render.RenderEnd()
	
	render.BeginFrame()
	render.RenderBegin()
end)

utilities.MonitorFileInclude()