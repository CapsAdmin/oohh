local META = {}

META.Type = "Canvas"
META.__index = META

function META:Initialize()
	self.cairo = Cairo(self.size:Unpack())
	self.cairo.tex = Texture(self.size:Unpack())	
	self:Invalidate()
	self:Draw()
end

function META:Remove()
	self.cairo.tex:Remove()
	self.cairo:Remove()
	
	utilities.MakeNULL(self)
end

do -- text
	function META:GetTextSize(font, text)
		font = font or "default"
		text = text or "W"
			font = font:gsub("%.ttf", "")

		self.cairo:SetFontSize(10) 
		self.cairo:SelectFontFace(font)
		return Vec2(self.cairo:TextExtents(text)) * Vec2(1.5, 1) / 10
	end

	e.TEXT_ALIGN_CENTER = Vec2(0,0)

	local function DrawText(self, text, pos, font, size, color, align_normal)
		local cairo = self.cairo
			
		font = font or "default"
		size = size or 12
		color = color or Color(1,1,1,1)
		align_normal = align_normal or Vec2(0,0)
		align_normal = align_normal + Vec2(0.5,1)
				
		if color.a == 0 then return end
		
		font = font:gsub("%.ttf", "")
		
		font = font == "default" and "arial" or font
		
		cairo:SelectFontFace(font)
		cairo:SetSourceRGBA(color:Unpack())

		local w, h = cairo:TextExtents(text)
		pos = pos + (align_normal * Vec2(w,h))
			
		cairo:SetOperator(e.CAIRO_OPERATOR_OVER)
		cairo:MoveTo(pos.x, pos.y+6)
		cairo:SetFontSize(size*1.4) 
		cairo:ShowText(text)  

		cairo:Stroke() 
		
		self:Invalidate()
		
		return pos
	end

	function META:DrawText(text, pos, font, scale, color, align_normal, shadow_dir, shadow_color, shadow_size, shadow_blur)
		if shadow_dir then
			shadow_color = shadow_color or Color(0,0,0, color.a)
			shadow_size = shadow_size or scale
			if shadow_blur and shadow_blur > 0 then
				for i = 1, shadow_blur do
					 
					local alpha_0_1 = (i/shadow_blur)
					local alpha_1_0 = -(i/shadow_blur)+1
					
					local col = shadow_color:Copy()
					col.a = math.clamp(col.a * alpha_1_0 ^ 2.5, 0.004, 1) -- when the alpha is below 0.004 the text becomes white. fix this!
							
					local scale = scale * shadow_size / self:GetTextSize(font, text).h * (alpha_0_1 + 1) ^ 2
							
					DrawText(
						self,
						text, 
						pos, 
						font, 
						scale,
						col, 
						align_normal + ((shadow_dir / scale) * alpha_0_1)
					)
				end
			else
				DrawText(self, text, shadow_dir + pos, font, shadow_size, shadow_color, align_normal)
			end
		end
		return DrawText(self, text, pos, font, scale, color, align_normal)
	end
end

-- rect

do
	local function DrawRect(self, rect, color, roundness, border_size, border_color)
		local cairo = self.cairo
		
		local x,y,w,h = rect:Unpack()
		local r = roundness
		local pi = math.pi/180
		
		
		cairo:NewSubPath()
			cairo:Arc(x + w - r, y + r, r, -90 * pi, 0 * pi)
			cairo:Arc(x + w - r, y + h - r, r, 0 * pi, 90 * pi)
			cairo:Arc(x + r, y + h - r, r, 90 * pi, 180 * pi)
			cairo:Arc(x + r, y + r, r, 180 * pi, 270 * pi)
		cairo:ClosePath()
		
		cairo:SetOperator(e.CAIRO_OPERATOR_OVER)
		
		cairo:SetSourceRGBA(color:Unpack())
		cairo:FillPreserve()
		cairo:SetSourceRGBA(border_color:Unpack())
		cairo:SetLineWidth(border_size)
		
		cairo:Stroke() 
				
		self:Invalidate()
	end

	function META:DrawRect(rect, color, roundness, border_size, border_color, shadow_distance, shadow_color)	
		color = color or Color(1,1,1,1)
		roundness = roundness or 0
		border_size = border_size or 0
		border_color = border_color or Color(1,1,1,1)
		shadow_distance = shadow_distance or Vec2(0, 0)
		shadow_color = shadow_color or Color(0,0,0,0.2)
	
		DrawRect(self, rect, color, roundness, border_size, border_color)
	end
end

function META:Invalidate()
	self.do_invalidate = true
end

function META:Draw(pos, size)
	local cairo = self.cairo

	pos = pos or Vec2()
	size = size or self.size
	
	if self.do_invalidate then	
		cairo:Flush()
		cairo:UpdateTexture(cairo.tex)
		cairo:MarkDirty()
	
		cairo:SetSourceRGBA(0,0,0,0)
		cairo:SetOperator(e.CAIRO_OPERATOR_SOURCE)
		cairo:Fill()
		cairo:Paint()	

		self.do_invalidate = false
	end
	
	graphics.DrawTexture(cairo.tex, Rect(pos, size), Color(1,1,1,1))
end

function Canvas(size)
	local self = setmetatable({}, META)
	
	self.size = size
	self:Initialize()
	
	return self
end

local obj = utilities.RemoveOldObject(Canvas(graphics.GetScreenSize()))

event.AddListener("PostDrawMenu", 1, function()	
	obj:Draw(Vec2(0,0))
end)

function graphics.DrawRect(rect, ...)
	local x,y = surface.GetTranslation()
	rect.x = x
	rect.y = y
	obj:DrawRect(rect, ...)
end

function graphics.DrawText(a, pos, ...)
	
	local x,y = surface.GetTranslation()
	pos.x = x
	pos.y = y
	
	obj:DrawText(a, pos, ...)
end


function graphics.GetTextSize(...)
	return obj:GetTextSize(...)
end

utilities.MonitorFileInclude() 