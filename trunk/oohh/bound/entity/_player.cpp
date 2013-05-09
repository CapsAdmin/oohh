#include "StdAfx.h"

#include "oohh.hpp"

#include "Player.h"
#include "Game.h"

LUAMTA_FUNCTION(player, __tostring)
{
	auto self = my->ToPlayer(1);

	my->Push(string("").Format("player[%i]", oohh::GetEntityId(self->GetEntity())));

	return 1;
}

LUAMTA_FUNCTION(player, GetActor)
{
	auto actor = static_cast<CActor*>(my->ToPlayer(1));

	my->Push(actor, false);

	return 1;
}

LUAMTA_FUNCTION(player, GetEntity)
{
	auto self = my->ToPlayer(1);

	my->Push(self->GetEntity(), false);

	return 1;
}

LUAMTA_FUNCTION(player, GetEyePos)
{
	SMovementState params;
		my->ToPlayer(1)->GetMovementController()->GetMovementState(params);
	my->Push(params.eyePosition);

	return 1;
}

LUAMTA_FUNCTION(player, SetFOV)
{
	auto self = my->ToPlayer(1);
	self->GetActorParams()->lookFOVRadians = my->ToNumber(2, 90);

	return 0;
}

LUAMTA_FUNCTION(player, GetFOV)
{
	auto self = my->ToPlayer(1);
	my->Push(self->GetActorParams()->lookFOVRadians);

	return 1;
}

LUAMTA_FUNCTION(player, GetEyeDir)
{
	SMovementState params;
		my->ToPlayer(1)->GetMovementController()->GetMovementState(params);
	my->Push(params.eyeDirection);

	return 1;
}

LUAMTA_FUNCTION(player, IsAlive)
{
	SMovementState params;
		my->ToPlayer(1)->GetMovementController()->GetMovementState(params);
	my->Push(params.isAlive);

	return 1;
}

LUAMTA_FUNCTION(player, IsFiring)
{
	SMovementState params;
		my->ToPlayer(1)->GetMovementController()->GetMovementState(params);
	my->Push(params.isFiring);

	return 1;
}

LUAMTA_FUNCTION(player, SetFlyMode)
{
	my->ToPlayer(1)->SetFlyMode(my->ToNumber(2));
	
	return 0;
}

LUAMTA_FUNCTION(player, EnableParachute)
{
	my->ToPlayer(1)->EnableParachute(my->ToBoolean(2));
	
	return 0;
}

LUAMTA_FUNCTION(player, ForceFreeFall)
{
	my->ToPlayer(1)->ForceFreeFall();
	
	return 0;
}

#define CHECKCHANNEL \
INetChannel *chan = NULL; \
	chan = self->GetGameObject() ? gEnv->pGame->GetIGameFramework()->GetNetChannel(self->GetChannelId()) : nullptr;\
	if (!chan) \
		chan = gEnv->pGame->GetIGameFramework()->GetClientChannel();

LUAMTA_FUNCTION(player, GetName)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	my->Push(chan->GetName());
	
	return 1;
}

LUAMTA_FUNCTION(player, GetProfileId)
{
	auto self = my->ToPlayer(1);
	
	CHECKCHANNEL;

	my->Push(chan->GetProfileId());
	
	return 1;
}

LUAMTA_FUNCTION(player, GetPing)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	my->Push(chan->GetPing(my->ToBoolean(2)));
	
	return 1;
}

LUAMTA_FUNCTION(player, GetChannelName)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	my->Push(chan->GetName());
	
	return 1;
}

LUAMTA_FUNCTION(player, IsFakeChannel)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	my->Push(chan->IsFakeChannel());
	
	return 1;
}

LUAMTA_FUNCTION(player, GetNickname)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	const char *nick = chan->GetNickname();
	my->Push(nick ? nick : "nomad");
	
	return 1;
}

LUAMTA_FUNCTION(player, SetNickname)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	chan->SetNickname(my->ToString(2));
	
	return 0;
}

LUAMTA_FUNCTION(player, Disconnect)
{
	auto self = my->ToPlayer(1);

	CHECKCHANNEL;

	chan->Disconnect(my->ToEnum<EDisconnectionCause>(2), my->ToString(3));
	
	return 0;
}

