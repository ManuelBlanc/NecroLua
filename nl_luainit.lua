-- Lua-side API using the LuaJIT FFI.
-- Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

-- Imports.
local ffi = require("ffi")
local cast, new, sizeof = ffi.cast, ffi.new, ffi.sizeof
local C = ffi.C
local format, concat, gsub = string.format, table.concat, string.gsub
local getinfo, stderr = debug.getinfo, io.stderr

-- Fix Lua IO.  http://www.boku.ru/2016/02/28/posting-to-console-from-gui-app/
ffi.cdef[[void *freopen(const char *path, const char *mode, void *stream);]]
C.freopen("CON", "w", cast("void*", io.stdout))
C.freopen("CON", "r", cast("void*", io.stdin ))
C.freopen("CON", "w", cast("void*", io.stderr))

local DLLNAME = _DLLNAME -- Global set on the C side.

local function TRACE__(...)
  local info = getinfo(2, "lSf")
  return stderr:write(format("[%s.dll][Lua] %s:%3d: %s\n", DLLNAME, info.short_src, info.currentline, format(...)))
end

-- Windows.
ffi.cdef[[
  typedef int           BOOL;
  typedef long          LONG;
  typedef unsigned long ULONG;
  typedef uint64_t      ULONG64;
  typedef unsigned long DWORD;
  typedef uint64_t      DWORD64;
  typedef void         *PVOID;
  typedef PVOID         HANDLE;
  typedef wchar_t       WCHAR;
  typedef char          CHAR;
  typedef const CHAR   *PCSTR;

  void *LocalAlloc(unsigned int, size_t);
  void *LocalFree(void *);
  size_t wcslen(const wchar_t *str);
  size_t wcstombs(char *mbstr, const wchar_t *wcstr, size_t count);
]]

-- Convert a wide-character string to multibyte string.
local function wstr2str(ws)
  local len = C.wcslen(ws)
  local buf = new("char[?]", len)
  C.wcstombs(buf, ws, len)
  return ffi.string(buf, len)
end

-- NecroLuaAPI.
local NLAPI = ffi.load(DLLNAME)
ffi.cdef[[
  HANDLE nl_hProcess;
  DWORD64 nl_BaseOfDll;
  LONG nl_attach(PVOID *ppPointer, PVOID pDetour);
  LONG nl_detach(PVOID *ppPointer, PVOID pDetour);
]]

