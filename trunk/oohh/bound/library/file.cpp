#include "StdAfx.h"
#include "oohh.hpp"
#include "ICryPak.h"

string base = "../";

LUALIB_FUNCTION(pak, OpenPacks)
{
	my->Push(gEnv->pCryPak->OpenPacks(my->ToString(1), ICryPak::FLAGS_PATH_REAL));

    return 1;
}


LUALIB_FUNCTION(pak, SetAlias)
{
	gEnv->pCryPak->SetAlias(my->ToString(1), my->ToString(2), true);

    return 0;
}

LUALIB_FUNCTION(pak, RemoveAlias)
{
	gEnv->pCryPak->SetAlias(my->ToString(1), my->ToString(2), false);

    return 0;
}

LUALIB_FUNCTION(pak, OpenPack)
{
    my->Push(gEnv->pCryPak->OpenPack(my->ToString(1)));

    return 1;
}
LUALIB_FUNCTION(pak, ClosePack)
{
    my->Push(gEnv->pCryPak->ClosePack(my->ToString(1)));

    return 1;
}

LUALIB_FUNCTION(pak, DoesFIleExist)
{
    my->Push(gEnv->pCryPak->IsFileExist(my->ToString(1)));

    return 1;
}
    
LUALIB_FUNCTION(pak, Find)
{
    _finddata_t fd;
    intptr_t handle = gEnv->pCryPak->FindFirst(my->ToString(1), &fd);

    my->NewTable();

    if (handle > -1)
    {
        int index = 0;

        do
        {
            index ++;

            string name = fd.name;

            if (name == (string)"." || name == (string)"..") continue;

            my->Push((const char *)name);

            my->NewTable();
				my->SetMember(-1, "attribute", (int)fd.attrib);
				my->SetMember(-1, "name", name);
				my->SetMember(-1, "size", (int)fd.size);
				my->SetMember(-1, "accessed", (int)fd.time_access);
				my->SetMember(-1, "created", (int)fd.time_create);
				my->SetMember(-1, "modified", (int)fd.time_write);
            my->SetTable(-3);

        } while (gEnv->pCryPak->FindNext(handle, &fd) >= 0);
    }

    return 1;
}