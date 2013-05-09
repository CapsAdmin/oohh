local ent = utilities.RemoveOldObject(Entity("ScriptedEntity"))
ent:SetPos(here)
ent:Spawn()

function ent:OnUpdate(delta, cam, frameid)
	print(xpcall(function()
		--graphics.DisableFlags(true)
			render.SetState(bit.bor(e.GS_BLSRC_SRCALPHA, e.GS_BLDST_ONEMINUSSRCALPHA, e.GS_DEPTHWRITE))
			graphics.Set2DFlags()
			surface.StartDraw()
			--render.SetCamera(cam)
				graphics.DrawRect(Rect(0,0,1000,1000))
			--surface.EndDraw()
		--graphics.DisableFlags(false)
	end, OnError))
end

utilities.MonitorFileInclude()