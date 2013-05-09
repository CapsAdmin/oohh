--------------------------------------------------
-- SneakerIdle
--------------------------
--   created: Mikko Mononen 21-6-2006


local Behavior = CreateAIBehavior("Cover2IdleST","HBaseIdle",	
{
		Constructor = function(self,entity)
		--AI.LogEvent(entity:GetName().." Cover2Idle constructor");
		entity:InitAIRelaxed();
		
		-- set combat class
		if ( entity.inventory:GetItemByClass("LAW") ) then
			AI.ChangeParameter( entity.id, AIPARAM_COMBATCLASS, AICombatClasses.InfantryRPG );
		else
			AI.ChangeParameter( entity.id, AIPARAM_COMBATCLASS, AICombatClasses.Infantry );
		end

		if ( entity.AI and entity.AI.needsAlerted ) then
			AI.SetBehaviorVariable(entity.id, "IncomingFire", true);
			entity.AI.needsAlerted = nil;
		end	

		
--		entity:CheckWeaponAttachments();
--		entity:EnableLAMLaser(false);
	end,	
	
	---------------------------------------------
	OnQueryUseObject = function ( self, entity, sender, extraData )
	end,

	---------------------------------------------
	OnEnemySeen = function( self, entity, fDistance, data )
		entity:MakeAlerted();
		entity:TriggerEvent(AIEVENT_DROPBEACON);
		entity.AI.firstContact = true;
		AI.SetBehaviorVariable(entity.id, "Attack", true);
		AI_Utils:CommonEnemySeen(entity, data);

	end,

	---------------------------------------------
	OnNoTarget = function(self,entity,sender)
	end,

	---------------------------------------------
	OnTankSeen = function( self, entity, fDistance )
		if(	AI_Utils:HasRPGAttackSlot(entity) and entity.inventory:GetItemByClass("LAW") 
				and AIBehavior.Cover2RPGAttack.FindRPGSpot(self, entity) ~= nil) then
			entity:Readibility("suppressing_fire",1,1,0.1,0.4);
			AI.SetBehaviorVariable(entity.id, "RpgAttack", true);
		else
			entity:Readibility("explosion_imminent",1,1,0.1,0.4);
			AI.SetBehaviorVariable(entity.id, "AvoidTank", true);
		end
	end,
	
	---------------------------------------------
	OnHeliSeen = function( self, entity, fDistance )
		entity:Readibility("explosion_imminent",1,1,0.1,0.4);
		AI.SetBehaviorVariable(entity.id, "AvoidTank", true);
	end,

	---------------------------------------------
	OnTargetDead = function( self, entity )
		-- called when the attention target died
		entity:Readibility("target_down",1,1,0.3,0.5);
	end,
	
	--------------------------------------------------
	OnNoHidingPlace = function( self, entity, sender,data )
	end,	

	---------------------------------------------
	OnBackOffFailed = function(self,entity,sender)
	end,

	---------------------------------------------
	SEEK_KILLER = function(self, entity)
		AI.SetBehaviorVariable(entity.id, "Threatened", true);
	end,


	---------------------------------------------
	DRAW_GUN = function( self, entity )
		if(not entity.inventory:GetCurrentItemId()) then
			entity:HolsterItem(false);
		end
	end,
	
	---------------------------------------------
	OnEnemyMemory = function( self, entity )
		-- called when the enemy can no longer see its foe, but remembers where it saw it last
	end,
	
	---------------------------------------------
	OnSomethingSeen = function( self, entity )
		-- called when the enemy sees a foe which is not a living player
		entity:Readibility("idle_interest_see",1,1,0.6,1);
		AI_Utils:CheckInterested(entity);
		AI.SetBehaviorVariable(entity.id, "Interested", true);
		AI.ModifySmartObjectStates(entity.id,"UseMountedWeaponInterested");
	end,
	
	---------------------------------------------
	OnThreateningSeen = function( self, entity )
		-- called when the enemy hears a scary sound
		entity:Readibility("idle_interest_see",1,1,0.6,1);
		entity:TriggerEvent(AIEVENT_DROPBEACON);
		if(AI_Utils:IsTargetOutsideStandbyRange(entity) == 1) then
			entity.AI.hurryInStandby = 0;
			AI.SetBehaviorVariable(entity.id, "ThreatenedStandby", true);
		else
			AI.SetBehaviorVariable(entity.id, "Threatened", true);
		end

		AI.ModifySmartObjectStates(entity.id,"UseMountedWeaponInterested");
	end,
	
	---------------------------------------------
	OnInterestingSoundHeard = function( self, entity )
		-- check if we should check the sound or not.
		entity:Readibility("idle_interest_hear",1,1,0.6,1);
		AI_Utils:CheckInterested(entity);
		AI.SetBehaviorVariable(entity.id, "Interested", true);
		AI.ModifySmartObjectStates(entity.id,"UseMountedWeaponInterested");
	end,

	---------------------------------------------
	OnThreateningSoundHeard = function( self, entity, fDistance )
		-- called when the enemy hears a scary sound
		entity:Readibility("idle_alert_threat_hear",1,1,0.6,1);
		entity:TriggerEvent(AIEVENT_DROPBEACON);
		if(AI_Utils:IsTargetOutsideStandbyRange(entity) == 1) then
			entity.AI.hurryInStandby = 0;
			AI.SetBehaviorVariable(entity.id, "ThreatenedStandby", true);
		else
			AI.SetBehaviorVariable(entity.id, "Threatened", true);
		end

		AI.ModifySmartObjectStates(entity.id,"UseMountedWeaponInterested");
	end,

	--------------------------------------------------
	INVESTIGATE_BEACON = function (self, entity, sender)
		entity:Readibility("ok_battle_state",1,1,0.6,1);
		AI.SetBehaviorVariable(entity.id, "Threatened", true);
	end,
		
	--------------------------------------------------
	OnCoverRequested = function ( self, entity, sender)
		-- called when the enemy is damaged
	end,

	---------------------------------------------
	OnDamage = function ( self, entity, sender)
		-- called when the enemy is damaged
		entity:Readibility("taking_fire",1,1,0.3,0.5);
		entity:GettingAlerted();
	end,

	---------------------------------------------
	OnEnemyDamage = function (self, entity, sender, data)
		-- called when the enemy is damaged
		entity:GettingAlerted();
		entity:Readibility("taking_fire",1,1,0.3,0.5);

		-- set the beacon to the enemy pos
		local shooter = System.GetEntity(data.id);
		if(shooter) then
			AI.SetBeaconPosition(entity.id, shooter:GetPos());
		else
			entity:TriggerEvent(AIEVENT_DROPBEACON);
		end

		AI.SetBehaviorVariable(entity.id, "IncomingFire", true);

		-- dummy call to this one, just to make sure that the initial position is checked correctly.
		AI_Utils:IsTargetOutsideStandbyRange(entity);

		AI.SetBehaviorVariable(entity.id, "Hide", true);
	end,

	---------------------------------------------
	OnReload = function( self, entity )
--		entity:Readibility("reloading",1);
		-- called when the enemy goes into automatic reload after its clip is empty
--		AI.LogEvent("OnReload()");
--		entity:SelectPipe(0,"cv_scramble");
	end,


	---------------------------------------------
	OnBulletRain = function(self, entity, sender, data)
		-- only react to hostile bullets.

--		AI.RecComment(entity.id, "hostile="..tostring(AI.Hostile(entity.id, sender.id)));

		if(AI.Hostile(entity.id, sender.id)) then
			entity:GettingAlerted();
			if(AI.GetTargetType(entity.id)==AITARGET_NONE) then
				local	closestCover = AI.GetNearestHidespot(entity.id, 3, 15, sender:GetPos());
				if(closestCover~=nil) then
					AI.SetBeaconPosition(entity.id, closestCover);
				else
					AI.SetBeaconPosition(entity.id, sender:GetPos());
				end
			else
				entity:TriggerEvent(AIEVENT_DROPBEACON);
			end
			entity:Readibility("bulletrain",1,1,0.1,0.4);

			-- dummy call to this one, just to make sure that the initial position is checked correctly.
			AI_Utils:IsTargetOutsideStandbyRange(entity);

			AI.Signal(SIGNALFILTER_GROUPONLY_EXCEPT,1,"INCOMING_FIRE",entity.id);
			AI.SetBehaviorVariable(entity.id, "Hide", true);
		else
			if(sender==g_localActor) then 
				entity:Readibility("friendly_fire",1,0.6,1);
				entity:InsertSubpipe(AIGOALPIPE_NOTDUPLICATE,"look_at_player_5sec");			
				entity:InsertSubpipe(AIGOALPIPE_NOTDUPLICATE,"do_nothing");		-- make the timeout goal in previous subpipe restart if it was there already
			end
		end
	end,

	--------------------------------------------------
	OnCollision = function(self,entity,sender,data)
		if(AI.GetTargetType(entity.id) ~= AITARGET_ENEMY) then 
			if(AI.Hostile(entity.id,data.id)) then 
			--entity:ReadibilityContact();
				entity:SelectPipe(0,"short_look_at_lastop",data.id);
			end
		end
	end,	
	
	--------------------------------------------------
	OnCloseContact = function ( self, entity, sender,data)
--		entity:InsertSubpipe(AIGOALPIPE_NOTDUPLICATE,"melee_close");
	end,

	---------------------------------------------
--	OnGroupMemberDied = function( self, entity, sender)
--		entity:GettingAlerted();
--		AI.Signal(SIGNALFILTER_SENDER,1,"TO_HIDE",entity.id);
--	end,
	
	--------------------------------------------------
	OnGroupMemberDied = function(self, entity, sender, data)
		--AI.LogEvent(entity:GetName().." OnGroupMemberDied!");
		entity:GettingAlerted();
		AI.SetBehaviorVariable(entity.id, "Hide", true);
	end,

	--------------------------------------------------
	COVER_NORMALATTACK = function (self, entity, sender)
--		entity:SelectPipe(0,"cv_scramble");
	end,

	--------------------------------------------------
	INVESTIGATE_TARGET = function (self, entity, sender)
		entity:SelectPipe(0,"cv_investigate_threat");	
	end,

	---------------------------------------------
	ENEMYSEEN_FIRST_CONTACT = function( self, entity )
		if(AI.GetTargetType(entity.id) ~= AITARGET_ENEMY) then
			entity:Readibility("idle_interest_see",1,1,0.6,1);
			if(AI_Utils:IsTargetOutsideStandbyRange(entity) == 1) then
				entity.AI.hurryInStandby = 1;
				AI.SetBehaviorVariable(entity.id, "ThreatenedStandby", true);
			else
				AI.SetBehaviorVariable(entity.id, "Threatened", true);
			end
		end
	end,

	--------------------------------------------------
	ENEMYSEEN_DURING_COMBAT = function (self, entity, sender)
		entity:GettingAlerted();
		if(AI.GetTargetType(entity.id) ~= AITARGET_ENEMY) then
			AI.SetBehaviorVariable(entity.id, "Seek", true);
		end
	end,

	---------------------------------------------
	INCOMING_FIRE = function (self, entity, sender)
		entity:GettingAlerted();

		if(DistanceVectors(sender:GetPos(), entity:GetPos()) < 15.0) then
			-- near to the guy who is being shot, hide!
			AI.SetBehaviorVariable(entity.id, "Hide", true);
		else
			-- further away, threatened!
			if(AI_Utils:IsTargetOutsideStandbyRange(entity) == 1) then
				entity.AI.hurryInStandby = 1;
				AI.SetBehaviorVariable(entity.id, "ThreatenedStandby", true);
			else
				AI.SetBehaviorVariable(entity.id, "Threatened", true);
			end
		end
	end,

	---------------------------------------------
	TREE_DOWN = function (self, entity, sender)
		entity:Readibility("bulletrain",1,1,0.1,0.4);
	end,

--	OnVehicleDanger = function(self, entity, sender, signalData)
--	end,

	--------------------------------------------------
	OnLeaderReadabilitySeek = function(self, entity, sender)
		entity:Readibility("signalMove",1,10);
	end,
	--------------------------------------------------
	OnLeaderReadabilityAlarm = function(self, entity, sender)
		entity:Readibility("signalGetDown",1,10);
	end,
	--------------------------------------------------
	OnLeaderReadabilityAdvanceLeft = function(self, entity, sender)
		entity:Readibility("signalAdvance",1,10);
	end,
	--------------------------------------------------
	OnLeaderReadabilityAdvanceRight = function(self, entity, sender)
		entity:Readibility("signalAdvance",1,10);
	end,
	--------------------------------------------------
	OnLeaderReadabilityAdvanceForward = function(self, entity, sender)
		entity:Readibility("signalAdvance",1,10);
	end,
	
	---------------------------------------------
	OnFriendlyDamage = function ( self, entity, sender,data)
		if(data.id==g_localActor.id) then 
			entity:Readibility("friendly_fire",1,1, 0.6,1);
			if(entity:IsUsingPipe("stand_only")) then 
				entity:InsertSubpipe(AIGOALPIPE_NOTDUPLICATE,"look_at_player_5sec");			
				entity:InsertSubpipe(AIGOALPIPE_NOTDUPLICATE,"do_nothing");		-- make the timeout goal in previous subpipe restart if it was there already
			end
		end
	end,

	---------------------------------------------
	SELECT_SEC_WEAPON = function (self, entity)
		entity:SelectSecondaryWeapon();
	end,

	---------------------------------------------
	SELECT_PRI_WEAPON = function (self, entity)
		entity:SelectPrimaryWeapon();
	end,

	---------------------------------------------
	ConstructorCover2 = function (self, entity)
		entity.AI.target = {x=0, y=0, z=0};
		entity.AI.targetFound = 0;

		AI_Utils:SetupTerritory(entity);
		AI_Utils:SetupStandby(entity);
	end,

	---------------------------------------------
	ConstructorSneaker = function (self, entity)
		entity.AI.target = {x=0, y=0, z=0};
		entity.AI.targetFound = 0;

		AI_Utils:SetupTerritory(entity);
		AI_Utils:SetupStandby(entity);
	end,

	---------------------------------------------
	ConstructorCamper = function (self, entity)
		entity.AI.target = {x=0, y=0, z=0};
		entity.AI.targetFound = 0;
		
		AI_Utils:SetupTerritory(entity);
		AI_Utils:SetupStandby(entity, true);
	end,

	---------------------------------------------
	ConstructorLeader = function (self, entity)
		entity.AI.target = {x=0, y=0, z=0};
		entity.AI.targetFound = 0;
		
		AI_Utils:SetupTerritory(entity);
		AI_Utils:SetupStandby(entity);
	end,

	---------------------------------------------
	OnShapeEnabled = function (self, entity, sender, data)
		--Log(entity:GetName().."OnShapeEnabled");
		if(data.iValue == AIAnchorTable.COMBAT_TERRITORY) then
			AI_Utils:SetupTerritory(entity, false);
		elseif(data.iValue == AIAnchorTable.ALERT_STANDBY_IN_RANGE) then
			AI_Utils:SetupStandby(entity);
		end
	end,

	---------------------------------------------
	OnShapeDisabled = function (self, entity, sender, data)
		--Log(entity:GetName().."OnShapeDisabled");
		if(data.iValue == 1) then
			-- refshape
			AI_Utils:SetupStandby(entity);
		elseif(data.iValue == 2) then
			-- territory
			AI_Utils:SetupTerritory(entity, false);
		elseif(data.iValue == 3) then
			-- refshape and territory
			AI_Utils:SetupTerritory(entity, false);
			AI_Utils:SetupStandby(entity);
		end
		
	end,

	---------------------------------------------
	SET_TERRITORY = function (self, entity, sender, data)

		-- If the current standby area is the same as territory, clear the standby.
		if(entity.AI.StandbyEqualsTerritory) then
			entity.AI.StandbyShape = nil;
		end

		entity.AI.TerritoryShape = data.ObjectName;
		newDist = AI.DistanceToGenericShape(entity:GetPos(), entity.AI.TerritoryShape, 0);

		local curDist = 10000000.0;
		if(entity.AI.StandbyShape) then
			curDist = AI.DistanceToGenericShape(entity:GetPos(), entity.AI.StandbyShape, 0);
		end

--		Log(" - curdist:"..tostring(curDist));
--		Log(" - newdist:"..tostring(newDist));

		if(newDist < curDist) then
			if(entity.AI.TerritoryShape) then
				entity.AI.StandbyShape = entity.AI.TerritoryShape;
			end
			entity.AI.StandbyEqualsTerritory = true;
		end

		if(entity.AI.StandbyShape) then
			entity.AI.StandbyValid = true;
			AI.SetRefShapeName(entity.id, entity.AI.StandbyShape);
		else
			entity.AI.StandbyValid = false;
			AI.SetRefShapeName(entity.id, "");
		end

		if(entity.AI.TerritoryShape) then
			AI.SetTerritoryShapeName(entity.id, entity.AI.TerritoryShape);
		else
			AI.SetTerritoryShapeName(entity.id, "");
		end

	end,

	---------------------------------------------
	CLEAR_TERRITORY = function (self, entity, sender, data)
		entity.AI.StandbyEqualsTerritory = false;
		entity.AI.StandbyShape = nil;
		entity.AI.TerritoryShape = nil;

		AI.SetRefShapeName(entity.id, "");
		AI.SetTerritoryShapeName(entity.id, "");
	end,

	--------------------------------------------------
	OnCallReinforcements = function (self, entity, sender, data)
		entity.AI.reinfSpotId = data.id;
		entity.AI.reinfType = data.iValue;

--		AI.LogEvent(">>> "..entity:GetName().." OnCallReinforcements");

		AI.SetBehaviorVariable(entity.id, "CallReinforcement", false);
	end,

	--------------------------------------------------
	OnGroupChanged = function (self, entity)
		-- TODO: goto the nearest group
		if (AI.GetTargetType(entity.id)~=AITARGET_ENEMY) then
			AI.BeginGoalPipe("cv_goto_beacon");
				AI.PushGoal("locate",0,"beacon");
				AI.PushGoal("approach",1,4,AILASTOPRES_USE,15,"",3);
				AI.PushGoal("signal",1,1,"GROUP_REINF_DONE",0);
			AI.EndGoalPipe();
			entity:SelectPipe(0,"cv_goto_beacon");
		end
	end,
	--------------------------------------------------
	GROUP_REINF_DONE = function (self, entity)
		AI_Utils:CommonContinueAfterReaction(entity);
	end,

	--------------------------------------------------
	OnExposedToFlashBang = function (self, entity, sender, data)

		if (data.iValue == 1) then
			-- near
			entity:SelectPipe(0,"sn_flashbang_reaction_flinch");
		else
			-- visible
			entity:SelectPipe(0,"sn_flashbang_reaction");
		end
	end,

	--------------------------------------------------
	FLASHBANG_GONE = function (self, entity)
		entity:SelectPipe(0,"do_nothing");
		-- Choose proper action after being interrupted.
		AI_Utils:CommonContinueAfterReaction(entity);
	end,

	--------------------------------------------------
	OnExposedToSmoke = function (self, entity)
		--System.Log(">>>>"..entity:GetName().." OnExposedToSmoke");
--		if (random(1,10) > 6) then
			entity:Readibility("cough",1,115,0.1,4.5);
--		end
	end,

	---------------------------------------------	
	OnExposedToExplosion = function(self, entity, data)
		if(data == nil)then
		   return;
		end
		self:OnCloseCollision(entity, data);
	end,

	---------------------------------------------
	OnCloseCollision = function(self, entity, data)
		AI_Utils:ChooseFlinchReaction(entity, data.point);
	end,

	---------------------------------------------
	OnGroupMemberMutilated = function(self, entity)
--		System.Log(">>"..entity:GetName().." OnGroupMemberMutilated");
		AI.SetBehaviorVariable(entity.id, "Panic", true);
	end,

	---------------------------------------------
	OnTargetCloaked = function(self, entity)
		entity:SelectPipe(0,"sn_target_cloak_reaction");
	end,

	---------------------------------------------
	PANIC_DONE = function(self, entity)
		AI.Signal(SIGNALFILTER_GROUPONLY_EXCEPT, 1, "ENEMYSEEN_FIRST_CONTACT",entity.id);
		-- Choose proper action after being interrupted.
		AI_Utils:CommonContinueAfterReaction(entity);
	end,

	
	--------------------------------------------------	
	OnOutOfAmmo = function (self,entity, sender)
		entity:Readibility("reload",1,4,0.1,0.4);
		if (entity.Reload == nil) then
			--System.Log("  - no reload available");
			do return end
		end
		entity:Reload();
	end,
	
	---------------------------------------------
	SET_DEFEND_POS = function(self, entity, sender, data)
		--System.Log(">>>>"..entity:GetName().." SET_DEFEND_POS");
		if (data and data.point) then
			AI.SetRefPointPosition(entity.id,data.point);
		end
	end,

	---------------------------------------------
	CLEAR_DEFEND_POS = function(self, entity, sender, data)
	end,

	---------------------------------------------
	OnFallAndPlayWakeUp	= function(self, entity, data)
--		System.Log(">>>>"..entity:GetName().." OnFallAndPlayWakeUp");
		AI_Utils:CommonContinueAfterReaction(entity);
	end,
})