-- Symbol manipulation.
local Dbghelp = ffi.load("Dbghelp")
ffi.cdef[[
  typedef struct _SYMBOL_INFO {
    ULONG   SizeOfStruct;
    ULONG   TypeIndex;
    ULONG64 Reserved[2];
    ULONG   Index;
    ULONG   Size;
    ULONG64 ModBase;
    ULONG   Flags;
    ULONG64 Value;
    ULONG64 Address;
    ULONG   Register;
    ULONG   Scope;
    ULONG   Tag;
    ULONG   NameLen;
    ULONG   MaxNameLen;
    CHAR    Name[1];
  } SYMBOL_INFO, *PSYMBOL_INFO;
  enum SymTagEnum {
    SymTagNull, SymTagExe, SymTagCompiland, SymTagCompilandDetails, SymTagCompilandEnv, SymTagFunction, SymTagBlock, SymTagData, SymTagAnnotation, SymTagLabel, SymTagPublicSymbol, SymTagUDT, SymTagEnum, SymTagFunctionType, SymTagPointerType, SymTagArrayType, SymTagBaseType, SymTagTypedef, SymTagBaseClass, SymTagFriend, SymTagFunctionArgType, SymTagFuncDebugStart, SymTagFuncDebugEnd, SymTagUsingNamespace, SymTagVTableShape, SymTagVTable, SymTagCustom, SymTagThunk, SymTagCustomType, SymTagManagedType, SymTagDimension,
  };
  typedef enum _IMAGEHLP_SYMBOL_TYPE_INFO {
    TI_GET_SYMTAG, TI_GET_SYMNAME, TI_GET_LENGTH, TI_GET_TYPE, TI_GET_TYPEID, TI_GET_BASETYPE, TI_GET_ARRAYINDEXTYPEID, TI_FINDCHILDREN, TI_GET_DATAKIND, TI_GET_ADDRESSOFFSET, TI_GET_OFFSET, TI_GET_VALUE, TI_GET_COUNT, TI_GET_CHILDRENCOUNT, TI_GET_BITPOSITION, TI_GET_VIRTUALBASECLASS, TI_GET_VIRTUALTABLESHAPEID, TI_GET_VIRTUALBASEPOINTEROFFSET, TI_GET_CLASSPARENTID, TI_GET_NESTED, TI_GET_SYMINDEX, TI_GET_LEXICALPARENT, TI_GET_ADDRESS, TI_GET_THISADJUST, TI_GET_UDTKIND, TI_IS_EQUIV_TO, TI_GET_CALLING_CONVENTION, TI_IS_CLOSE_EQUIV_TO, TI_GTIEX_REQS_VALID, TI_GET_VIRTUALBASEOFFSET, TI_GET_VIRTUALBASEDISPINDEX, TI_GET_IS_REFERENCE, TI_GET_INDIRECTVIRTUALBASECLASS, TI_GET_VIRTUALBASETABLETYPE,
    IMAGEHLP_SYMBOL_TYPE_INFO_MAX,
  } IMAGEHLP_SYMBOL_TYPE_INFO;
  typedef struct _TI_FINDCHILDREN_PARAMS {
    ULONG Count;
    ULONG Start;
    ULONG ChildId[1];
  } TI_FINDCHILDREN_PARAMS;
  enum CV_call_e {
    CV_CALL_NEAR_C    = 0x00,
    CV_CALL_NEAR_FAST = 0x04,
    CV_CALL_NEAR_STD  = 0x07,
    CV_CALL_NEAR_SYS  = 0x09,
    CV_CALL_THISCALL  = 0x0b,
    CV_CALL_CLRCALL   = 0x16,
  };
  enum UdtKind {
    UdtStruct,
    UdtClass,
    UdtUnion,
  };
  enum BasicType {
    btNoType   = 0,
    btVoid     = 1,
    btChar     = 2,
    btWChar    = 3,
    btInt      = 6,
    btUInt     = 7,
    btFloat    = 8,
    btBCD      = 9,
    btBool     = 10,
    btLong     = 13,
    btULong    = 14,
    btCurrency = 25,
    btDate     = 26,
    btVariant  = 27,
    btComplex  = 28,
    btBit      = 29,
    btBSTR     = 30,
    btHresult  = 31,
    btChar16   = 32,
    btChar32   = 33,
  };
  typedef BOOL (__stdcall *PSYM_ENUMERATESYMBOLS_CALLBACK)(PSYMBOL_INFO, ULONG, PVOID);
  BOOL SymEnumSymbols(
    HANDLE                         hProcess,
    ULONG64                        BaseOfDll,
    PCSTR                          Mask,
    PSYM_ENUMERATESYMBOLS_CALLBACK EnumSymbolsCallback,
    PVOID                          UserContext
  );
  BOOL SymEnumTypesByName(
    HANDLE                         hProcess,
    ULONG64                        BaseOfDll,
    PCSTR                          Mask,
    PSYM_ENUMERATESYMBOLS_CALLBACK EnumSymbolsCallback,
    PVOID                          UserContext
  );
  BOOL SymFromName(
    HANDLE       hProcess,
    PCSTR        Name,
    PSYMBOL_INFO Symbol
  );
  BOOL SymSearch(
    HANDLE                         hProcess,
    ULONG64                        BaseOfDll,
    DWORD                          Index,
    DWORD                          SymTag,
    PCSTR                          Mask,
    DWORD64                        Address,
    PSYM_ENUMERATESYMBOLS_CALLBACK EnumSymbolsCallback,
    PVOID                          UserContext,
    DWORD                          Options
  );
  BOOL SymGetTypeInfo(
    HANDLE                    hProcess,
    DWORD64                   ModBase,
    ULONG                     TypeId,
    IMAGEHLP_SYMBOL_TYPE_INFO GetType,
    PVOID                     pInfo
  );
]]

local SYMTAG_LOOKUP = { [0] = "Null", "Exe", "Compiland", "CompilandDetails", "CompilandEnv", "Function", "Block", "Data", "Annotation", "Label", "PublicSymbol", "UDT", "Enum", "FunctionType", "PointerType", "ArrayType", "BaseType", "Typedef", "BaseClass", "Friend", "FunctionArgType", "FuncDebugStart", "FuncDebugEnd", "UsingNamespace", "VTableShape", "VTable", "Custom", "Thunk", "CustomType", "ManagedType", "Dimension" }

