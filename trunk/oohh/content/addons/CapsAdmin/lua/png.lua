

local m = hllib.module

function TexturePNG(path)
	path = path:match(".-%.%./(.+)") -- uggghh FIX THI
	
	local data = vfs.Read(path, "b")
	
	local w, h = 16, 16
	
	local tex = Texture(w,h)
			
	local img = tex:GetPixelTable(true)
	for i = 0, tex:GetLength() do
		img[i].r = T*i%255
		img[i].g = (math.sin((i*T)/10000)*1000)%255
		img[i].b = math.cos(i*255)%255
		img[i].a = 90
	end
	tex:SetPixelTable(img)	
	
	return tex
end

local frm = utilities.RemoveOldObject(aahh.Create("frame"))
	frm:SetSize(Vec2()+500)
	frm:Dock("center")
	
local pnl = frm:CreatePanel("image")
	pnl:SetTexture(TexturePNG(R("textures/gui/heart.png")))
	pnl:Dock("fill")