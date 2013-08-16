local PANEL = {}

PANEL.ClassName = "image"

aahh.GetSet(PANEL, "Texture", Texture(R"textures/aahh/c.dds"))
aahh.GetSet(PANEL, "UV")
aahh.GetSet(PANEL, "Color")
aahh.GetSet(PANEL, "Scale", Vec2(1,1))
aahh.GetSet(PANEL, "Filter", true)
aahh.GetSet(PANEL, "ResizePanelWithImage", true)

function PANEL:SizeToContent()
	local siz = Vec2(self.Texture:GetSize()) * self.Scale
	self:SetMinSize(siz)
	self:SetSize(siz)
end

function PANEL:SetTexture(tex)
	self.Texture = tex
	
	if self.ResizePanelWithImage then
		self:SizeToContent()
	end
end

function PANEL:OnDraw()
	self:DrawHook("ImageDraw")
end

function PANEL:OnRequestLayout()
	self:LayoutHook("ImageLayout")
end

aahh.RegisterPanel(PANEL)