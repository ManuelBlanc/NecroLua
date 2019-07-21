# NecroLua makefile for nmake.
# Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

EXENAME=NecroLua
DLLNAME=NecroLuaAPI

DEFINES=/DEXENAME="\"$(EXENAME)\"" /DDLLNAME="\"$(DLLNAME)\""
CFLAGS=/nologo /W3 /I include $(DEFINES)
LDFLAGS=/link /nologo /LIBPATH:lib
RFLAGS=/nologo $(DEFINES)

# Phony.
all: $(EXENAME).exe $(DLLNAME).dll
test: all
	$(EXENAME) 0
clean:
	-del $(DLLNAME).dll
	-del $(DLLNAME).lib
	-del $(EXENAME).exe
	-del nl_launcher.ico
	-del nl_launcher.res
	-del *.exp
	-del *.obj

# Launcher.
$(EXENAME).exe: nl_launcher.obj nl_launcher.res
	$(CC) /Fe:$(EXENAME).exe $** $(LDFLAGS)

# Payload.
$(DLLNAME).dll: nl_payload.obj nl_luainit.obj
	$(CC) /Fe:$(DLLNAME).dll $** /LD $(LDFLAGS)

# Recipes.
.SUFFIXES: .png .lua
.png.ico:
	magick convert $< -define icon:auto-resize="256,128,64,48,32,16" $@
.lua.obj:
	luajit -bgn $(DLLNAME).init $< $@

# Dependencies.
nl_launcher.obj nl_payload.obj: nl_common.h
nl_launcher.res: nl_launcher.rc nl_launcher.ico
