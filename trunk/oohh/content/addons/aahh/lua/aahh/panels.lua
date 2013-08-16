function aahh.Create(name, parent, pos)
	local pnl = class.Create("panel", name, "base")
	
	if not pnl then return end
	
	for key, val in pairs(pnl) do
		if hasindex(val) and val.Copy then
			pnl[key] = val:Copy()
		end
	end
	
	if pnl.__Initialize then
		pnl:__Initialize()
	end
	
	table.insert(aahh.ActivePanels, 1, pnl)
	pnl.aahh_id = #aahh.ActivePanels
	
	if pnl.Initialize then
		pnl:Initialize()
	end
	
	timer.Simple(0, function()
		if pnl:IsValid() then
			pnl:RequestLayout()
		end
	end)
	
	return pnl, pnl:SetParent(parent, pos)
end

function aahh.RegisterPanel(META, name)
	META.TypeBase = "base"
	class.Register(META, "panel", name)
end

function aahh.GetRegisteredPanels()
	return class.GetAll("panel")
end

function aahh.GetPanel(name)
	return class.Get("panel", name)
end

function aahh.GetPanels()
	for key, pnl in pairs(aahh.ActivePanels) do
		if not pnl:IsValid() then
			aahh.ActivePanels[key] = nil
		end
	end
	return aahh.ActivePanels
end

function aahh.RemoveAllPanels()
	for key, pnl in pairs(aahh.GetPanels()) do
		if pnl:IsValid() then
			pnl:Remove()
		end
	end
	aahh.ActivePanels = {}
end

function aahh.CallPanelHook(name, ...)
	for key, pnl in pairs(aahh.GetPanels()) do
		if pnl[name] then
			pnl[name](pnl, ...)
		end
	end
end

