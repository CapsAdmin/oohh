

local PANEL = {}

PANEL.ClassName = "tabbedbutton"
PANEL.Base = "button"

function PANEL:Initialize()
	self.BaseClass.Initialize(self)
	
	self.lbl = aahh.Create("label", self)
	self.lbl:SetIgnoreMouse(true)
		
	self.img = aahh.Create("image", self)
	self.img:SetTexture(Texture(R("textures/gui/heart.png")))
	self.img:SetIgnoreMouse(true)

	self:SetCursor(e.IDC_HAND)
end

function PANEL:GetLabel()
	return self.lbl or NULL
end

function PANEL:SetTextOffset(...)
	self.lbl:SetTextOffset(...)
end

function PANEL:SetAlignNormal(...)
	self.lbl:SetAlignNormal(...)
end

function PANEL:SetTexture(tex)
	self.img:SetTexture(tex)
end

function PANEL:SetText(str)
	self.lbl:SetText(str)
	self.lbl:SizeToText()

	local pad = self:GetSkinVar("Padding", 1)
	
	self:SetSize(self.img:GetSize() + Vec2(self.lbl:GetSize().w + pad * 4, 0)) 
	self:RequestLayout()
end

function PANEL:SetFont(name)
	self.lbl:SetFont(name)
end

function PANEL:SetTextSize(siz)
	self.lbl:SetTextSize(siz)
end

function PANEL:OnDraw()
	self:DrawHook("ButtonDraw")
end

function PANEL:OnRequestLayout()
	self:LayoutHook("TabbedLayout")
end

aahh.RegisterPanel(PANEL)

local PANEL = {}

PANEL.ClassName = "tabbed"

function PANEL:Initialize()
	local bar = aahh.Create("grid", self)
	
	bar:SetSpacing(Vec2())
	bar:SetSizeToHeight(true)
	bar:SetNoPadding(true)
	
	bar.OnDraw = function() end
	self.bar = bar
	
	self.current_tab = NULL
	
	self.tabs = {}
end

local height = 16 + 2

function PANEL:OnRequestLayout()
	self.bar:SetPos(Vec2(0, 0))
	self.bar:SetSize(Vec2(self:GetWidth(), height - 2))
	
	local pnl = self.current_tab
	
	if pnl:IsValid() then
		pnl:SetPos(Vec2(0, height - 1))
		pnl:SetSize(Vec2(self:GetWidth(), self:GetHeight() - height + 1))
	end
end

function PANEL:SelectTab(title)
	local pnl = self.tabs[title]
	
	if not pnl then return end
	
	pnl:SetVisible(true)
	pnl.tabbutton.selected = true
	
	self.current_tab = pnl

	for key, _pnl in pairs(self.tabs) do	
		if pnl ~= _pnl then
			_pnl:SetVisible(false)
			_pnl.tabbutton.selected = false
		end
	end
	
	self:RequestLayout()
end

function PANEL:AddTab(title, fill_pnl)
	
	local btn = aahh.Create("tabbedbutton", self.bar)
		btn:SetText(title)
		btn.OnPress = function() 
			self:SelectTab(title) 
		end
		
		btn.OnDraw = function(s)
			s:DrawHook("TabbedButtonDraw")
		end
		
	local pnl = aahh.Create("panel", self)
		pnl.tabbutton = btn
		pnl:SetVisible(false)
		pnl.OnRemove = function() 
			btn:Remove() 
			self.tabs[title] = nil 
		end
		
	self.tabs[title] = pnl
		
	if fill_pnl then
		local fill_pnl = pnl:CreatePanel(fill_pnl)
		fill_pnl:Dock("fill")
		
		return pnl, fill_pnl
	end
		
	return pnl
end

aahh.RegisterPanel(PANEL)