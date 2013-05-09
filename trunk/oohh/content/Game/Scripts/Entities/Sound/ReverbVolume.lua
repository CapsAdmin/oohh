-----------------------------------------------------------------------------------------------
--
--	Reverb entity - to be attached to area 
--	will set specified EAX settings when entering area
-- registers/updates/unregisters Presets and supports blending

ReverbVolume = {
	type = "ReverbVolume",
	
	Editor={
		Model="Editor/Objects/Sound.cgf",
		Icon="ReverbVolume.bmp",
	},
	
	Properties = {
		reverbpresetReverbPreset="",
		OuterRadius=2,
		Environment=1,
		bFullEffectWhenInside=0, --used for Reverb-Morphing
		bEnabled=1,
	},
	bstarted=0,
	sCurrentReverbPresetName="",
}


function ReverbVolume:OnSpawn()
	self:SetFlags(ENTITY_FLAG_CLIENT_ONLY, 0);
end

----------------------------------------------------------------------------------------
function ReverbVolume:OnLoad(table)
  self.bstarted = table.bstarted;
  self.bEnabled = table.bEnabled;
end

----------------------------------------------------------------------------------------
function ReverbVolume:OnSave(table)
  table.bstarted = self.bstarted;
  table.bEnabled = self.bEnabled;
  
end

----------------------------------------------------------------------------------------
function ReverbVolume:OnPropertyChange()

  self:SetSoundEffectRadius(self.Properties.OuterRadius);
	self.bEnabled = self.Properties.bEnabled;
	self.Environment = self.Properties.Environment;
	
	if (self.sCurrentReverbPresetName ~= self.Properties.reverbpresetReverbPreset and self.bstarted == 1) then
		Sound.UnregisterWeightedEaxEnvironment(self.sCurrentReverbPresetName, self.id);
		Sound.RegisterWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id, self.Properties.bFullEffectWhenInside, 0);
		Sound.UpdateWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id, self.fFadeValue);
		self.sCurrentReverbPresetName=self.Properties.reverbpresetReverbPreset;
	end;
	
	--if (self.bEnabled ~= 0) then
	  --if (self.bEnabled ~= 0) then
		  --self:OnEnterNearArea();
		--end
	--else
	  --self:OnLeaveNearArea();
	--end
	
end

----------------------------------------------------------------------------------------
function ReverbVolume:CliSrv_OnInit()
	
	self.bstarted = 0;
	self.sReverbName = "";
	self:NetPresent(0);
	self.inside = 0;
	self.fFadeValue = 0;
	self.Environment = 0;
	self:SetFlags(ENTITY_FLAG_VOLUME_SOUND,0);
	if (self.Initialized) then
		return
	end	
	
	self:SetSoundEffectRadius(self.Properties.OuterRadius);
	self.Initialized=1;
end

----------------------------------------------------------------------------------------
function ReverbVolume:OnShutDown()
end

----------------------------------------------------------------------------------------
function ReverbVolume:RegisterReverb( player )
  --local Preset=ReverbPresetDB[self.Properties.reverbpresetReverbPreset];
 
  -- local test=nil + 1;  -- for testing unless lua debugger works
	--if (Preset) then
	  --System.Log("Register Reverb-Area "..self.Properties.reverbpresetReverbPreset);
	  --System.Log("Preset "..Preset.nEnvironment);
	  if (self.bEnabled == 0 ) then 
			do return end;
		end
	  if (self.bstarted == 0) then
    	Sound.RegisterWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id, self.Properties.bFullEffectWhenInside, 0);
    	self.bstarted=1;
		self.sCurrentReverbPresetName=self.Properties.reverbpresetReverbPreset;
    end;
  --end;
	
end

----------------------------------------------------------------------------------------
function ReverbVolume:UnregisterReverb( player )
	
	-- disable eax, choosing OFF preset	

	--System.Log("Unregister EAX-Area "..self.Properties.reverbpresetReverbPreset);
	--System.Log("bStarted "..tostring(self.bstarted));
	if (self.bstarted ~= 0) then
		Sound.UnregisterWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id);
		self.bstarted = 0;
		self.fFadeValue = 0;
		self.sCurrentReverbPresetName="";
		
	end;

end

----------------------------------------------------------------------------------------
function ReverbVolume:UpdateReverb( player, fFade, fDistSq )
  
  	if (self.bEnabled == 0 or (fFade == 0 and fDistSq == 0)) then 
  		Sound.UnregisterWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id);
  		--System.Log("Update: bStarted "..tostring(self.bstarted));
			self.bstarted = 0;
			do return end;
		end
		
  if (self.Properties.OuterRadius ~= 0) then
  
    --if (self.bstarted == 0) then
      --OnEnterNearArea(player, areaId);
    --end;
    --System.LogToConsole("RV: Update: Dist: "..tostring(fDistSq));
    --System.LogToConsole("RV: Update: new: "..tostring(fFade));
    --System.LogToConsole("RV: Update: old: "..tostring(self.fFadeValue));
    --System.LogToConsole("RV: self-Fade now: "..tostring(fFade));
    --System.LogToConsole("RV: DistSq now: "..tostring(fDistSq));
    
    if (self.inside == 1) then
    --System.LogToConsole("RV: Inside ");
    --System.LogToConsole("RV: FADE inside: "..self.fFadeValue);
    	if (self.fFadeValue ~= fFade) then
    	  self.fFadeValue = math.abs(fFade);
    	  --System.LogToConsole("RV: new Fade not old Fade ");
    		Sound.UpdateWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id, self.fFadeValue);
    		--System.LogToConsole("RV: FADE inside: "..self.fFadeValue);
    	end;
    else
      --System.LogToConsole("RV: outside ");
  		local fLocalFade = 1 - (math.sqrt(fDistSq) / self.Properties.OuterRadius);
  	 	--System.LogToConsole("RV: FADE outside "..fLocalFade);
  	 	if ( fLocalFade > 0) then
    		Sound.UpdateWeightedEaxEnvironment(self.Properties.reverbpresetReverbPreset, self.id, fLocalFade);
    		self.fFadeValue = fLocalFade;
     	end    
    end;

  end

