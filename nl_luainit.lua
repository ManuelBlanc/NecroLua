-- Lua-side API using the LuaJIT FFI.
-- Copyright (C) 2019 Manuel Blanc. See Copyright Notice in LICENSE.txt

-- Imports.
local ffi = require("ffi")
local cast, new, sizeof = ffi.cast, ffi.new, ffi.sizeof
local C = ffi.C
local format, gsub, match, concat = string.format, string.gsub, string.match, table.concat
local getinfo, traceback, stderr = debug.getinfo, debug.traceback, io.stderr

-- Fix Lua IO.  http://www.boku.ru/2016/02/28/posting-to-console-from-gui-app/
ffi.cdef[[void *freopen(const char *path, const char *mode, void *stream);]]
C.freopen("CON", "w", cast("void*", io.stdout))
C.freopen("CON", "r", cast("void*", io.stdin ))
C.freopen("CON", "w", cast("void*", io.stderr))

local DLLNAME = _DLLNAME -- Set on the DLL.

local function TRACE__(...)
  local info = getinfo(2, "lSf")
  return stderr:write(format("[\x1B[33m%s.dll\x1B[0m][\x1B[32mLua\x1B[0m] %s:%3d: %s\n",
    DLLNAME, info.short_src, info.currentline, format(...)))
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
  DWORD tempGetLastError();
  DWORD tempPrintLastError();
  typedef void CxxClass;
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
  BOOL SymGetTypeFromName(
    HANDLE       hProcess,
    ULONG64      BaseOfDll,
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
  [Dbghelp.CV_CALL_THISCALL] = "__thiscall" -- Compatible.
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

-- Add the NameLuaStr property to get the name as a Lua string.
ffi.metatype("SYMBOL_INFO", {
  __index = function(si, key)
    if key == "NameLuaStr" then return ffi.string(si.Name, si.NameLen) end
  end,
})

-- Enumerate through symbols and types. We re-use the same callback.
-- Caveat: cannot enumerate while already performing an enumeration.
local enum_allowed, enum_cb, enum_err = true
local enum_cb_trampoline = cast("PSYM_ENUMERATESYMBOLS_CALLBACK", function(pSymInfo, SymbolSize, UserContext)
  local si_table = SYMBOL_INFO_to_table(pSymInfo)
  local ok, val = xpcall(enum_cb, traceback, si_table, SymbolSize)
  if ok then return val ~= false end
  enum_err = val
  return false
end)
local function nlP_doenum(method, mask, cb)
  assert(enum_allowed, "Cannot nest symbol/type enumerations.")
  enum_allowed, enum_err, enum_cb = false, nil, cb
  Dbghelp.SymEnumSymbols(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, mask or "*", enum_cb, nil)
  if enum_err then error(enum_err) end
  enum_allowed = true
end
local function nl_enumsymbols(mask, cb)
  return nlP_doenum(Dbghelp.SymEnumSymbols, mask, cb)
end
local function nl_enumtypes(mask, cb)
  return nlP_doenum(Dbghelp.SymEnumTypesByName, mask, cb)
end

-- Get the name of a type, performing a wchar_t to char conversion.
local function nl_typename(index)
  local symname = new("WCHAR*[1]")
  local ret = Dbghelp.SymGetTypeInfo(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, index, Dbghelp.TI_GET_SYMNAME, symname)
  if ret == 0 then return "ERROR" end
  local name = wstr2str(symname[0])
  C.LocalFree(symname[0])
  return name
end

-- Get the value of a DWORD attribute.
local dword_buf = new("DWORD[1]")
local function nl_typedword(index, key)
  Dbghelp.SymGetTypeInfo(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, index, key, dword_buf)
  return dword_buf[0]
end

-- Retrieve an array with the type indexes of all children.
local function nl_typechildren(index)
  local children = {}
  local childcount = nl_typedword(index, Dbghelp.TI_GET_CHILDRENCOUNT)
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

local _ctype_registry = {}
local function nl_ctype(name)
  name = gsub(name, "%W", "_") -- Remove invalid characters.
  if match(name, "^%A") then name = "_"..name end
  if not _ctype_registry[name] then
    local typedef = format("typedef struct %s {} %s;", name, name)
    --TRACE__("nl_ctype :: %q -> %q", name, typedef)
    ffi.cdef(typedef)
    _ctype_registry[name] = ffi.typeof(name)
  end
  return _ctype_registry[name]
end

-- Convert a type to a string.
local function nl_typedef(index, name, class)
  name = name or ""
  local symtag = nl_typedword(index, Dbghelp.TI_GET_SYMTAG)

  if symtag == Dbghelp.SymTagFunctionType then -- Function prototype.
    local callconv = nl_typedword(index, Dbghelp.TI_GET_CALLING_CONVENTION)
    local rettype = nl_typedword(index, Dbghelp.TI_GET_TYPE)
    local arity = nl_typedword(index, Dbghelp.TI_GET_COUNT)
    local args = nl_typechildren(index)
    for i, a in ipairs(args) do args[i] = nl_typedef(a) end
    if arity == #args + 1 then
      local this = class or (name and match(name, "([^:]+)::")) or "CxxClass"
      table.insert(args, 1, this.."*")
    end
    return format("%s %s (*%s)(%s)",
      CV_LOOKUP[callconv], nl_typedef(rettype), name or "", concat(args, ", ")
    )

  elseif symtag == Dbghelp.SymTagFunction then -- Function.
    return nl_typedef(nl_typedword(index, Dbghelp.TI_GET_TYPE), name or nl_typename(index), class)

  elseif symtag == Dbghelp.SymTagFunctionArgType then -- Argument.
    return nl_typedef(nl_typedword(index, Dbghelp.TI_GET_TYPE))

  elseif symtag == Dbghelp.SymTagPointerType then -- Pointer.
    return nl_typedef(nl_typedword(index, Dbghelp.TI_GET_TYPE)).."*"

  elseif symtag == Dbghelp.SymTagData then -- Datum.
    return nl_typedef(nl_typedword(index, Dbghelp.TI_GET_TYPE))

  elseif symtag == Dbghelp.SymTagArrayType then -- Array.
    local subtype = nl_typedword(index, Dbghelp.TI_GET_TYPE)
    local count = nl_typedword(index, Dbghelp.TI_GET_COUNT)
    return nl_typedef(subtype, format("%s[%d]", name))

  elseif symtag == Dbghelp.SymTagTypedef then -- Type definition (typedef).
    return nl_typename(index)

  elseif symtag == Dbghelp.SymTagUDT then -- User Data Type (class/struct/union)
    local name = nl_typename(index)
    nl_ctype(name)
    return name -- UdtStruct UdtClass UdtUnion

  elseif symtag == Dbghelp.SymTagPublicSymbol then
    return nl_typedef(nl_typedword(index, Dbghelp.TI_GET_TYPE))

  elseif symtag == Dbghelp.SymTagBaseType then
    return BT_LOOKUP[nl_typedword(index, Dbghelp.TI_GET_BASETYPE)]
  end

  error("Invalid SymTag: " .. SYMTAG_LOOKUP[symtag])
end

local _metatype_registry = {}
local function nl_metatype(index)
  if _metatype_registry[index] then return _metatype_registry[index] end
  _metatype_registry[index] = true -- Prevent recursion. (TMP)
  local name = nl_typename(index)
  --TRACE__("nl_metatype :: %q", name)
  local symtag = nl_typedword(index, Dbghelp.TI_GET_SYMTAG)
  local kind = nl_typedword(index, Dbghelp.TI_GET_DATAKIND)
  assert(Dbghelp.SymTagUDT == symtag, SYMTAG_LOOKUP[symtag])
  local ctype = nl_ctype(name)
  local ctype_ptr = ffi.typeof("$*", ctype)
  local m_offsets, m_ctypes = {}, {}
  local m_methods = {}
  local bc_offset, bc_lookup
  for i, child in ipairs(nl_typechildren(index)) do
    local symtag = nl_typedword(child, Dbghelp.TI_GET_SYMTAG)

    if symtag == Dbghelp.SymTagData then -- Member fields.
      local fieldname = nl_typename(child)
      --TRACE__("Member %q", fieldname)
      m_offsets[fieldname] = nl_typedword(child, Dbghelp.TI_GET_OFFSET)
      m_ctypes[fieldname] = nl_ctype(child)

    elseif symtag == Dbghelp.SymTagFunction then -- Functions.
      local funcname = nl_typename(child)
      funcname = match(funcname, "::(.*)$") or funcname
      local addr = nl_typedword(child, Dbghelp.TI_GET_ADDRESS)
      local typedef = nl_typedef(child, nil, name)
      --TRACE__("Method %q -> %q", funcname, typedef)
      local cfunc = cast(typedef, addr)
      m_methods[funcname] = function(self, ...)
        return cfunc(cast(ctype_ptr, self), ...)
      end

    elseif symtag == Dbghelp.SymTagBaseClass then -- Base class.
      --assert(not bc_lookup)
      local bcindex = nl_typedword(child, Dbghelp.TI_GET_TYPE)
      --TRACE__("Base class %q", nl_typename(bcindex))
      --bc_offset = nl_typedword(child, Dbghelp.TI_GET_OFFSET)
      --bc_lookup = nl_metatype(bcindex).__index
    end
  end

  local mt = {
    ctype = ctype, ctype_ptr = ctype_ptr,
    __index = function(base, key)
      --TRACE__("%s.__index(%q, %q)", class, base, key)
      if m_methods[key] then return m_methods[key] end
      local off = m_offsets[key]
      if off then return cast(m_ctypes[key], base + off)
      elseif bc_index then return bc_index(base + bc_offset, key)
      end
      error(format("'%s' has no member named '%s'", name, key))
    end,
  }
  ffi.metatype(ctype, mt)
  _metatype_registry[index] = mt
  return mt
end

-- Find a symbol index.
local function nl_symbol(name)
  local si = new("SYMBOL_INFO[1]")
  si[0].SizeOfStruct = sizeof("SYMBOL_INFO")
  si[0].MaxNameLen = 0
  print("----debug----")
  print("error code: "..tostring(NLAPI.tempGetLastError()))
  local ret = Dbghelp.SymFromName(NLAPI.nl_hProcess, name, si)
  if ret == 1 then return si[0] end
  local code = NLAPI.tempGetLastError()
  print("----debug----")
  print("error code: "..tostring(code))
  NLAPI.tempPrintLastError()
  print("----debug----")
end

local function nl_type(name)
  local si = new("SYMBOL_INFO[1]")
  si[0].SizeOfStruct = sizeof("SYMBOL_INFO")
  si[0].MaxNameLen = 0
  local ret = Dbghelp.SymGetTypeFromName(NLAPI.nl_hProcess, NLAPI.nl_BaseOfDll, name, si)
  if ret == 1 then return si[0] end
end

-- Get the value of a symbol.
local function nl_get(mask)
  local symbol_info = nl_symbol(mask)
  assert(symbol_info, "Symbol not found: " .. mask)
  local index = symbol_info.Index
  local typedef = nl_typedef(index, "")
  local addr = nl_typedword(index, Dbghelp.TI_GET_ADDRESS)
  TRACE__("nl_get :: cast(%q, %s)", typedef, addr)
  return cast(typedef, addr)
end

-- Attach a detour to a function.
local function nl_attach(name, handler)
  local symbol_info = nl_symbol(name)
  assert(symbol_info, "Symbol not found: " .. tostring(name))
  local index = symbol_info.Index
  local class, method = match(name, "([^:]+)::.*")
  local mt = nl_metatype(nl_type(class).TypeIndex, "index")
  local typedef = nl_typedef(nl_typedword(index, Dbghelp.TI_GET_TYPE), nil, class)
  local addr = nl_typedword(index, Dbghelp.TI_GET_ADDRESS)
  TRACE__("nl_attach :: NLAPI.nl_attach(cast(%q, %s), %s)", typedef, addr, tostring(handler))
  local ppPointer = new("PVOID[1]", cast("PVOID", addr))
  TRACE__("typedef : %q", typedef)
  local pDetour = cast(typedef, handler)
  NLAPI.nl_attach(ppPointer, pDetour)
  local root = cast(typedef, ppPointer[0])
  return function(this, ...) return root(this, ...) end
end

-- Advice-like hooking.
local _hook_registry = {}
local function nl_hook(mask, handler)
  if not _hook_registry[mask] then
    _hook_registry[mask] = nl_attach(mask, function(...)
      local ok, val = xpcall(_hook_registry[mask], traceback, ...)
      if ok then return val end
      io.stderr:write(val, "\n")
      os.exit(1)
    end)
  end
  local prev = _hook_registry[mask]
  _hook_registry[mask] = function(...)
    return handler(prev, ...)
  end
end

local function nl_reload(mods)
  TRACE__("Reloading %s mods ...", mods and #mods)
  if not mods then return end
  for _, init in ipairs(mods) do
    TRACE__("Reload %s", init)
    dofile(init)
  end
end

-- Exports.
TRACE__("%s.init mod API loaded.", DLLNAME)
return {
  enumsymbols   = nl_enumsymbols,
  enumtypes     = nl_enumtypes,
  typename      = nl_typename,
  typedword     = nl_typedword,
  typechildren  = nl_typechildren,
  typedef       = nl_typedef,
  ctype         = nl_ctype,
  metatype      = nl_metatype,
  type          = nl_type,
  symbol        = nl_symbol,
  attach        = nl_attach,
  hook          = nl_hook,
  get           = nl_get,
  reload        = nl_reload,
}