LUAMTA_FUNCTION(player, GetActiveWeapon)
{
	auto self = my->ToPlayer(1);

	if (self->GetInventory())
	{
		my->Push(self->GetWeapon(self->GetCurrentItemId()));
		return 1;
	}

	return 0;
}

LUAMTA_FUNCTION(player, GetGrabbedEntity)
{
	my->Push(gEnv->pEntitySystem->GetEntity(my->ToPlayer(1)->GetGrabbedEntityId()));

	return 1;
}

LUAMTA_FUNCTION(player, GetRelativeWaterLevel)
{
	my->Push(my->ToPlayer(1)->GetActorStats()->relativeWaterLevel);

	return 1;
}

LUAMTA_FUNCTION(player, GetSpeed)
{
	my->Push(my->ToPlayer(1)->GetActorStats()->speed);

	return 1;
}

LUAMTA_FUNCTION(player, GetMass)
{
	my->Push(my->ToPlayer(1)->GetActorStats()->mass);

	return 1;
}

LUAMTA_FUNCTION(player, IsRagdoll)
{
	my->Push(my->ToPlayer(1)->GetActorStats()->isRagDoll);

	return 1;
}

LUAMTA_FUNCTION(player, IsInAir)
{
	auto self = my->ToPlayer(1);

	float time = self->GetActorStats()->inAir;

	if (time > 0) 
	{
		my->Push(time);
	}
	else
	{
		my->Push(false);
	}

	return 1;
}

LUAMTA_FUNCTION(player, IsHeadUnderWater)
{
	auto self = my->ToPlayer(1);

	float time = self->GetActorStats()->headUnderWaterTimer;

	if (time > 0) 
	{
		my->Push(time);
	}
	else
	{
		my->Push(false);
	}

	return 1;
}

LUAMTA_FUNCTION(player, IsInWater)
{
	auto self = my->ToPlayer(1);

	float time = self->GetActorStats()->inWaterTimer;

	if (time > 0) 
	{
		my->Push(time);
	}
	else
	{
		my->Push(false);
	}

	return 1;
}

LUAMTA_FUNCTION(player, HasJumped)
{
	auto self = my->ToPlayer(1);

	my->Push(self->GetPlayerStats().jumped);

	return 1;
}

LUAMTA_FUNCTION(player, IsOnGround)
{
	auto self = my->ToPlayer(1);

	float time = self->GetActorStats()->onGround;

	if (time > 0) 
	{
		my->Push(time);
	}
	else
	{
		my->Push(false);
	}

	return 1;
}

LUAMTA_FUNCTION(player, SetOnGround)
{
	auto self = my->ToPlayer(1);

	if (my->ToBoolean(2))
	{
		self->GetActorStats()->onGround = my->ToNumber(3, 1);
		self->GetActorStats()->inAir = -1;		
	}
	else
	{
		self->GetActorStats()->onGround = -1;
		self->GetActorStats()->inAir = my->ToNumber(3, 1);
	}

	return 0;
}

LUAMTA_FUNCTION(player, SetRotation)
{ 
	auto self = my->ToPlayer(1);

	CPlayer::MoveParams params(self->GetEntity()->GetPos(), my->ToQuat(2));

	self->GetGameObject()->InvokeRMI(CPlayer::ClMoveTo(), params, eRMI_ToClientChannel | eRMI_NoLocalCalls, self->GetChannelId());
	self->GetEntity()->SetWorldTM(Matrix34::Create(Vec3(1,1,1), params.rot, params.pos));

	return 0;
}

LUAMTA_FUNCTION(player, SetPos)
{ 
	auto self = my->ToPlayer(1);

	CPlayer::MoveParams params(my->ToVec3(2), self->GetViewRotation());

	self->GetGameObject()->InvokeRMI(CPlayer::ClMoveTo(), params, eRMI_ToClientChannel|eRMI_NoLocalCalls, self->GetChannelId());
	self->GetEntity()->SetWorldTM(Matrix34::Create(Vec3(1,1,1), params.rot, params.pos));

	return 0;
}

LUAMTA_FUNCTION(player, Give)
{ 
	auto self = my->ToPlayer(1);

	auto id = gEnv->pGame->GetIGameFramework()->GetIItemSystem()->GiveItem(
		gEnv->pGame->GetIGameFramework()->GetIActorSystem()->GetActor(self->GetEntityId()),
		my->ToString(2),
		my->IsFalse(4),
		my->IsTrue(3),
		my->IsTrue(5)
	);
	
	my->Push(gEnv->pEntitySystem->GetEntity(id));

	return 1;
}

