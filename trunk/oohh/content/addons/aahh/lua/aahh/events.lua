
local white

function aahh.StartDraw(pnl)
	if not pnl:IsValid() then return end
		
	local pos = pnl:GetWorldPos()
	surface.SetTranslation(pos.x, pos.y)
	
	if false and CAPSADMIN then 
		if input.IsKeyDown("space") then return end
		graphics.SetRect(Rect(pos.x, pos.y, pnl:GetSize():Unpack()))
	end
end

function aahh.EndDraw(pnl)	
	if aahh.debug then 
		white = white or Texture(R("textures/defaults/white.dds")):GetId() -- ugh

		local siz = pnl:GetSize()
		
		surface.SetColor(Color(1,1,0,0.5))
		surface.SetTexture(white)
		render.SetState(bit.bor(e.OS_MULTIPLY_BLEND, e.GS_BLSRC_SRCALPHA, e.GS_BLDST_DSTALPHA, e.GS_NODEPTHTEST, e.GS_WIREFRAME))
		surface.DrawTexturedRect(0,0, siz.w, siz.h)
	end

	surface.SetTranslation(0, 0)

	
	if false and CAPSADMIN then 
		if input.IsKeyDown("space") then return end

		graphics.SetRect()
	end
end

function aahh.Draw(delta)
	if aahh.ActiveSkin then
		aahh.ActiveSkin.FT = delta
		aahh.ActiveSkin:Think(delta)
	end
	
	if aahh.World:IsValid() then
		aahh.World:Draw()
	end
	
	if aahh.HoveringPanel:IsValid() then
		mouse.SetCursor(aahh.HoveringPanel:GetCursor())
	else
		mouse.SetCursor(1)
	end
end

function aahh.CallEvent(pnl, name, ...)
	pnl = pnl or aahh.World
	
	return pnl:CallEvent(name, ...)
end

function aahh.MouseInput(key, press, pos)
	local tbl = {}
	
	for _, pnl in pairs(aahh.GetPanels()) do
		if not pnl.IgnoreMouse and pnl:IsWorldPosInside(pos) and pnl:IsVisibleEx() then
			
			if pnl.AlwaysReceiveMouse then
				pnl:OnMouseInput(key, press, pos - pnl:GetWorldPos())
			end
			
			table.insert(tbl, pnl)
		end
	end

	for _, pnl in pairs(tbl) do
		if pnl:IsInFront() then
			return pnl:OnMouseInput(key, press, pos - pnl:GetWorldPos())
		end
	end
	
	for _, pnl in pairs(tbl) do	
		if press then pnl:BringToFront() end
		return pnl:OnMouseInput(key, press, pos - pnl:GetWorldPos())
	end
end

if CRYENGINE3 then
	aahh.ActivePanel = NULL
	
	event.AddListener("PostMenuUpdate", "aahh", function(delta)
		for key, pnl in pairs(aahh.GetPanels()) do
			if pnl.remove_me then
				MakeNULL(pnl)
			end
		end
	
		if aahh.ActivePanel:IsValid() then
			input.DisableFocus = true
		else
			input.DisableFocus = false
		end
		
		if false and CAPSADMIN then
			aahh.Zoom = aahh.Zoom or 1
			
			if input.WasKeyPressed("mwheel_up") then
				aahh.Zoom = aahh.Zoom - 0.1
			elseif input.WasKeyPressed("mwheel_down") then
				aahh.Zoom = aahh.Zoom + 0.1
			end
			
			aahh.Zoom = math.clamp(aahh.Zoom, 0, 1)
			
			local z = aahh.Zoom * 1000
			local x,y = mouse.GetPos()
			local w,h = render.GetScreenSize()

			local rect = Rect(0,0,w,h)
			
			rect:Shrink(z)
			
			render.SetViewport(rect:Unpack())
			--render.SetViewport(0,0,w,h)
		end
		
		surface.StartDraw()
			graphics.Set2DFlags()
			
			event.Call("DrawHUD")
	
			event.Call("PreDrawMenu")
				aahh.Draw(delta)
			event.Call("PostDrawMenu")
		surface.EndDraw()
	end, nospam_print)

	function aahh.KeyInput(key, press)
		if key:find("mouse") or key == "mwheel_down" or key == "mwheel_up" then
			aahh.MouseInput(key, press, Vec2(mouse.GetPos()))
		else
			return aahh.CallEvent(aahh.World, "KeyInput", key, press)
		end
	end
	event.AddListener("OnKeyInput", "aahh", aahh.KeyInput, nospam_print)

	function aahh.CharInput(key, press)
		return aahh.CallEvent(aahh.World, "CharInput", key, press)
	end
	event.AddListener("OnCharInput", "aahh", aahh.CharInput, nospam_print)	
end