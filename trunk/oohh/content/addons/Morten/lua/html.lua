utilities.MonitorFileInclude()
 
local scrw, scrh = render.GetScreenSize()

local view = utilities.RemoveOldObject(WebView(scrw, scrh))
local tex = utilities.RemoveOldObject(Texture(scrw, scrh, ETF_A8R8G8B8))

view:SetTransparent(true)

event.AddListener("PostDrawMenu", "html", function()
--	tex:Fill(function(x,y, r,g,b) return x/100%1,1,1,0.25 end)
	print(view:UpdateTexture(tex))
	graphics.DrawTexture(tex, Rect(0, 0, scrw, scrh), nil, nil, true)
end)

print(view:ExecuteJavascriptWithResult([[
	window.onload = function() {
		var h1 = document.createElement("h1");
		h1.appendChild(document.createTextNode("Hello World"));
		document.body.style.background = "red";
		document.body.appendChild(h1);
	};
]]))

