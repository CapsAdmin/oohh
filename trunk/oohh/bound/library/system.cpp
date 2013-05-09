#include "StdAfx.h"
#include "oohh.hpp"

#include "Game.h"
#include "GameRules.h"

LUALIB_FUNCTION(system, IsClient)
{
#ifdef CE3
	my->Push(gEnv->IsClient());
#else
	my->Push(gEnv->bClient);
#endif
	
	return 1;
}

LUALIB_FUNCTION(system, IsServer)
{
	my->Push(gEnv->bServer);

	return 1;
}

LUALIB_FUNCTION(system, IsMultiPlayer)
{
	my->Push(gEnv->bMultiplayer);

	return 1;
}

LUALIB_FUNCTION(system, IsDedicated)
{
#ifdef CE3
	my->Push(gEnv->IsDedicated());
#else
	my->Push(gEnv->bServer);
#endif

	return 1;
}

LUALIB_FUNCTION(system, IsEditor)
{
#ifdef CE3
	my->Push(gEnv->IsEditor());
#else
	my->Push(gEnv->bEditor);
#endif

	return 1;
}

#undef GetCommandLine
LUALIB_FUNCTION(system, GetCommandLine)
{ 
	my->NewTable();

	for (int i = 0; i < gEnv->pSystem->GetICmdLine()->GetArgCount(); i++)
	{
		auto arg = gEnv->pSystem->GetICmdLine()->GetArg(i);

		my->SetMember(-1, arg->GetName(), arg->GetValue(), false);
	}

	return 1;
}

LUALIB_FUNCTION(system, RunCryScriptString)
{
    string script = my->ToString(1);
    my->Push(gEnv->pScriptSystem->ExecuteBuffer(script.c_str(), script.size(), "oohh"));

    return 1;
}

LUALIB_FUNCTION(system, ConsolePrint)
{
	printf("%s", my->ToString(1));

	return 0;
}

LUALIB_FUNCTION(system, EnableRendering)
{
	oohh::EnableRender(my->ToBoolean(1));

	return 0;
}

LUALIB_FUNCTION(system, IsRendering)
{
	my->Push(oohh::IsRendering());

	return 1;
}

LUALIB_FUNCTION(system, EnableFocus)
{
	oohh::EnableFocus(my->ToBoolean(1));

	return 0;
}

LUALIB_FUNCTION(system, IsFocused)
{
	my->Push(oohh::IsFocused());	

	return 1;
}

LUALIB_FUNCTION(system, ResetGame)
{
	gEnv->pGameFramework->Reset(!my->ToBoolean(1));

	return 1;
}


LUALIB_FUNCTION(system, PauseGame)
{
	gEnv->pGameFramework->PauseGame(my->ToBoolean(1), my->IsFalse(2), my->ToNumber(3, 0U));

	return 1;
}


LUALIB_FUNCTION(system, GetHostName)
{
	my->Push(gEnv->pNetwork->GetHostName());

	return 1;
}

LUALIB_FUNCTION(system, SetViewCamera)
{
	gEnv->pSystem->SetViewCamera(my->ToCamera(1));

	return 0;
}

#include "Network/Lobby/GameLobbyManager.h"
#include "Network/Lobby/GameLobby.h"
#include "Network/Squad/SquadManager.h"

LUALIB_FUNCTION(system, Connect)
{
	auto address = my->ToString(1);
	auto retry = my->ToBoolean(2);

	CGameLobby *pGameLobby = g_pGame->GetGameLobby();
	CGameLobbyManager *pGameLobbyMgr = g_pGame->GetGameLobbyManager();
	CSquadManager *pSquadMgr = g_pGame->GetSquadManager();

	if(pGameLobbyMgr)
	{
		pGameLobbyMgr->SetMultiplayer(true);
	}

	if(pSquadMgr)
	{
		pSquadMgr->SetMultiplayer(true);
	}

	ICryMatchMaking *pMatchmaking = gEnv->pNetwork->GetLobby()->GetLobbyService()->GetMatchMaking();

	CrySessionID session;
	pMatchmaking->GetSessionIDFromSessionURL(address, &session);

	auto success = pGameLobby->JoinServer(session, "", CryMatchMakingInvalidConnectionUID, retry);

	my->Push(success);

	return 1;
}

LUALIB_FUNCTION(system, GetFullPath)
{
	TCHAR buffer[MAX_PATH] = TEXT(""); 
	GetFullPathName(my->ToString(1), MAX_PATH, buffer, NULL);
		
	my->Push(buffer);

    return 1;
}