local PANEL = {}

PANEL.ClassName = "menuitem"
PANEL.Base = "button"

function PANEL:Initialize()
	self.lbl = aahh.Create("label", self)
	self.img = aahh.Create("image", self)
	self.img:SetResizePanelWithImage(true)
	-- self.img:SetIgnoreMouse(true)
	self.button_down = {}
end

function PANEL:SetText(...)
	self.lbl:SetText(...)
end

function PANEL:SetTexture(...)
	self.img:SetTexture(...)
end

function PANEL:OnDraw()
	self:DrawHook("MenuItemDraw")
end

function PANEL:OnRequestLayout()
	self:LayoutHook("MenuItemLayout")
end
 
aahh.RegisterPanel(PANEL)
 
local PANEL = {}

PANEL.ClassName = "context"
PANEL.Base = "grid"

aahh.GetSet(PANEL, "IconSize", Vec2(16, 16))

function PANEL:Initialize()
	self:SetPos(Vec2(mouse.GetPos()))

	self:SetStackRight(false)
	self:SetSizeToWidth(false)
	self:SetSizeToContent(true)
end

function PANEL:SetIconSize(siz)
	for key, pnl in pairs(self:GetChildren()) do
		if pnl.ClassName == "menuitem" then
			pnl.img:SetSize(siz)
		end
	end
end

function PANEL:AddOption(icon, str, callback)
	local itm = aahh.Create("menuitem", self)
	itm:SetText(str)
	itm:SetTexture(icon)
	itm.img:SetSize(self.IconSize)
	itm:RequestLayout()
	itm.OnPress = function() callback(self) end
	
	self:RequestLayout(true)
end

function PANEL:AddSpace()
	local itm = aahh.Create("panel", self)
	itm:SetHeight(5)
	itm.OnDraw = function(s) s:DrawHook("ContextSpaceDraw", self) end
	self:RequestLayout(true)
end

function PANEL:OnLayoutRequest()
	self:LayoutHook("ContextLayout")
end

function PANEL:OnDraw()
	self:DrawHook("ContextDraw")
end

aahh.RegisterPanel(PANEL)