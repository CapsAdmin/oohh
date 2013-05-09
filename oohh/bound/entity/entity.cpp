#include "StdAfx.h"
#include "oohh.hpp"

#include "IEntitySystem.h"
#include "IIndexedMesh.h"


LUAMTA_FUNCTION(entity, __tostring)
{
	auto self = my->ToEntity(1);

	my->Push(string("").Format("entity[%i][%s]", oohh::GetEntityId(self), self->GetClass()->GetName()));

	return 1;
}

/* 
Normally the uniqueid is the pointer of the ... pointer. 

Since we want for example an actor instance of an entity to be the 
same as the entity we should give it the same id as entity so user 
data stored in its table will be shared between actor and entity 
*/

LUAMTA_FUNCTION(entity, __uniqueid)
{
	auto self = my->ToEntity(1);

	my->Push((long int)self);

	return 1;
}

LUAMTA_FUNCTION(entity, GetId)
{
	auto self = my->ToEntity(1);
	my->Push(oohh::GetEntityId(self, my->IsTrue(2)));

	return 1;
}

LUAMTA_FUNCTION(entity, SetChannelId)
{
	auto self = my->ToEntity(1);

	auto obj = gEnv->pGame->GetIGameFramework()->GetGameObject(self->GetId());

	if (obj)
	{
		obj->SetChannelId(my->ToNumber(2));
		my->Push(obj->GetChannelId());

		return 1;
	}

	return 0;
}


LUAMTA_FUNCTION(entity, Spawn)
{
	auto self = my->ToEntity(1);

	SEntitySpawnParams params;
		params.pClass = self->GetClass();
		params.vPosition = self->GetPos();
		params.vScale = self->GetScale();
		params.qRotation = self->GetRotation();

	gEnv->pEntitySystem->InitEntity(self, params);

	my->Push(self);

	return 1;
}

LUAMTA_FUNCTION(entity, Remove)
{
	auto self = my->ToEntity(1);
	auto now = my->ToBoolean(2);

	gEnv->pEntitySystem->RemoveEntity(self->GetId(), now);
	if (now)
		my->MakeNull(self);

	return 0;
}

LUAMTA_FUNCTION(entity, Activate)
{
	my->ToEntity(1)->Activate(my->ToBoolean(2));

	return 0;
}

LUAMTA_FUNCTION(entity, SetPos)
{
	auto self = my->ToEntity(1);

	self->SetPos(my->ToVec3(2));

	return 0;
}

LUAMTA_FUNCTION(entity, GetPos)
{
	auto self = my->ToEntity(1);

	my->Push(self->GetPos());

	return 1;
}

LUAMTA_FUNCTION(entity, GetName)
{
	auto self = my->ToEntity(1);
	my->Push(self->GetName());
	return 1;
}

LUAMTA_FUNCTION(entity, GetClass)
{
	auto self = my->ToEntity(1);
	my->Push(self->GetClass()->GetName());
	return 1;
}

LUAMTA_FUNCTION(entity, GetDescription)
{
	auto self = my->ToEntity(1);
	my->Push(self->GetEntityTextDescription());
	return 1;
}

LUAMTA_FUNCTION(entity, IsValid)
{
	auto self = my->ToEntity(1);
	my->Push(!self->IsGarbage());

	return 1;
}

LUAMTA_FUNCTION(entity, SetModel)
{
	auto self = my->ToEntity(1);
	
	int slot = 0;
	auto ext = PathUtil::GetExt(my->ToString(2));

	if ((stricmp(ext, "chr") == 0) || (stricmp(ext, "cdf") == 0) || (stricmp(ext, "cga") == 0))
	{
		slot = self->LoadCharacter(my->ToNumber(3, 0), my->ToString(2), my->ToNumber(4, 0));
	}
	else
	{
		slot = self->LoadGeometry(my->ToNumber(3, 0), my->ToString(2), 0);
	}

	self->UpdateSlotPhysics(slot);

	my->Push(slot);

	return 1;
}
	
LUAMTA_FUNCTION(entity, GetModel)
{
	auto self = my->ToEntity(1);
	auto slot = my->ToNumber(2, 0);

	auto obj = self->GetStatObj(slot);
	
	if (obj)
	{
		my->Push(obj ? obj->GetFilePath() : "");
	}
	else
	{
		auto obj = self->GetCharacter(slot);

		my->Push(obj ? obj->GetICharacterModel()->GetModelFilePath() : "");
	}
	
	return 1;
}

LUAMTA_FUNCTION(entity, GetLocalTM)
{
	my->Push(my->ToEntity(1)->GetLocalTM());

	return 1;
}

