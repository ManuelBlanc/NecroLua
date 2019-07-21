// Small wrapper that injects the DLL.
// Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

// Windows.
#include <windows.h>
#pragma comment(lib,"user32.lib")
// Detours.
#include <detours.h>
#pragma comment(lib,"detours.lib")
// User.
#define MODULENAME EXENAME".exe"
#include "nl_common.h"

int main(int argc, char** argv)
{
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
	return exit_code;
}