end

----------------------------------------------------------------------------------------
function ReverbVolume:OnMove()
--	local newInsidePos = self:UpdateInSector(self.nBuilding,	self.nSector );
--	self.nBuilding = newInsidePos.x;
--	self.nSector = newInsidePos.y;
end

----------------------------------------------------------------------------------------
ReverbVolume.Server={
	OnInit=function(self)
		self:CliSrv_OnInit()
	end,
	OnShutDown=function(self)
	end,
}

----------------------------------------------------------------------------------------
ReverbVolume.Client={
	OnInit=function(self)
		self:RegisterForAreaEvents(1);
		self:CliSrv_OnInit()
		self:OnMove();
	end,
	OnShutDown=function(self)
	end,
	
	OnBeginState=function(self)
--System.Log("Entering INACTIVE");		
	end,
	

	
	-- OnEnterNearArea = ReverbVolume.OnEnterNearArea,
	--OnEnterArea=ReverbVolume.Client_Inactive_OnEnterArea,
	--OnMove=ReverbVolume.OnMove,
--		OnMove=EAXPresetArea.Client.OnMove,		
	
	OnBeginState=function(self)
--System.Log("Entering ACTIVE");		
		--	System.Log("SetTimer");
--			self:SetTimer(200);
	end,
		--OnMove = function(self)
		--end,
	OnLocalClientEnterNearArea = function(self, player, nAreaID, fFade )
	  ReverbVolume.RegisterReverb(self,player);
	end,
	
	OnLocalClientMoveNearArea = function(self,player,areaId,fFade,fDistsq )
	  ReverbVolume.UpdateReverb(self,player,fFade,fDistsq);
	end,	
	
	OnLocalClientEnterArea = function(self,player,areaId,fFade )
	  self.inside = 1;
	  self.fFadeValue = 0;
	  ReverbVolume.RegisterReverb(self,player);
	  ReverbVolume.UpdateReverb(self,player,fFade,0);
	end,
	
	OnSoundEnterArea = function(self)
	  --self.inside = 1;
	  --self.fFadeValue = 0;
	  --ReverbVolume.RegisterReverb(self,player,areaId);
	  --ReverbVolume.UpdateReverb(self,player,areaId,fDistsq);
	  if (self.bEnabled ~= 0) then
--	    System.LogToConsole("OnSoundEnterArea-Client");
	    -- Sound.RegisterReverbSound()
	  end;
	end,
	
	
	OnLocalClientProceedFadeArea = function(self, player, areaId, fExternalFade)
	  -- fExternalFade holds the fade value which was calculated by an inner, higher priority area
	  -- in the AreaManager to fade out the outer sound dependant on the biggest effect radius of all attached entities
	  
	  if (fExternalFade > 0) then
	  	self.inside = 1;
	  	ReverbVolume.RegisterReverb(self, player);
	  	ReverbVolume.UpdateReverb(self, player, fExternalFade, 0);
	  else
	  	ReverbVolume.UpdateReverb(self, player, 0, 0); -- this forces an un-register of this reverb
	  end
	end,
	
	OnLocalClientLeaveArea = function(self, player, nAreaID, fFade)
		self.inside = 0;
	end,	
	
	OnLocalClientLeaveNearArea = function(self, player, nAreaID, fFade)
	  ReverbVolume.UnregisterReverb(self,player);
	  self.inside = 0;
	end,
	
	OnUnBindThis = function(self)
		--System.LogToConsole("OnUnBindThis-Client");
		ReverbVolume.UnregisterReverb(self,player);
		self.inside = 0;
	end,	
	
		--OnMoveNearArea = function(self)
		--end,
		--OnLeaveNearArea = function(self)
		--end,
		OnEndState=function(self)
--			System.Log("KillTimer");
--			self:KillTimer();
		end,
}

--function ReverbVolume:Event_Radius( sender, fRadius )
  --System.Log( "Ambient Volume :Enable radius");
	
	--self.Properties.OuterRadius = fRadius;
	--self:Stop();
	--BroadcastEvent( self,"Radius" );
--end

function ReverbVolume:Event_Deactivate(sender)
  --System.Log( "Ambient Volume :Enable deactive");
  self.bEnabled = 0;
  --self:Stop();

end

----------------------------------------------------------------------------------------------------
function ReverbVolume:Event_Activate(sender)
  --System.Log( "Ambient Volume :Enable active");
  self.bEnabled = 1;
  --self:OnReset();
	
end

ReverbVolume.FlowEvents =
{
	Inputs =
	{
	  --SoundName = { ReverbVolume.Event_SoundName, "string" },
		--Enable = { ReverbVolume.Event_Enable, "bool" },
		Deactivate = { ReverbVolume.Event_Deactivate, "bool" },
		Activate   = { ReverbVolume.Event_Activate, "bool" },
		--Radius = { ReverbVolume.Event_Radius, "float" },
		--Volume = { ReverbVolume.Event_Volume, "float" },
	},
	Outputs =
	{
	},
}