LUAMTA_FUNCTION(entity, SetLocalTM)
{
	my->ToEntity(1)->SetLocalTM(my->ToMatrix34(2));

	return 1;
}

LUAMTA_FUNCTION(entity, GetWorldRotation)
{
	my->Push(my->ToEntity(1)->GetWorldRotation());

	return 1;
}

LUAMTA_FUNCTION(entity, GetWorldPos)
{
	my->Push(my->ToEntity(1)->GetWorldPos());

	return 1;
}

LUAMTA_FUNCTION(entity, SetRotation)
{
	my->ToEntity(1)->SetRotation(my->ToQuat(2));

	return 0;
}

LUAMTA_FUNCTION(entity, GetRotation)
{
	my->Push(my->ToEntity(1)->GetRotation());

	return 1;
}

LUAMTA_FUNCTION(entity, SetAngles)
{
	my->ToEntity(1)->SetRotation(Quat(my->ToAng3(2)));

	return 0;
}

LUAMTA_FUNCTION(entity, GetAngles)
{
	my->Push(Ang3(my->ToEntity(1)->GetRotation()));

	return 1;
}

LUAMTA_FUNCTION(entity, GetScale)
{	
	my->Push(my->ToEntity(1)->GetScale());

	return 1;
}

LUAMTA_FUNCTION(entity, SetScale)
{
	my->ToEntity(1)->SetScale(my->ToVec3(2));

	return 0;
}

LUAMTA_FUNCTION(entity, SetParent)
{
	my->ToEntity(2)->AttachChild(my->ToEntity(1));

	return 0;
}

LUAMTA_FUNCTION(entity, AddChild)
{
	my->ToEntity(1)->AttachChild(my->ToEntity(2));

	return 0;
}

LUAMTA_FUNCTION(entity, GetParent)
{
	my->Push(my->ToEntity(1)->GetParent());

	return 1;
}

// flags
LUAMTA_FUNCTION(entity, SetFlags)
{
	my->ToEntity(1)->SetFlags(my->ToNumber(2));

	return 0;
}

LUAMTA_FUNCTION(entity, AddFlags)
{
	my->ToEntity(1)->AddFlags(my->ToNumber(2));

	return 0;
}

LUAMTA_FUNCTION(entity, GetFlags)
{
	my->Push((int)my->ToEntity(1)->GetFlags());

	return 1;
}

LUAMTA_FUNCTION(entity, SetName)
{
	my->ToEntity(1)->SetName(my->ToString(2));

	return 0;
}

LUAMTA_FUNCTION(entity, GetGuid)
{
	my->Push(string("").Format("%llu", my->ToEntity(1)->GetGuid()));

	return 1;
}

LUAMTA_FUNCTION(entity, UpdateNetworkPosition)
{
	auto self = my->ToEntity(1);
	
	auto framework = gEnv->pGame->GetIGameFramework();

	if (framework && framework->GetNetContext() && framework->GetNetContext()->IsBound(self->GetId()))
	{
		framework->GetNetContext()->ChangedTransform(self->GetId(), self->GetPos(), self->GetRotation(), gEnv->p3DEngine->GetMaxViewDistance());
		
		my->Push(true);

		return 1;
	}

	my->Push(false);

	return 1;
}

LUAMTA_FUNCTION(entity, SetNetworkParent)
{
	auto self = gEnv->pGame->GetIGameFramework()->GetGameObject(my->ToEntity(1)->GetId());

	if (self)
	{
		self->SetNetworkParent(my->ToEntity(2)->GetId());
	}

	return 0;
}

LUAMTA_FUNCTION(entity, IsProbablyDistant)
{
	auto self = gEnv->pGame->GetIGameFramework()->GetGameObject(my->ToEntity(1)->GetId());

	if (self)
	{
		my->Push(self->IsProbablyDistant());

		return 1;
	}

	return 0;
}

LUAMTA_FUNCTION(entity, IsProbablyVisible)
{
	auto self = gEnv->pGame->GetIGameFramework()->GetGameObject(my->ToEntity(1)->GetId());

	if (self)
	{
		my->Push(self->IsProbablyVisible());

		return 1;
	}

	return 0;
}

LUAMTA_FUNCTION(entity, SetKeyValue)
{
	auto self = my->ToEntity(1);
	
	if (my->IsString(3))
	{
		self->GetScriptTable()->SetValue(my->ToString(2), my->ToString(3));
	}
	else 
	if (my->IsNumber(3))
	{
		self->GetScriptTable()->SetValue(my->ToString(2), (float)my->ToNumber(3));
	}
	else 
	if (my->IsVec3(3))
	{
		self->GetScriptTable()->SetValue(my->ToString(2), my->ToVec3(3));
	}

	return 0;
}

