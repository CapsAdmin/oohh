
function aahh.StringInput(msg, default, callback, check)
	local frame = aahh.Create("frame")
	frame:SetResizingAllowed(false)
	frame:SetTitle("Text Input Request")
	
	local x = 8
	local y = 8
	
	local label = aahh.Create("label", frame)
	label:SetTrapInsideParent(false)
	label:SetText(msg)
	label:SetPos(Vec2(x, y))
	label:SetSize(Vec2(400, 20))
	label:SizeToText()
	label:SetSize(label:GetSize()+Vec2(0, 4))
	label:AppendToBottom(4)
	
	local textinput = aahh.Create("textinput", frame)
	textinput:SetTrapInsideParent(false)
	textinput:SetText(default)
	textinput:SetPos(Vec2(x, y))
	textinput:SetSize(Vec2(400, 20))
	textinput:AppendToBottom(4)
	
	local textbutton = aahh.Create("textbutton", frame)
	textbutton:SetTrapInsideParent(false)
	textbutton:SetText("Ok")
	textbutton:SetPos(Vec2(x, y))
	textbutton:SetSize(Vec2(400, 20))
	textbutton:AppendToBottom(4)
	
	
	textbutton.OnPress = function(self)
		callback(textinput:GetText())
		frame:Remove()
	end
	
	textinput.OnEnter = function(self)
		local str = textinput:GetText()
		if not check or check(str, self) ~= false then
			callback()
			frame:Remove()
		end
	end
	
	frame:OnRequestLayout()
	frame:SizeToContents(4, 4)
	frame:Center()
end



