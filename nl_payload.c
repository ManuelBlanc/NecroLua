// NecroLua mod API payload.
// Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

// Standard libraries.
#define _CRT_SECURE_NO_WARNINGS 1
#include <stdio.h>
// Windows.
#include <windows.h>
#include <psapi.h>
// Detours
#include <detours.h>
#pragma comment(lib,"detours.lib")
// Lua.
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "luajit.h"
#pragma comment(lib,"lua51.lib")
// DbgHelp
#include <dbghelp.h>
#pragma comment(lib,"Dbghelp.lib")
// User.
#define MODULENAME "\x1B[33m"DLLNAME".dll\x1B[0m"
#include "nl_common.h"

// Globals.
static lua_State *nl_L;

__declspec(dllexport) HANDLE nl_hProcess;
__declspec(dllexport) DWORD64 nl_BaseOfDll;

__declspec(dllexport) LONG nl_attach(PVOID *ppPointer, PVOID pDetour)
{
	DetourTransactionBegin();
	DetourUpdateThread(GetCurrentThread());
	LONG ret = DetourAttach(ppPointer, pDetour);
	DetourTransactionCommit();
	return ret;
}

__declspec(dllexport) LONG nl_detach(PVOID *ppPointer, PVOID pDetour)
{
	DetourTransactionBegin();
	DetourUpdateThread(GetCurrentThread());
	LONG ret = DetourDetach(ppPointer, pDetour);
	DetourTransactionCommit();
	return ret;
}

static int nlP_traceback(lua_State *L)
{
	luaL_traceback(L, L, lua_tostring(L, 1), 1); // Lua 5.2
	return 1;
}


static DWORD WINAPI nlP_initialize(LPVOID ptr)
{
	// Attach to the parent's console.
	if (!GetConsoleWindow()) {
		AttachConsole(ATTACH_PARENT_PROCESS);
#define _CRT_SECURE_NO_WARNINGS 1
		freopen("CON", "w", stdout);
		freopen("CON", "r", stdin );
		freopen("CON", "w", stderr);
#undef _CRT_SECURE_NO_WARNINGS
	}

	TRACE__("Opening the Lua state ...");
	lua_State *L = nl_L = luaL_newstate();
	luaL_openlibs(L);
	lua_pushliteral(L, DLLNAME);
	lua_setglobal(L, "_DLLNAME");

	TRACE__("Preparing the symbol API ...");
	nl_hProcess = GetCurrentProcess();
	SymInitialize(nl_hProcess, NULL, FALSE);
	MODULEINFO modinfo; //lpBaseOfDll//SizeOfImage//EntryPoint
	GetModuleInformation(nl_hProcess, GetModuleHandle(NULL), &modinfo, sizeof(modinfo));
	nl_BaseOfDll = SymLoadModuleEx(
		nl_hProcess, NULL, "NecroDancer.pdb", NULL,
		(DWORD64)modinfo.lpBaseOfDll, modinfo.SizeOfImage,
		NULL, 0);
	TRACE__("BaseOfExe is 0x%08X", nl_BaseOfDll);

	TRACE__("Initializing the Lua environment ...");
	TRACE__("Top : %d", lua_gettop(L));
	lua_pushcfunction(L, &nlP_traceback);
	lua_getglobal(L, "require");
	lua_pushliteral(L, DLLNAME".init");
	if (lua_pcall(L, 1, 0, 1)) {
		TRACE__("Lua error: %s\n", lua_tostring(L, -1));
		exit(EXIT_FAILURE);
	}

	lua_settop(L, 0);
	TRACE__("Mods initialized.");
	return 0;
}

static DWORD WINAPI nlP_finalize(LPVOID ptr)
{
	// We don't cleanup because the unloading can result in a deadlock.

	//TRACE__("Closing Lua and unloading symbols ...");
	//lua_close(nl_L);
	//SymUnloadModule(nl_hProcess, (DWORD)nl_BaseOfDll);
	//SymCleanup(nl_hProcess);
	TRACE__("Mod API finalized.");
	return 0;
}

BOOL WINAPI DllMain(HMODULE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
	if (DetourIsHelperProcess()) return TRUE;

	switch (fdwReason) {
	case DLL_PROCESS_ATTACH:
		DetourRestoreAfterWith();
		DisableThreadLibraryCalls(hinstDLL);
		nlP_initialize(NULL); // This is very unsafe.
		break;
	case DLL_PROCESS_DETACH:
		nlP_finalize(NULL);
		break;
	case DLL_THREAD_ATTACH:
	case DLL_THREAD_DETACH:
		break;
	}

	return TRUE;
}