LUAMTA_FUNCTION(entity, GetKeyValues)
{
	auto self = my->ToEntity(1);
	
	auto iter = self->GetScriptTable()->BeginIteration();
	
	my->NewTable();
	

	while(self->GetScriptTable()->MoveNext(iter))
	{
#ifdef CE3
		if (iter.key.type == ANY_TSTRING)
		{	
			if (iter.value.type == ANY_TSTRING)
			{
				my->SetMember(-1, iter.key.str, iter.value.str);
			}
			else
			if (iter.value.type == ANY_TNUMBER)
			{
				my->SetMember(-1, iter.key.str, iter.value.number);
			}
			else
			if (iter.value.type == ANY_TVECTOR)
			{
				my->SetMember(-1, iter.key.str, Vec3(iter.value.vec3.x, iter.value.vec3.y, iter.value.vec3.z));
			}
		}
		else
		if (iter.key.type == ANY_TNUMBER)
		{	
			if (iter.value.type == ANY_TSTRING)
			{
				my->SetMember(-1, iter.key.number, iter.value.str);
			}
			else
			if (iter.value.type == ANY_TNUMBER)
			{
				my->SetMember(-1, iter.key.number, iter.value.number);
			}
			else
			if (iter.value.type == ANY_TVECTOR)
			{
				my->SetMember(-1, iter.key.number, Vec3(iter.value.vec3.x, iter.value.vec3.y, iter.value.vec3.z));
			}
		}
#else
		my->SetMember(-1, iter.sKey, iter.value.str);
#endif
	}
	
	return 1;
}

LUAMTA_FUNCTION(entity, GetBoneNameFromId)
{
	auto self = my->ToEntity(1);
	auto chr = self->GetCharacter(my->ToNumber(3, 0));

	if (chr)
	{
		my->Push(chr->GetICharacterModel()->GetICharacterModelSkeleton()->GetJointNameByID(my->ToNumber(2)));

		return 1;
	}

	return 0;
}


LUAMTA_FUNCTION(entity, GetBoneIdFromName)
{
	auto self = my->ToEntity(1);
	auto chr = self->GetCharacter(my->ToNumber(3, 0));

	if (chr)
	{
		my->Push(chr->GetICharacterModel()->GetICharacterModelSkeleton()->GetJointIDByName(my->ToString(2)));

		return 1;
	}

	return 0;
}


LUAMTA_FUNCTION(entity, GetBoneCount)
{
	auto self = my->ToEntity(1);
	auto chr = self->GetCharacter(my->ToNumber(2, 0));

	if (chr)
	{
		my->Push(chr->GetICharacterModel()->GetICharacterModelSkeleton()->GetJointCount());

		return 1;
	}

	my->Push(0);

	return 1;
}


LUAMTA_FUNCTION(entity, SetIKBonePos)
{
	auto self = my->ToEntity(1);

	auto chr = self->GetCharacter(my->ToNumber(4, 0));

	if (chr)
	{
		auto um = QuatT();
		um.SetTranslation(my->ToVec3(3));

		my->Push(chr->GetISkeletonPose()->SetHumanLimbIK(um, my->ToNumber(2)));

		return 1;
	}

	return 0;
}

LUAMTA_FUNCTION(entity, SetBonePos)
{
	auto self = my->ToEntity(1);
	auto chr = self->GetCharacter(my->ToNumber(4, 0));

	if (chr)
	{
		auto um = QuatT();
		um.SetTranslation(my->ToVec3(3));

		chr->GetISkeletonPose()->SetAbsJointByID(my->ToNumber(2), um);
	}

	return 0;
}

LUAMTA_FUNCTION(entity, GoLimp)
{
	auto self = my->ToEntity(1);
	auto chr = self->GetCharacter(my->ToNumber(2, 0));

	if (chr)
	{
		chr->GetISkeletonPose()->GoLimp();
	}

	return 0;
}

LUAMTA_FUNCTION(entity, GetParentBoneIdFromBoneId)
{
	auto self = my->ToEntity(1);

	auto chr = self->GetCharacter(my->ToNumber(3, 0));

	if (chr)
	{
		my->Push(chr->GetISkeletonPose()->GetParentIDByID(my->ToNumber(2)));

		return 1;
	}

	return 0;
}