do -- meta
	local PANEL = {}

	PANEL.ClassName = "base"
	PANEL.Internal = true

	function PANEL:__tostring()
		return string.format("%s[%s][%i]", self.Type, self.ClassName, self.aahh_id or 0)
	end
	
	aahh.GetSet(PANEL, "Children")
	aahh.GetSet(PANEL, "Parent")
	
	aahh.GetSet(PANEL, "Pos", Vec2())
	aahh.GetSet(PANEL, "Size", Vec2())
	aahh.GetSet(PANEL, "Padding", Rect())
	aahh.GetSet(PANEL, "Margin", Rect())
	aahh.GetSet(PANEL, "MinSize", Vec2(8,8))
	aahh.GetSet(PANEL, "TrapInsideParent", false)
	aahh.GetSet(PANEL, "Cursor", 1)
	aahh.GetSet(PANEL, "Spacing", 0)
	aahh.GetSet(PANEL, "DockPadding", 1) -- Default padding around all child panels in docking
	aahh.IsSet(PANEL, "Visible", true)
	aahh.IsSet(PANEL, "ObeyMargin", true)
	aahh.IsSet(PANEL, "IgnoreMouse", false)
	aahh.IsSet(PANEL, "AlwaysReceiveMouse", false)

	aahh.GetSet(PANEL, "Skin")
	aahh.GetSet(PANEL, "DrawBackground", true)
	
	function PANEL:__Initialize()
		self.Children = {}
		self.Colors = {}
		self.Parent = NULL
		
		self.Skin = aahh.ActiveSkin
		self:UpdateSkinColors()
	end
			
	do -- colors
		function PANEL:UpdateSkinColors()
			local skin = self.Skin
			if skin and skin.Colors then	
				for key, val in pairs(skin.Colors) do
					self.Colors[key] = self.Colors[key] or val
				end
			end
		end
		
		function PANEL:SetSkin(name)
			self.Skin = aahh.GetSkin(name)
		end
		
		function PANEL:SetSkinColor(key, val)
			self.Colors[key] = aahh.GetSkinColor(val, self.Skin, false)
			self:UpdateSkinColors()
		end
		
		function PANEL:GetSkinColor(key, def)
			self:UpdateSkinColors()
			return self.Colors[key] or aahh.GetSkinColor(key, self.Skin, def)
		end	
	end
	
	do -- orientation
		function PANEL:SetPos(vec)
			vec = type(vec) == "number" and Vec2() + size or typex(vec) == "vec2" and vec or Vec2(0, 0)
			self.Pos = vec
			
			if self.last_pos ~= vec then
				self:CalcTrap()
				self.last_pos = vec
			end
		end

		function PANEL:SetSize(vec)
			vec = type(vec) == "number" and Vec2() + vec or typex(vec) == "vec2" and vec or Vec2(0, 0)
			self.Size = vec
			
			if self.last_size ~= vec then
				self:CalcTrap()
				self:RequestLayout()
				self.last_size = vec
			end
		end

		function PANEL:SetRect(rect)
			if typex(rect) ~= "rect" then return end
			self.Pos = Vec2(rect.x, rect.y)
			self.Size = Vec2(rect.w, rect.h)
			self:RequestLayout()
		end

		function PANEL:GetRect()
			return Rect(self.Pos.x, self.Pos.y, self.Size.w, self.Size.h)
		end

		function PANEL:GetParentMargin()
			return self.Parent and self.Parent.GetMargin and self.Parent:GetMargin() or Rect()
		end

		function PANEL:SetWidth(w)
			self.Size = Vec2(w, self.Size.h)
			self:RequestLayout()
		end

		function PANEL:GetWidth()
			return self.Size.w
		end

		function PANEL:SetHeight(h)
			self.Size = Vec2(self.Size.w, h)
			self:RequestLayout()
		end

		function PANEL:GetHeight()
			return self.Size.h
		end

		PANEL.GetWide = PANEL.GetWidth
		PANEL.GetTall = PANEL.GetHeight

		function PANEL:SetWorldPos(pos)
			local temp = self
			
			for i = 1, 100 do
				local parent = temp:GetParent()
				
				if parent:IsValid() then
					pos = pos - parent:GetPos()
					temp = parent
				else
					break
				end
			end			

			self:SetPos(pos)
		end

		function PANEL:GetWorldPos()
			local pos = self:GetPos()	
			local temp = self
		
			for i = 1, 100 do
				local parent = temp:GetParent()
				
				if parent:IsValid() then
					pos = pos + parent:GetPos()
					temp = parent
				else
					break
				end
			end

			return pos
		end

		do -- z orientation
			aahh.FrontPanel = NULL
			
			function PANEL:IsInFront()
				if self == aahh.World then return false end
				if self == aahh.FrontPanel then return true end
				
				local temp = self
				
				for i = 1, 100 do
					local parent = temp:GetParent()
					
					if parent:IsValid() then
						if parent == aahh.FrontPanel then
							return true
						else
							temp = parent
						end
					else
						break
					end
				end
				
				return false
			end
	
			function PANEL:BringToFront()
				if self == aahh.World then return end
				
				if not self:IsInFront() then

					aahh.FrontPanel = self

					local parent = self:GetParent()
					
					if parent:IsValid() then
						local tbl = parent:GetChildren()
						for key, pnl in pairs(tbl) do
							if pnl == self then
								table.remove(tbl, key)
								table.insert(tbl, pnl)
								break
							end
						end
					end
				end
			end

			function PANEL:MakeActivePanel()
				if aahh.ActivePanel:IsValid() then
					aahh.ActivePanel:OnFocusLost()
				end
				aahh.ActivePanel = self
			end
			
			function PANEL:IsActivePanel()
				return aahh.ActivePanel == self
			end
		end
	end
	
	do -- parenting
		function PANEL:CreatePanel(name, pos)
			return aahh.Create(name, self, pos)
		end
	
		function PANEL:SetParent(var, pos)
			var = var or aahh.World
			if not var:IsValid() then
				self:UnParent()
				return false
			else
				return var:AddChild(self, pos)
			end
		end
		
		function PANEL:GetParent()
			return self.Parent or NULL
		end	
				
		function PANEL:AddChild(var, pos)
			var = var or NULL
			if not var:IsValid() then 
				return
			end
			
			if self == var or var:HasChild(self) then 
				return false 
			end
		
			var:UnParent()
		
			var.Parent = self

			pos = pos or #self:GetChildren() + 1
			table.insert(self:GetChildren(), pos, var)
			
			
			var:OnParent(self)
			self:OnChildAdd(var)
			
			var:RequestLayout()
			self:RequestLayout()

			return pos
		end

		function PANEL:HasParent()
			return self.Parent:IsValid()
		end

		function PANEL:HasChildren()
			return #self:GetChildren() > 0
		end

		function PANEL:HasChild(pnl)
			for key, child in pairs(self:GetChildren()) do
				if child == pnl or child:HasChild(pnl) then
					return true
				end
			end
			return false
		end
		
		function PANEL:RemoveChild(var)
			local children = self:GetChildren()
		
			for key, pnl in pairs(children) do
				if pnl == var then
					children[key] = nil
					return
				end
			end
			
			self.Children = children
		end

		function PANEL:GetRootPanel()
			
			if not self:HasParent() then return self end
		
			local temp = self
			
			for i = 1, 100 do
				local parent = temp:GetParent()
				
				if parent:IsValid() and parent ~= aahh.World then
					temp = parent
				else
					break
				end
			end
			
			return self
		end
		
		function PANEL:IsVisibleEx()
			if self:IsVisible() == false then return false end
			
			local temp = self
			
			for i = 1, 100 do
				local parent = temp:GetParent()
				
				if parent:IsValid() then
					if not parent:IsVisible() then
						return false
					else
						temp = parent
					end
				else
					break
				end
			end
			
			return true
		end

		function PANEL:GetChildren()		
			for key, pnl in pairs(self.Children) do
				if not pnl:IsValid() then
					self.Children[key] = nil
				end
			end

			return self.Children
		end
		
		function PANEL:RemoveChildren()
			for key, pnl in pairs(self:GetChildren()) do
				pnl:Remove()
			end
			self.Children = {}
		end

		function PANEL:UnParent()
			local parent = self:GetParent()
			
			if parent:IsValid() then
				parent:RemoveChild(self)
				self:OnUnParent(parent)
			end			
		end
	end		

	do -- center
		function PANEL:CenterX()
			self:SetPos(Vec2((self.Parent:GetSize().x * 0.5) - (self:GetSize().x * 0.5), self:GetPos().y))
		end

		function PANEL:CenterY()
			self:SetPos(Vec2(self:GetPos().x, (self.Parent:GetSize().y * 0.5) - (self:GetSize().y * 0.5)))
		end

		function PANEL:Center()
			self:CenterY()
			self:CenterX()
		end
	end

	do -- align
		
		function PANEL:Align(vec, off)
			off = off or Vec2()
			
			local padding = self:GetPadding() or Rect()
			local size = self:GetSize() + padding:GetPosSize()
			local centerparent = self:GetParent():GetSize() * vec
			local centerself = size * vec
			local pos = centerparent - centerself
			
			if vec.x == -1 and vec.y == -1 then
				return
			elseif vec.x == -1 then
				self.Pos.y = pos.y + off.y + padding.y
			elseif vec.y == -1 then
				self.Pos.x = pos.x + off.x + padding.x
			else
				self:SetPos(pos + off + padding:GetPos())
			end
			
		end
	end

	do -- fill
		do -- normal
			function PANEL:Fill(left, top, right, bottom)
				self:SetSize(self.Parent:GetSize() - Vec2(right+left, bottom+top))
				self:SetPos(Vec2(left, top))
			end

			-- todo rest ??
		end

		-- do we need this?
		do -- percent
			function PANEL:FillPercent(div)
				div = div or 1

				self:SetPos(self.Parent:GetSize() / div)
				self:SetSize((self.Parent:GetSize() / 2) - (self:GetSize() / 2))
			end

			function PANEL:FillBottomPercent(div, index)
				div = div or 2
				index = math.clamp(math.abs(index or 1), 1, div)

				self:SetPos(self.Parent:GetSize() / Vec2(1, div))
				self:SetSize(self:GetSize() * Vec2(0, -index + div))
			end

			function PANEL:FillTopPercent(div, index)
				div = div or 2
				index = index or 1
				self:FillBottom(div, -index + div + 1)
			end

			function PANEL:FillRightPercent(div, index)
				div = div or 2
				index = math.clamp(math.abs(index or 1), 1, div)

				self:SetPos(self.Parent:GetSize() / Vec2(div, 1))
				self:SetSize(self.Parent:GetSize() - (self:GetSize() * Vec2(index, 1)))
			end

			function PANEL:FillLeftPercent(div, index)
				div = div or 2
				index = index or 1

				self:FillRight(div, -index + div + 1)
			end
		end

		do -- axis specific (TODO)
			function PANEL:AddRightWidth(w, prev_w)
				self:SetSize(Vec2(prev_w + w, self:GetSize().h))
			end

			function PANEL:AddBottomHeight(h, prev_h)
				self:SetSize(Vec2(self:GetSize().w, prev_h + h))
			end

			--function PANEL:AddLeftWidth(w, prev_w, prev_x)
				--self:SetPos(Vec2(prev_x - prev_w, self:GetPos().y))
				--self:SetSize(Vec2(prev_x - w + prev_w, self:GetSize().h))
			--end

			--function PANEL:AddTopHeight(h, prev_h, prev_y)
				--self:SetPos(Vec2(self:GetPos().x, prev_h + h))
				--self:SetSize(Vec2(self:GetSize().w, prev_y - h + prev_h))
			--end
		end
	end

	do -- dock
		
		-- wrapped
		
		function PANEL:Undock()
			self:Dock()
		end
		
		function PANEL:Dock(loc)
			if not loc then
				self.DockInfo = nil
			end
			if type(loc) ~= "string" then return end
						
			self.DockInfo = string.lower(loc)
			self:RequestLayout()
		end
		
		function PANEL:DockLayout(um)		
			self.SKIP_LAYOUT = true
			
			local dpad = self.DockPadding or Rect(1, 1, 1, 1)-- Default padding between all panels
			local margin = self.Margin or Rect()
			
			local x = margin.x
			local y = margin.y
			local w = self:GetWidth() - x - margin.w
			local h = self:GetHeight() - y - margin.h
			
			local area = Rect(x, y, w, h)
			
			-- Fill [CenterX CenterY] Left Right Top Bottom
			
			local fill, left, right, top, bottom
			local pad
			
			-- Grab one of each dock type
			for _, pnl in ipairs(self:GetChildren()) do
				if pnl.DockInfo then
					if not fill and pnl.DockInfo == "fill" then
						fill = pnl
					end
					if not left and pnl.DockInfo == "left" then
						left = pnl
					end
					if not right and pnl.DockInfo == "right" then
						right = pnl
					end
					if not top and pnl.DockInfo == "top" then
						top = pnl
					end
					if not bottom and pnl.DockInfo == "bottom" then
						bottom = pnl
					end
				end
			end
			
			if top then
				pad = top:GetPadding() + dpad
				
				top:SetPos(area:GetPos() + pad:GetPos())
				top:SetWidth(area.w - pad:GetXW())
				area.y = area.y + top:GetHeight() + pad:GetYH()
				area.h = area.h - top:GetHeight() - pad:GetYH()
			end
			
			if bottom then
				pad = bottom:GetPadding() + dpad
				
				bottom:SetPos(area:GetPos() + Vec2(pad.x, area.h - bottom:GetHeight() - pad.h))
				bottom:SetWidth(w - pad:GetXW())
				area.h = area.h - bottom:GetHeight() - pad:GetYH()
			end
			
			if left then
				pad = left:GetPadding() + dpad
				
				left:SetPos(area:GetPos() + pad:GetPos())
				left:SetHeight(area.h - pad:GetYH())
				area.x = area.x + left:GetWidth() + pad:GetXW()
				area.w = area.w - left:GetWidth() - pad:GetXW()
			end
			
			if right then
				pad = right:GetPadding() + dpad
				
				right:SetPos(area:GetPos() + Vec2(area.w - right:GetWidth() - pad.w, pad.y))
				right:SetHeight(area.h - pad:GetYH())
				area.w = area.w - right:GetWidth() - pad:GetXW()
			end
			
			if fill then
				pad = fill:GetPadding() + dpad
				
				fill:SetPos(area:GetPos() + pad:GetPos())
				fill:SetSize(area:GetSize() - pad:GetPosSize())
			end
							
			self.SKIP_LAYOUT = false
		end

		function PANEL:DockHelper(pos, offset) -- rename this function
			offset = offset or 0

			local siz = self:GetSize()

			if
				(pos.y > 0 and pos.y < offset) and -- top
				(pos.x > 0 and pos.x < offset) -- left
			then
				return "TopLeft"
			end

			if
				(pos.y > 0 and pos.y < offset) and -- top
				(pos.x > siz.w - offset and pos.x < siz.w) -- right
			then
				return "TopRight"
			end


			if
				(pos.y > siz.h - offset and pos.y < siz.h) and -- bottom
				(pos.x > 0 and pos.x < offset) -- left
			then
				return "BottomLeft"
			end

			if
				(pos.y > siz.h - offset and pos.y < siz.h) and -- bottom
				(pos.x > siz.w - offset and pos.x < siz.w) --right
			then
				return "BottomRight"
			end

			--

			if pos.x > 0 and pos.x < offset then
				return "Left"
			end

			if pos.x > siz.w - offset and pos.x < siz.w then
				return "Right"
			end

			if pos.y > siz.h - offset and pos.y < siz.h then
				return "Bottom"
			end

			if pos.y > 0 and pos.y < offset then
				return "Top"
			end

			return "Center"
		end
	end

	function PANEL:IsWorldPosInside(a)
		local b, s = self:GetWorldPos(), self:GetSize()
		
		if
			a.x > b.x and a.x < b.x + s.w and
			a.y > b.y and a.y < b.y + s.h
		then
			return true
		end

		return false
	end

	function PANEL:GetMousePos()
		local pos = Vec2(mouse.GetPos())

		if self:IsWorldPosInside(pos) then
			return pos - self:GetWorldPos()
		end

		return Vec2()
	end
	
	function PANEL:CallEvent(event, ...)
		for key, pnl in npairs(self:GetChildren()) do
			local args = {pnl:CallEvent(event, ...)}
			if args[1] == true then
				return unpack(args)
			end
		end
		
		if self[event] then
			local args = {self[event](self, ...)}
			if args[1] == true then
				return unpack(args)
			end
		end
	end
	
	function PANEL:GetNextSpace()
		
		local children = self:GetChildren()
		
		local width = 0
		local height = 0
		
		for _,child in ipairs(children)do
			local x = child:GetPos().x + child:GetSize().w + child:GetPadding().w
			local y = child:GetPos().y + child:GetSize().h + child:GetPadding().h
			width = math.max(width, x)
			height = math.max(height, y)
		end
		
		return Vec2(width, height)
	end
	
	function PANEL:GetNextSpaceX()
		
		local children = self:GetChildren()
		
		local width = 0
		
		for _,child in ipairs(children)do
			local x = child:GetPos().x + child:GetSize().w + child:GetPadding().w
			width = math.max(width, x)
		end
		
		return width
	end
	
	function PANEL:GetNextSpaceY()
		
		local children = self:GetChildren()
		
		local height = 8
		
		for _,child in ipairs(children)do
			local y = child:GetPos().y + child:GetSize().h + child:GetPadding().h
			height = math.max(height, y)
		end
		
		return height
	end
	
	function PANEL:SizeToContents(offx, offy)
		local offset = Vec2(offx or 0, offy or 0)
		
		self:SetSize(self:GetNextSpace() + self:GetMargin():GetSize() + offset)
	end
	
	function PANEL:SizeToContentsX(off)
		self:SetWidth(self:GetNextSpaceX() + self:GetMargin().w + off)
	end
	
	function PANEL:SizeToContentsY(off)
		self:SetHeight(self:GetNextSpaceY() + self:GetMargin().h + off)
	end
	
	function PANEL:AppendToRight(offset)
		offset = offset or 0
		self.Pos.x = self.Parent:GetNextSpaceX()+offset
	end
	
	function PANEL:AppendToBottom(offset)
		offset = offset or 0
		self.Pos.y = self.Parent:GetNextSpaceY()+offset
	end
	
	function PANEL:KeyInput(key, press)
		if self:IsActivePanel() then
			return true, self:OnKeyInput(key, press)
		end
	end

	function PANEL:CharInput(key, press)
		if self:IsActivePanel() then
			return true, self:OnCharInput(key, press)
		end
	end

	function PANEL:CalcTrap()
		self.SKIP_LAYOUT = true
		
		local parent = self:GetParent()
		
		if parent:IsValid() then
			local pad = self:GetSkinVar("Padding", 1)
			pad = 0
			
			if self.ObeyMargin then
				local psize = parent:GetSize()
				local m = self:GetParentMargin()

				if m.w ~= 0 then
					self.Size.w = math.min(self.Size.w, psize.w - m.w)
					self.Size.h = math.min(self.Size.h, psize.h - m.h)
				end
			end
			
			if self.TrapInsideParent or parent == aahh.World then
				local psize = parent:GetSize()

				self.Pos.x = math.clamp(self.Pos.x, pad, (psize.w - self.Size.w) - (pad * 2))
				self.Pos.y = math.clamp(self.Pos.y, pad, (psize.h - self.Size.h) - (pad * 2))
				
				self.Size.w = math.clamp(self.Size.w, self.MinSize.w, psize.w - pad)
				self.Size.h = math.clamp(self.Size.h, self.MinSize.h, psize.h - pad)
			end
		end
				
		self.SKIP_LAYOUT= false
	end
			
	function PANEL:SetVisible(b)
		self.Visible = b
		
		if b ~= self.Visible then
			if b then
				self:OnShow()
			else
				self:OnHide()
			end
		end
		
		if self:IsInFront() then
			aahh.FrontPanel = NULL
		end
	end
	
	function PANEL:VisibleInsideParent()
		local parent = self:GetParent()
		
		if parent:IsValid() then
			local a = self:GetPos()
			local b = self:GetSize()
			local c = parent:GetSize()
			return 	
				a.x > -b.w and
				a.y > -b.h and
				a.x < c.w and
				a.y < c.h
		end
		
		return true
	end
	
	function PANEL:Draw()		
		
		if self:IsVisibleEx() and self:VisibleInsideParent() then
			self:Think()
			self:Animate()

			aahh.StartDraw(self)
				self:OnDraw(self:GetSize())
				self:OnPostDraw(self:GetSize())
			aahh.EndDraw(self)

			if not self.HideChildren then
				for key, pnl in pairs(self:GetChildren()) do
					pnl:Draw()
				end
			end
		end
	end
		
	function PANEL:CalcCursor()	end
	
	function PANEL:Think()
		if self.LayMeOut then
			self:RequestLayout(true)
		end

		local mousepos = Vec2(mouse.GetPos())
				
