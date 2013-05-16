#ifdef _DEBUG
#undef _ITERATOR_DEBUG_LEVEL
#define _ITERATOR_DEBUG_LEVEL 0
#endif

#include "..\mmyy.hpp"

#include <concrt.h>

#ifdef _DEBUG
#undef _ITERATOR_DEBUG_LEVEL
#define _ITERATOR_DEBUG_LEVEL 0
#endif

static bool supress = false;

const char *my_call(lua_State *L, int arguments, int results)
{
	if (!lua_isfunction(L, -(arguments+1)))
	{
		return "tried to call a non function";
	}

	if (lua_pcall(L, arguments, results, 0) != 0)
	{	
		auto err = lua_tostring(L, -1);
		lua_remove(L, -1);
		return err;
	}


	return 0;
}