-- https://docs.microsoft.com/en-us/visualstudio/debugger/debug-interface-access/cv-call-e
local CV_LOOKUP = {
  [Dbghelp.CV_CALL_NEAR_C] = "__cdecl",
  [Dbghelp.CV_CALL_NEAR_FAST] = "__fastcall",
  [Dbghelp.CV_CALL_NEAR_STD] = "__stdcall",
  --[Dbghelp.CV_CALL_NEAR_SYS] = "?UNKNOWN",
  [Dbghelp.CV_CALL_THISCALL] = "__stdcall" -- Compatible.
}
-- https://docs.microsoft.com/en-us/visualstudio/debugger/debug-interface-access/basictype
local BT_LOOKUP = {
  [Dbghelp.btNoType] = nil,
  [Dbghelp.btVoid] = "void",
  [Dbghelp.btChar] = "char",
  [Dbghelp.btWChar] = "wchar_t",
  [Dbghelp.btInt] = "int",
  [Dbghelp.btUInt] = "unsigned int",
  [Dbghelp.btFloat] = "float",
  --[Dbghelp.btBCD]
  [Dbghelp.btBool] = "bool",
  [Dbghelp.btLong] = "long",
  [Dbghelp.btULong] = "unsigned long",
  --[Dbghelp.btCurrency]
  --[Dbghelp.btDate]
  --[Dbghelp.btVariant]
  --[Dbghelp.btComplex]
  --[Dbghelp.btBit]
  --[Dbghelp.btBSTR]
  --[Dbghelp.btHresult] --> HRESULT --> LONG --> long
  --[Dbghelp.btChar16]
  --[Dbghelp.btChar32]
};

-- Enumerate throgh symbols and types.
local enum_allowed = true
local enum_cb = cast("PSYM_ENUMERATESYMBOLS_CALLBACK", function() end) -- args: pSymInfo, SymbolSize, UserContext
local function necrolua_enumsymbols(mask, cb)
  assert(enum_allowed)
  enum_allowed = false
  enum_cb:set(cb)
  Dbghelp.SymEnumSymbols(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, mask or "*", enum_cb, nil)
  enum_allowed = true
end
local function necrolua_enumtypes(mask, cb)
  enum_cb:set(cb)
  enum_allowed = false
  Dbghelp.SymEnumTypesByName(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, mask or "*", enum_cb, nil)
  enum_allowed = true
end

-- Get the name of a type, performing a wchar_t to char conversion.
local function necrolua_typename(index)
  local symname = new("WCHAR*[1]")
  local ret = Dbghelp.SymGetTypeInfo(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, index, Dbghelp.TI_GET_SYMNAME, symname)
  if ret == 0 then return "ERROR" end
  local name = wstr2str(symname[0])
  C.LocalFree(symname[0])
  return name
end

-- Get the value of a DWORD attribute.
local dword_buf = new("DWORD[1]")
local function necrolua_typedword(index, key)
  Dbghelp.SymGetTypeInfo(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, index, key, dword_buf)
  return dword_buf[0]
end

-- Retrieve an array with the type indexes of all children.
local function necrolua_typechildren(index)
  local children = {}
  local childcount = necrolua_typedword(index, Dbghelp.TI_GET_CHILDRENCOUNT)
  if childcount == 0 then return children end
  local size = sizeof("TI_FINDCHILDREN_PARAMS") + childcount * sizeof("ULONG")
  local pFC = cast("TI_FINDCHILDREN_PARAMS*", C.LocalAlloc(0, size))
  pFC.Start = 0
  pFC.Count = childcount
  Dbghelp.SymGetTypeInfo(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, index, Dbghelp.TI_FINDCHILDREN, pFC)
  for i=1, pFC.Count do children[i] = pFC.ChildId[i-1] end
  C.LocalFree(pFC)
  return children
end

-- Convert a type to a string.
local function necrolua_typeinfo(index, name)
  local symtag = necrolua_typedword(index, Dbghelp.TI_GET_SYMTAG)

  if symtag == Dbghelp.SymTagFunctionType then -- Function prototype.
    local callconv = necrolua_typedword(index, Dbghelp.TI_GET_CALLING_CONVENTION)
    local rettype = necrolua_typedword(index, Dbghelp.TI_GET_TYPE)
    local arity = necrolua_typedword(index, Dbghelp.TI_GET_COUNT)
    local args = necrolua_typechildren(index)
    for i, a in ipairs(args) do args[i] = necrolua_typeinfo(a) end
    return format("%s %s (*%s)(%s)",
      CV_LOOKUP[callconv], necrolua_typeinfo(rettype), name, concat(args, ", ")
    )

  elseif symtag == Dbghelp.SymTagFunction then -- Function.
    local functype = necrolua_typedword(index, Dbghelp.TI_GET_TYPE)
    local funcname = necrolua_typename(index)
    return necrolua_typeinfo(functype, name or funcname)

  elseif symtag == Dbghelp.SymTagFunctionArgType then -- Argument.
    return necrolua_typeinfo(necrolua_typedword(index, Dbghelp.TI_GET_TYPE))

  elseif symtag == Dbghelp.SymTagPointerType then -- Pointer.
    return necrolua_typeinfo(necrolua_typedword(index, Dbghelp.TI_GET_TYPE)).."*"

  elseif symtag == Dbghelp.SymTagData then -- Datum.
    return necrolua_typeinfo(necrolua_typedword(index, Dbghelp.TI_GET_TYPE))

  elseif symtag == Dbghelp.SymTagArrayType then -- Array.
    local subtype = necrolua_typedword(index, Dbghelp.TI_GET_TYPE)
    local count = necrolua_typedword(index, Dbghelp.TI_GET_COUNT)
    return format("%s[%d]", necrolua_typeinfo(subtype, name), count)

  elseif symtag == Dbghelp.SymTagTypedef then -- Type definition (typedef).
    return necrolua_typename(index)

  elseif symtag == Dbghelp.SymTagUDT then -- User Data Type (class/struct/union)
  return necrolua_typename(index)  -- UdtStruct UdtClass UdtUnion

  elseif symtag == Dbghelp.SymTagPublicSymbol then
    return necrolua_typeinfo(necrolua_typedword(index, Dbghelp.TI_GET_TYPE))

  elseif symtag == Dbghelp.SymTagBaseType then
    return BT_LOOKUP[necrolua_typedword(index, Dbghelp.TI_GET_BASETYPE)]
  end

  error("Invalid SymTag: " .. SYMTAG_LOOKUP[symtag])
