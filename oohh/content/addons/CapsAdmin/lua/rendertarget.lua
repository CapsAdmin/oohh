local SIZE = Vec2(128, 128)
local tex = Texture(SIZE.w, SIZE.h, true)

local function UpdateRenderTarget()
	local old_view = Rect(render.GetViewport())
	surface.StartDraw()	
	render.SetRenderTarget(tex)
	--render.SetViewport(0, 0, SIZE.w, SIZE.h)
	
		graphics.DrawRect(Rect(0, 0, SIZE), Color(0,0,0,0.5))
		render.Clear(Color(1, 0, 0, 1))
	
		local T = os.clock()
				
		surface.SetColor(HSVToColor(T*30 % 360, 1, 1))
		surface.DrawFilledRect(SIZE.w/2 + math.sin(T)*SIZE.w/4, SIZE.h/2 + math.cos(T)*SIZE.h/4, 16, 16)
		
	render.SetRenderTarget()
	--render.SetViewport(old_view:Unpack())
	surface.EndDraw()
end

-- update our render target with 10 fps
timer.Create("RT_Update", 1/10, 0, function()
	UpdateRenderTarget()		
end)


-- draw it onto our hud
event.AddListener("PostDrawMenu", "asdf", function()
	graphics.DrawTexture(tex, Rect(Vec2(mouse.GetPos()), Vec2()+128))
end)

-- draw it onto a model
local mat = materials.CreateFromXML("asdf", [[<Material MtlFlags="524288" Shader="Ice" GenMask="100000000" StringGenMask="%TESSELLATION" SurfaceType="mat_default" MatTemplate="" Diffuse="0.50543249,0.50543249,0.50543249" Specular="0,0,0" Emissive="0,0,0" Shininess="10" Opacity="1">
 <Textures>
  <Texture Map="Diffuse" File="textures/defaults/defaultnouvs.dds"/>
 </Textures>
 <PublicParams FresnelPower="4" GlossFromDiffuseContrast="1" FresnelScale="1" GlossFromDiffuseOffset="0" FresnelBias="1" GlossFromDiffuseAmount="0" GlossFromDiffuseBrightness="0.333" IndirectColor="0.25,0.25,0.25"/>
</Material>
]])
mat:SetShader("Illum")
mat:SetTexture(e.EFTT_DIFFUSE, tex)
print(mat:GetShader())

if MULTIPLAYER then
	local rt_ent = utilities.RemoveOldObject(Entity("models/hunter/plates/plate1x1.mdl"))
	rt_ent:SetPos(here)
	rt_ent:SetMaterial(mat)
end