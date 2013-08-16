#include "StdAfx.h"
#include "oohh.hpp"

#include "Game.h"
#include "IGameObject.h"
#include "GameRules.h"

#define INVOKE gEnv->pGame->GetIGameFramework()->GetIGameRulesSystem()->GetCurrentGameRules()->GetGameObject()->InvokeRMI

LUALIB_FUNCTION(network, SendRawToClient)
{
	if (!gEnv->bServer)
		return 0;

	auto msg = (string)my->ToString(2);

	// null fix hmm
	msg = "" + msg; 

	if(my->ToBoolean(3))
	{
		INVOKE(CGameRules::oohhFromServerTCP(), CGameRules::oohhNetMsgTCP(msg), eRMI_ToClientChannel, my->ToPlayer(1)->GetChannelId());
	}
	else
	{
		INVOKE(CGameRules::oohhFromServerUDP(), CGameRules::oohhNetMsgUDP(msg), eRMI_ToClientChannel, my->ToPlayer(1)->GetChannelId());	
	}

	return 0;
}

LUALIB_FUNCTION(network, SendRawToServer)
{
	if (!gEnv->IsClient())
		return 0;

	if (!gEnv->pGame->GetIGameFramework()->GetClientActor())
		return 0;

	auto msg = (string)my->ToString(1);

	// null fix hmm
	msg = "" + msg; 

	if(my->ToBoolean(2))
	{
		INVOKE(CGameRules::oohhFromClientTCP(), CGameRules::oohhNetMsgTCP(msg), eRMI_ToServer);
	}
	else
	{
		INVOKE(CGameRules::oohhFromClientUDP(), CGameRules::oohhNetMsgUDP(msg), eRMI_ToServer);
	}

	return 0;
}

LUALIB_FUNCTION(network, Connect)
{
	auto ip = my->ToString(1);
	auto port = my->ToNumber(2);

	// cleanly disconnect from any current game if there is any
	if (auto chan = gEnv->pGameFramework->GetClientChannel())
	{
		chan->Disconnect(eDC_UserRequested, "left");
	}

	// end the game context
	gEnv->pGameFramework->EndGameContext();

	// start a new one
	SGameStartParams params;
		params.hostname = ip;
		params.port = port;
		params.flags = eGSF_Client;
	gEnv->pGameFramework->StartGameContext(&params);

	return 0;
}

LUALIB_FUNCTION(network, Disconnect)
{
	if (auto chan = gEnv->pGameFramework->GetClientChannel())
	{
		chan->Disconnect(eDC_UserRequested, my->ToString(1, "no reason"));
	}

	gEnv->pGameFramework->EndGameContext();

	return 0;
}

LUALIB_FUNCTION(network, Host)
{
	auto map = my->ToString(3);
	auto port = my->ToNumber(2);

	gEnv->pSystem->GetISystemEventDispatcher()->OnSystemEvent(ESYSTEM_EVENT_LEVEL_LOAD_PREPARE, 0, 0);

	gEnv->pCryPak->TouchDummyFile("startlevelload");
	gEnv->pCryPak->GetFileReadSequencer()->StartSection(map);

	gEnv->pGameFramework->StartedGameContext();
	gEnv->pGameFramework->GetIGameSessionHandler();
	gEnv->pGameFramework->GetILevelSystem()->PrepareNextLevel(map);
		
	SGameContextParams ctx;
		ctx.gameRules = "DeathMatch";
		ctx.levelName = map;
		
	SGameStartParams params;
		params.flags = eGSF_Server;
		params.pContextParams = &ctx;
		params.port = port;
		params.maxPlayers = 512;

	gEnv->pGameFramework->StartGameContext(&params);

	return 0;
}

IMPLEMENT_RMI(CGameRules, oohhFromClientTCP)
{
	if (my)
	{
		auto ply = (CPlayer *)GetActorByChannelId(gEnv->pGame->GetIGameFramework()->GetGameChannelId(pNetChannel));
		
		if (ply)
		{
			my->CallHook("OnTCPMessageFromClient", ply, params.str);

			return true;
		}		
	}

	return false;
}

IMPLEMENT_RMI(CGameRules, oohhFromServerTCP)
{
	if (my)
	{
		my->CallHook("OnTCPMessageFromServer", params.str);

		return true;
	}

	return false;
}


IMPLEMENT_RMI(CGameRules, oohhFromClientUDP)
{
	if (my)
	{
		auto ply = (CPlayer *)GetActorByChannelId(gEnv->pGame->GetIGameFramework()->GetGameChannelId(pNetChannel));
		
		if (ply)
		{
			my->CallHook("OnUDPMessageFromClient", ply, params.str);

			return true;
		}		
	}

	return false;
}

IMPLEMENT_RMI(CGameRules, oohhFromServerUDP)
{
	if (my)
	{
		my->CallHook("OnUDPMessageFromServer", params.str);

		return true;
	}

	return false;
}