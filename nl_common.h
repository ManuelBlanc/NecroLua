// Common code used in the launcher and payload.
// Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

#pragma once

#define NECRODANCER_APP_NAME "NecroDancer.exe"

#include <stdio.h>
#include <stdarg.h>
#define TRACE__(...) ((void)TRACE__printf(__FILE__, __LINE__, __VA_ARGS__))
void TRACE__printf(const char *file, int line, const char *fmt, ...)
{
	char msg[BUFSIZ];
	va_list args;
	va_start(args, fmt);
	size_t bytes = snprintf(msg, BUFSIZ, "["MODULENAME"] %s:%3i: ", file, line);
	bytes += vsnprintf(msg+bytes, BUFSIZ-bytes, fmt, args);
	msg[bytes++] = '\n';
	msg[bytes++] = '\0';
	fputs(msg, stderr);
	va_end(args);
}
