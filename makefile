# NecroLua makefile for nmake.
# Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

# Configuration
EXENAME=NecroLua
DLLNAME=NecroLuaAPI
VERSION=0.2.0
ZIPNAME=$(EXENAME)-$(VERSION)

# ==============================================================================
# Internal settings. You should not need to edit anything beyond this point.

!IFNDEF RELEASE
RELEASE=0
!ENDIF
ZIPFILES=$(EXENAME).exe $(DLLNAME).dll README.md LICENSE.txt LEGAL.txt steam_appid.txt
DEFINES=/DEXENAME=\"$(EXENAME)\" /DDLLNAME=\"$(DLLNAME)\" /DRELEASE=$(RELEASE) /DVERSION=$(VERSION)
CFLAGS=/nologo /W3 /I include $(DEFINES)
LDFLAGS=/link /nologo /LIBPATH:lib
RFLAGS=/nologo $(DEFINES) /DVERSION=\"$(VERSION)\" /DUSERNAME=\"$(USERNAME)\" /DCOMPUTERNAME=\"$(COMPUTERNAME)\"
ZIP=zip -9lovu

# Phony.
all: $(EXENAME).exe $(DLLNAME).dll
release:
	cmd /C "set RELEASE=1 && $(MAKE) /nologo /$(MAKEFLAGS) $(ZIPNAME).zip"
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
	-del $(ZIPNAME).zip

# Release zipfile.
$(ZIPNAME).zip: $(ZIPFILES)
	$(ZIP) $(ZIPNAME).zip $**

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
nl_launcher.res: nl_launcher.rc

!IF $(RELEASE)
!MESSAGE Building RELEASE version $(VERSION)
nl_launcher.res: nl_launcher.ico
!ENDIF
