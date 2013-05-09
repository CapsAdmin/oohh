#include "StdAfx.h"
#include "oohh.hpp"


LUALIB_FUNCTION(timer, GetFrameTime)
{
	my->Push(gEnv->pTimer->GetFrameTime());

	return 1;
}

LUALIB_FUNCTION(timer, GetRealFrameTime)
{
	my->Push(gEnv->pTimer->GetRealFrameTime());

	return 1;
}

LUALIB_FUNCTION(timer, GetCurTime)
{
	my->Push(gEnv->pTimer->GetCurrTime());

	return 1;
}

LUALIB_FUNCTION(timer, GetAsyncCurTime)
{
	my->Push(gEnv->pTimer->GetAsyncCurTime());

	return 1;
}