end

-- Find a symbol index.
local function necrolua_symbol(name)
  local symbol_info = new("SYMBOL_INFO[1]")
  symbol_info[0].SizeOfStruct = sizeof("SYMBOL_INFO")
  symbol_info[0].MaxNameLen = 0
  local ok = Dbghelp.SymFromName(NLAPI.nl_hProcess, name, symbol_info)
  return ok ~= 0 and symbol_info[0]
end

-- Get the value of a symbol.
local function necrolua_get(mask)
  local symbol_info = necrolua_symbol(mask)
  assert(symbol_info, "Symbol not found: " .. mask)
  local index = symbol_info.Index
  local typedef = necrolua_typeinfo(index, "")
  local addr = necrolua_typedword(index, Dbghelp.TI_GET_ADDRESS)
  TRACE__("necrolua_get :: cast(%q, %s)", typedef, addr)
  return cast(typedef, addr)
end

-- Attach a detour to a function.
local function necrolua_attach(mask, handler)
  local symbol_info = necrolua_symbol(mask)
  assert(symbol_info, "Symbol not found: " .. mask)
  local index = symbol_info.Index
  local typedef = necrolua_typeinfo(index, "")
  local addr = necrolua_typedword(index, Dbghelp.TI_GET_ADDRESS)
  TRACE__("necrolua_attach :: NLAPI.nl_attach(cast(%q, %s), %s)", typedef, addr, tostring(handler))
  local ppPointer = new("PVOID[1]", cast("PVOID", addr))
  local pDetour = cast(typedef, handler)
  NLAPI.nl_attach(ppPointer, pDetour)
  return cast(typedef, ppPointer[0])
end

-- Detach a detour from a function.
local function necrolua_detach(mask, handler)
  local symbol_info = necrolua_symbol(mask)
  assert(symbol_info, "Symbol not found: " .. mask)
  local index = symbol_info.Index
  local typedef = necrolua_typeinfo(index, "")
  local addr = necrolua_typedword(index, Dbghelp.TI_GET_ADDRESS)
  TRACE__("NLAPI.nl_detach(cast(%q, %s), %s)", typedef, addr, tostring(handler))
  local ppPointer = new("PVOID[1]", cast("PVOID", addr))
  local pDetour = cast(typedef, handler)
  NLAPI.nl_detach(ppPointer, pDetour)
  return cast(typedef, ppPointer[0])
end

-- Advice-like hooking [chaining NYI].
local _hook_registry = {}
local function necrolua_hook(mask, handler)
  if not _hook_registry[mask] then
    local orig = necrolua_attach(mask, function(...)
      return _hook_registry[mask](...) -- Dynamically get the last one.
    end)
    _hook_registry[mask] = orig
  end
  local prev = _hook_registry[mask]
  _hook_registry[mask] = function(...)
    return handler(prev, ...)
  end
end

-- Exports (as global).
necrolua = {
  enumsymbols   = necrolua_enumsymbols,
  enumtypes     = necrolua_enumtypes,
  typename      = necrolua_typename,
  typedword     = necrolua_typedword,
  typechildren  = necrolua_typechildren,
  typeinfo      = necrolua_typeinfo,
  symbol        = necrolua_symbol,
  attach        = necrolua_attach,
  detach        = necrolua_detach,
  hook          = necrolua_hook,
  get           = necrolua_get,
}
TRACE__("%s.init mod API loaded.", DLLNAME)


local entrypoint = "mods/init.lua"
TRACE__("Running user entrypoint (%q) ...", entrypoint)
dofile(entrypoint) -- [TMP] User code entrypoint.