LUAMTA_FUNCTION(entity, GetBonePosAng)
{
	auto self = my->ToEntity(1);

	auto chr = self->GetCharacter(my->ToNumber(3, 0));

	if (chr)
	{
		auto data = chr->GetISkeletonPose()->GetAbsJointByID(my->ToNumber(2));

		my->Push(data.t);
		my->Push(Ang3(data.q));

		return 2;
	}

	return 0;
}

#define PTR_ISVALID(obj) if(obj == NULL){my->Push(false); my->Push("Pointer invalid: "#obj); return 2;}
#define SHOULD_EXPECT(expect) if(!my->Is##expect(-1)){my->Push(false); my->Push("Expected format for a vertex is {Vec3 vertex, Vec3 norm}"); return 2;}

LUAMTA_FUNCTION(entity, SetMeshTable)
{
	auto self = my->ToEntity(1);

	luaL_checktype(L, 2, LUA_TTABLE);
	auto vertexcount = lua_objlen(L, 2) + 1;
	
	auto proxy = static_cast<IEntityRenderProxy *>(self->GetProxy(ENTITY_PROXY_RENDER));
	PTR_ISVALID(proxy)

	auto node = proxy->GetRenderNode();
	PTR_ISVALID(node)
	
	auto statobj = node->GetEntityStatObj(my->ToNumber(3, 0));
	PTR_ISVALID(statobj)

	auto imesh = statobj->GetIndexedMesh(true);
	PTR_ISVALID(imesh)
	
	auto mesh = imesh->GetMesh();

	mesh->SetIndexCount(vertexcount);
	mesh->SetVertexCount(vertexcount);
	mesh->SetFacesCount(vertexcount);
	mesh->m_subsets.clear();

	for(int i = 0; i < vertexcount; i++)
	{
		lua_rawgeti(L, 2, i);
		
		if (my->IsType(-1, LUA_TTABLE))
		{
			lua_rawgeti(L, -1, 1);
				SHOULD_EXPECT(Vec3);
				mesh->m_pPositions[i] = my->ToVec3(-1);
			my->Remove(-1);

			lua_rawgeti(L, -1, 2);
				SHOULD_EXPECT(Vec3);
				mesh->m_pNorms[i] = my->ToVec3(-1);
			my->Remove(-1);

			mesh->m_pIndices[i] = i;
		}
		
		my->Remove(-1);
	}

	AABB box;
	self->GetLocalBounds(box);
	mesh->m_bbox.min = box.min;
	mesh->m_bbox.max = box.max;

	const char* error_desc = 0;	
	if (mesh->Validate(&error_desc))
	{
		imesh->SetMesh(*mesh);
		imesh->Invalidate();
	
		my->Push(true);

		return 1;
	}

	my->Push(false);
	my->Push(error_desc);

	return 2;
}

LUAMTA_FUNCTION(entity, GetMeshTable)
{
	auto self = my->ToEntity(1);
	auto proxy = static_cast<IEntityRenderProxy *>(self->GetProxy(ENTITY_PROXY_RENDER));
	
	auto node = proxy->GetRenderNode();
	PTR_ISVALID(node)
	
	auto statobj = node->GetEntityStatObj(my->ToNumber(2, 0));
	PTR_ISVALID(statobj)

	auto rmesh = statobj->GetRenderMesh();
	PTR_ISVALID(rmesh)

	rmesh->LockForThreadAccess();

	auto vtx_count = rmesh->GetVerticesCount();
	auto vtx_stride = 0;
	auto vtx_data = rmesh->GetPosPtr(vtx_stride, FSL_SYSTEM_UPDATE);
	PTR_ISVALID(vtx_data)

	auto nrm_stride = 0;
	auto nrm_data = rmesh->GetNormPtr(nrm_stride, FSL_SYSTEM_UPDATE);
	PTR_ISVALID(nrm_data)

	auto idx_count = rmesh->GetIndicesCount();
	auto idx_stride = 0;
	auto idx_data = rmesh->GetIndexPtr(FSL_SYSTEM_UPDATE, 0);
	PTR_ISVALID(idx_data)
	
	auto vertices = strided_pointer<Vec3>((Vec3*)vtx_data, vtx_stride);
    auto normals = strided_pointer<Vec3>((Vec3*)nrm_data);
    auto indices = strided_pointer<uint16>(idx_data);

	my->NewTable();

	// since lua tables start at 1 we want to follow that rule 
	// by shifting up the indeces by 1
	for (int i = 0; i < vtx_count; ++i)
	{
		my->NewTable();

			auto idx = indices[i];

			my->Push(Vec3(vertices[idx]));
			lua_rawseti(L, -2, 1);

			my->Push(Vec3(normals[idx]));
			lua_rawseti(L, -2, 2);

		lua_rawseti(L, -2, idx);		
	}

	rmesh->UnLockForThreadAccess();

	return 1;
}

