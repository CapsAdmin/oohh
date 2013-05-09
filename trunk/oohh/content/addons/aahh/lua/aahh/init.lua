if SERVER then 
mouse.ShowCursor(false)
return end

aahh = {}

aahh.ActivePanels = aahh.ActivePanels or {}
aahh.ActivePanel = NULL
aahh.HoveringPanel = NULL
aahh.World = NULL
aahh.Stats = 
{
	layout_count = 0
}

function aahh.Initialize()
	aahh.UseSkin("default")
	
	local WORLD = aahh.Create("base")
		WORLD:SetMargin(Rect()+5)
		
		function WORLD:GetSize()
			self.Size = Vec2(render.GetScreenSize())
			return self.Size
		end
		
		function WORLD:GetPos()
			self.Pos = Vec2(0, 0)
			return self.Pos
		end
		
		WORLD:SetCursor(1)
		
	aahh.World = WORLD
end

aahh.IsSet = class.IsSet

function aahh.GetSet(PANEL, name, var, ...) 
	class.GetSet(PANEL, name, var, ...)
	if name:find("Color") then
		PANEL["Set" .. name] = function(self, color) 
			self[name] = self:HandleColor(color) or var
		end 
	end
end

function aahh.Panic()
	for key, pnl in pairs(aahh.ActivePanels) do
		pnl:Remove()
	end

	aahh.ActivePanels = {}
end

aahh.LayoutRequests = {}

dofile("panels.lua")
dofile("events.lua")
dofile("skin.lua")
dofile("util.lua")

aahh.Initialize()

event.Call("AahhInitialized")

dofile("unit_test.lua")