--		if self.OnMouseMove then
			-- Check if the mouse has moved
			if not self.lastmousepos or self.lastmousepos ~= mousepos then
				self.lastmousepos = mousepos
				-- Get local position
				local localpos = mousepos - self:GetWorldPos()
				
				-- Check if it is in panel
				if
					localpos.x > 0 and localpos.y > 0 and
					localpos.x < self:GetWidth() and
					localpos.y < self:GetHeight() 
				then				
					-- Make a call
					self:OnMouseMove(localpos, true)
					
					if not self.mouse_entered then
						self:OnMouseEntered(localpos)
						self.mouse_entered = true
					end
					
					if self:GetCursor() ~= 1 then
						aahh.HoveringPanel = self
					end
				else
					if aahh.HoveringPanel == self then
						aahh.HoveringPanel = NULL
					end
					
					self:OnMouseMove(localpos, false)
					
					if self.mouse_entered then
						self:OnMouseLeft(localpos)
						self.mouse_entered = false
					end
				end
			end
		--end
				
		self:OnThink()
	end
	
	do -- animation
		function PANEL:Animate()
			if not self.Animations then return end
			
			local delta = math.min(FT, 1)
			local data = self.Animations
			for key, data in pairs(self.Animations) do
				if data and data.begin < os.clock() then
					data.current = data.current + (data.speed * delta) ^ data.exp
					
					if data.calc(self, data.current, data) == true then
						data.calc(self, 1, data)
						self.Animations[key] = nil
						if data.done_func then
							data.done_func(self, data)
						end
					end
				end
			end
		end
		
		local function ADD_ANIM(name, original, callback)
			PANEL[name] = function(self, target, speed, delay, exp, done_func)
				speed = speed or 0.25
				delay = delay or 0
				exp = exp or 1
				
				self.Animations = self.Animations or {}
				self.Animations[name] = 
				{
					begin = os.clock() + delay,
					current = 0,
					original = original(self),
					calc = callback,
					done_func = done_func,
					
					target = target, 
					speed = speed, 
					delay = delay, 
					exp = exp
				}
			end
		end
		 
		ADD_ANIM(
			"MoveTo",
			function(self) 
				return self:GetPos() 
			end, 
			function(self, lerp, data) 
				self:SetPos(data.original:Lerp(lerp, data.target))
				return lerp > 1
			end
		)
		ADD_ANIM(
			"SizeTo",
			function(self) 
				return self:GetSize() 
			end, 
			function(self, lerp, data) 
				self:SetSize(data.original:Lerp(lerp, data.target)) 
				return lerp > 1
			end
		)
		
		function PANEL:RectTo(rect, ...)
			self:MoveTo(Vec2(rect.x, rect.y), ...)
			self:SizeTo(Vec2(rect.w, rect.h), ...)
		end
		
		function PANEL:ExpandLocallyTo(rect, ...)
			local pos = Vec2(rect.x, rect.y)
			local siz = Vec2(rect.w, rect.h)
			
			self:MoveTo(self:GetPos() + pos, ...)
			self:SizeTo(self:GetSize() + siz * 2, ...)
		end
	end
	
	function PANEL:IsValid()
		return true
	end
	
	do -- events
		function PANEL:Initialize() end
		function PANEL:OnRemove() end
		
		function PANEL:Remove()
			event.Call("OnPanelRemove", self)

			for key, pnl in pairs(self:GetChildren()) do
				pnl:Remove()
			end
			
			self:OnRemove()
			
			self.IsValid = function() return false end
			self.remove_me = true
		end
		
		function PANEL:OnThink()	end
		function PANEL:OnParent() end
		function PANEL:OnChildAdd() end
		function PANEL:OnUnParent() end
		
		function PANEL:OnHide() end
		function PANEL:OnShow() end
		
		function PANEL:OnMouseMove() end
	end
	
	function PANEL:RequestLayout(now)
		if not self:IsVisibleEx() then
			now = false
		end
	
		if not now then
			for i, pnl in pairs(self:GetChildren()) do
				pnl:RequestLayout()
			end
			
			self.LayMeOut = true
			
			return
		end
		
		if self.SKIP_LAYOUT then return end
				
		if now then
			for i, pnl in pairs(self:GetChildren()) do
				pnl:RequestLayout(true)
			end
		end
		
		self:DockLayout()
		self:CalcTrap()
		
		aahh.Stats.layout_count = aahh.Stats.layout_count + 1
		
		if self:HasParent() then 
			self:OnRequestLayout(self.Parent, self:GetSize())
		end
		
		self.LayMeOut = false
	end

	function PANEL:SkinCall(func_name, ...)
		return aahh.SkinCall(self, func_name, self.Skin, ...)
	end
	
	function PANEL:DrawHook(func_name, ...)
		return aahh.SkinDrawHook(self, func_name, self.Skin, ...)
	end

	function PANEL:LayoutHook(func_name, ...)
		return aahh.SkinLayoutHook(self, func_name, self.Skin, ...)
	end

	function PANEL:GetSkinVar(key, def)
		return aahh.GetSkinVar(key, self.Skin) or def
	end

	function PANEL:OnKeyInput(key, press) end
	function PANEL:OnCharInput(key, press) end
	function PANEL:OnMouseInput(key, press, pos) end
	function PANEL:OnMouseEntered(pos) end
	function PANEL:OnMouseLeft(pos) end
	function PANEL:OnThink() end
	function PANEL:OnDraw() end
	function PANEL:OnPostDraw() end
	function PANEL:OnRequestLayout() end
	function PANEL:OnRemove() end
	function PANEL:OnFocusLost() end
	
	aahh.RegisterPanel(PANEL)
end

for path in vfs.Iterate("lua/aahh/panels/", nil, true) do include(path) end