LUAMTA_FUNCTION(entity, NetSpawn)
{
	auto self = my->ToEntity(1);

	gEnv->pGame->GetIGameFramework()->GetNetContext()->SpawnedObject(self->GetId());

	return 0;
}

LUAMTA_FUNCTION(entity, NetTransform)
{
	auto self = my->ToEntity(1);

	gEnv->pGame->GetIGameFramework()->GetNetContext()->ChangedTransform(self->GetId(), my->ToVec3(2), my->ToQuat(3), my->ToNumber(4));

	return 0;
}

LUAMTA_FUNCTION(entity, NetAspect)
{
	auto self = my->ToEntity(1);

	gEnv->pGame->GetIGameFramework()->GetNetContext()->ChangedAspects(self->GetId(), my->ToNumber(2, NET_ASPECT_ALL));

	return 0;
}

LUAMTA_FUNCTION(entity, NetBind)
{
	auto self = my->ToEntity(1);

	gEnv->pGame->GetIGameFramework()->GetNetContext()->BindObject(self->GetId(), my->ToNumber(2, NET_ASPECT_ALL), my->ToBoolean(3));

	return 0;
}

LUAMTA_FUNCTION(entity, NetPulse)
{
	auto self = my->ToEntity(1);

	gEnv->pGame->GetIGameFramework()->GetNetContext()->PulseObject(self->GetId(), my->ToNumber(2));

	return 0;
}

LUAMTA_FUNCTION(entity, SetNetParent)
{
	auto self = my->ToEntity(1);

	gEnv->pGame->GetIGameFramework()->GetNetContext()->SetParentObject(self->GetId(), my->ToEntity(2)->GetId());

	return 0;
}

LUAMTA_FUNCTION(entity, BindToNetwork)
{
	auto self = my->ToEntity(1);

	if (strcmp(self->GetClass()->GetName(), "ScriptedEntity") == 0) return 0;

	auto obj = gEnv->pGame->GetIGameFramework()->GetIGameObjectSystem()->CreateGameObjectForEntity(self->GetId());

	obj->EnablePrePhysicsUpdate(ePPU_Always);
	obj->EnablePhysicsEvent(true, eEPE_AllImmediate);
	obj->SetAspectProfile(eEA_Physics, ePT_Rigid);

	obj->BindToNetwork();

	return 0;
}

LUAMTA_FUNCTION(entity, AddEntityLink)
{
	auto self = my->ToEntity(1);

	self->AddEntityLink(my->ToString(2), my->ToEntity(3)->GetId(), my->ToEntity(3)->GetGuid(), my->ToQuat(4, Quat(IDENTITY)), my->ToVec3(5, IDENTITY));

	return 0;
}

LUAMTA_FUNCTION(entity, RemoveEntityLink)
{
	auto self = my->ToEntity(1);
	auto str = my->ToString(2);

	for (auto link = self->GetEntityLinks(); link; link= link->next)
    {
		if (strcmp(link->name, str) == 0)
		{
			self->RemoveEntityLink(link);
			break;
		}
	}

	return 0;
}

LUAMTA_FUNCTION(entity, GetEntityLinks)
{
	auto self = my->ToEntity(1);
	auto str = my->ToString(2);

	my->NewTable();

	for (auto link = self->GetEntityLinks(); link; link= link->next)
    {
		my->NewTable();
			my->SetMember(-1, "name", link->name);
			my->SetMember(-1, "pos", link->relPos);
			my->SetMember(-1, "rot", link->relRot);
		my->SetTable(-2);
	}

	return 1;
}

LUAMTA_FUNCTION(entity, RemoveAllEntityLinks)
{
	my->ToEntity(1)->RemoveAllEntityLinks();

	return 0;
}

LUAMTA_FUNCTION(entity, SetOpacity)
{
	auto self = (IEntityRenderProxy *)my->ToEntity(1)->GetProxy(ENTITY_PROXY_RENDER);

	self->SetOpacity(my->ToNumber(2));

	return 0;
}

LUAMTA_FUNCTION(entity, GetOpacity)
{
	auto self = (IEntityRenderProxy *)my->ToEntity(1)->GetProxy(ENTITY_PROXY_RENDER);

	my->Push(self->GetOpacity());

	return 1;
}