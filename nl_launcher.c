// Small wrapper that injects the DLL.
// Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

// Windows.
#include <windows.h>
#pragma comment(lib,"user32.lib")
// Detours.
#include "detours.h"
#pragma comment(lib,"detours.lib")
// User.
#define MODULENAME "\x1B[31m"EXENAME".exe\x1B[0m"
#include "nl_common.h"

int main(int argc, char** argv)
{
	HANDLE hOut = GetStdHandle(STD_ERROR_HANDLE);
	HANDLE hErr = GetStdHandle(STD_ERROR_HANDLE);
	DWORD dwModeOut, dwModeErr;
	GetConsoleMode(hOut, &dwModeOut);
	GetConsoleMode(hErr, &dwModeErr);
	SetConsoleMode(hOut, dwModeOut | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
	SetConsoleMode(hErr, dwModeErr | ENABLE_VIRTUAL_TERMINAL_PROCESSING);

	CHAR *rlpDlls[1] = { DLLNAME".dll" };
	STARTUPINFO si = { 0, .cb = sizeof(si) };
	PROCESS_INFORMATION pi = { 0 };
	TRACE__("DetourCreateProcessWithDlls on %s with %s ...", NECRODANCER_APP_NAME, *rlpDlls);
	if (!DetourCreateProcessWithDlls(
		NECRODANCER_APP_NAME, // lpApplicationName
		GetCommandLine(), // lpCommandLine
		NULL, // lpProcessAttributes
		NULL, // lpThreadAttributes
		TRUE, // bInheritHandles
		0, // dwCreationFlags
		NULL, // lpEnvironment
		NULL, // lpCurrentDirectory
		&si, // lpStartupInfo
		&pi, // lpProcessInformation
		1, // nDlls
		rlpDlls, // rlpDlls
		NULL // pfCreateProcessW
	)) {
		MessageBox(0, "Could not launch "NECRODANCER_APP_NAME, *argv, MB_ICONERROR);
		return;
	}
	TRACE__("Game started.");
	//TRACE__("Assigning child process to a job ...");
	//HANDLE hJob = CreateJobObjectA(NULL, NULL);
	//JOBOBJECT_BASIC_LIMIT_INFORMATION jobObjInfo = { 0, .LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE };
	//SetInformationJobObject(hJob, JobObjectBasicLimitInformation, &jobObjInfo, sizeof(jobObjInfo));
	//AssignProcessToJobObject(hJob, pi.hProcess);
	TRACE__("WaitForSingleObject ...");
	WaitForSingleObject(pi.hProcess, INFINITE);
	int exit_code;
	GetExitCodeProcess(pi.hProcess, &exit_code);
	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);
	TRACE__("Done with exit code 0x%08X", exit_code);

	SetConsoleMode(hOut, dwModeOut);
	SetConsoleMode(hErr, dwModeErr);
	return exit_code;
}