LUAMTA_FUNCTION(player, Spawn)
{ 
	auto self = my->ToPlayer(1);

	self->Revive(my->IsTrue(2));

	return 0;
}

LUAMTA_FUNCTION(player, Kill)
{ 
	auto self = my->ToPlayer(1);

	self->Kill();

	return 0;
}

LUAMTA_FUNCTION(player, SetVelocity)
{
	auto phys = my->ToPlayer(1)->GetEntity()->GetPhysics();

	pe_action_move params;
		params.dir = my->ToVec3(2);
		params.iJump = 1;
	phys->Action(&params);

	return 1;
}

LUAMTA_FUNCTION(player, AddVelocity)
{
	auto phys = my->ToPlayer(1)->GetEntity()->GetPhysics();

	pe_action_move params;
		params.dir = my->ToVec3(2);
		params.iJump = 2;
	phys->Action(&params);

	return 1;
}

LUAMTA_FUNCTION(player, SetPlayerDynamics)
{
	auto phys = my->ToPlayer(1)->GetEntity()->GetPhysics();
	luaL_checktype(L, 2, LUA_TTABLE);

	pe_player_dynamics params;

		// auto gen'd
		if (my->GetMember(2, "kInertia"))
			params.kInertia = my->ToNumber(-1, params.kInertia);
	
		if (my->GetMember(2, "kInertiaAccel"))	
			params.kInertiaAccel = my->ToNumber(-1, params.kInertiaAccel);

		if (my->GetMember(2, "kAirControl"))
			params.kAirControl = my->ToNumber(-1, params.kAirControl);

		if (my->GetMember(2, "kAirResistance"))
			params.kAirResistance = my->ToNumber(-1, params.kAirResistance);
	
		if (my->GetMember(2, "gravity"))
			params.gravity = my->ToVec3(-1, params.gravity);
	
		if (my->GetMember(2, "nodSpeed"))
			params.nodSpeed = my->ToNumber(-1, params.nodSpeed);
	
		if (my->GetMember(2, "bSwimming"))
			params.bSwimming = my->IsNil(-1) ? params.bSwimming : my->ToBoolean(-1) ? 1 : 0;
	
		if (my->GetMember(2, "mass"))
			params.mass = my->ToNumber(-1, params.mass);
	
		if (my->GetMember(2, "surface_idx"))
			params.surface_idx = my->ToNumber(-1, params.surface_idx);
	
		if (my->GetMember(2, "minSlideAngle"))
			params.minSlideAngle = my->ToNumber(-1, params.minSlideAngle);
	
		if (my->GetMember(2, "maxClimbAngle"))
			params.maxClimbAngle = my->ToNumber(-1, params.maxClimbAngle);
	
		if (my->GetMember(2, "maxJumpAngle"))
			params.maxJumpAngle = my->ToNumber(-1, params.maxJumpAngle);
	
		if (my->GetMember(2, "minFallAngle"))
			params.minFallAngle = my->ToNumber(-1, params.minFallAngle);
	
		if (my->GetMember(2, "maxVelGround"))
			params.maxVelGround = my->ToNumber(-1, params.maxVelGround);
	
		if (my->GetMember(2, "timeImpulseRecover"))
			params.timeImpulseRecover = my->ToNumber(-1, params.timeImpulseRecover);
	
		if (my->GetMember(2, "collTypes"))
			params.collTypes = my->ToNumber(-1, params.collTypes);
	
		if (my->GetMember(2, "pLivingEntToIgnore"))
			params.pLivingEntToIgnore = my->ToPhysics(-1, params.pLivingEntToIgnore);
	
		if (my->GetMember(2, "bNetwork"))
			params.bNetwork = my->IsNil(-1) ? params.bNetwork : my->ToBoolean(-1) ? 1 : 0; 
	
		if (my->GetMember(2, "bActive"))
			params.bActive = my->IsNil(-1) ? params.bActive : my->ToBoolean(-1) ? 1 : 0;
	
		if (my->GetMember(2, "iRequestedTime"))
			params.iRequestedTime = my->ToNumber(-1, params.iRequestedTime);
	

	phys->SetParams(&params);

	return 0;
}