require("profiler")

local prof = Profiler("time")
prof:Start()

timer.Simple(2, function()
	prof:Stop()
	
	vfs.Write("profiler_report.txt", prof:GetReport(true))
end)