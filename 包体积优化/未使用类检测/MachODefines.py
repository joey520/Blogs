
# coding=utf-8
from ctypes import *


MH_MAGIC = 0xfeedface
MH_CIGAM = 0xcefaedfe
MH_MAGIC_64 = 0xfeedfacf
MH_CIGAM_64 = 0xcffaedfe
MH_OBJECT = 0x1
MH_EXECUTE = 0x2
MH_FVMLIB = 0x3
MH_CORE = 0x4
MH_PRELOAD = 0x5
MH_DYLIB = 0x6
MH_DYLINKER = 0x7
MH_BUNDLE = 0x8
MH_DYLIB_STUB = 0x9
MH_DSYM = 0xa
MH_KEXT_BUNDLE = 0xb
MH_NOUNDEFS = 0x1
MH_INCRLINK = 0x2
MH_DYLDLINK = 0x4
MH_BINDATLOAD = 0x8
MH_PREBOUND = 0x10
MH_SPLIT_SEGS = 0x20
MH_LAZY_INIT = 0x40
MH_TWOLEVEL = 0x80
MH_FORCE_FLAT = 0x100
MH_NOMULTIDEFS = 0x200
MH_NOFIXPREBINDING = 0x400
MH_PREBINDABLE = 0x800
MH_ALLMODSBOUND = 0x1000
MH_SUBSECTIONS_VIA_SYMBOLS = 0x2000
MH_CANONICAL = 0x4000
MH_WEAK_DEFINES = 0x8000
MH_BINDS_TO_WEAK = 0x10000
MH_ALLOW_STACK_EXECUTION = 0x20000
MH_ROOT_SAFE = 0x40000
MH_SETUID_SAFE = 0x80000
MH_NO_REEXPORTED_DYLIBS = 0x100000
MH_PIE = 0x200000
MH_DEAD_STRIPPABLE_DYLIB = 0x400000
MH_HAS_TLV_DESCRIPTORS = 0x800000
MH_NO_HEAP_EXECUTION = 0x1000000
MH_APP_EXTENSION_SAFE = 0x02000000
MH_NLIST_OUTOFSYNC_WITH_DYLDINFO = 0x04000000
MH_SIM_SUPPORT = 0x08000000
MH_DYLIB_IN_CACHE = 0x80000000
LC_REQ_DYLD = 0x80000000
LC_SEGMENT = 0x1
LC_SYMTAB = 0x2
LC_SYMSEG = 0x3
LC_THREAD = 0x4
LC_UNIXTHREAD = 0x5
LC_LOADFVMLIB = 0x6
LC_IDFVMLIB = 0x7
LC_IDENT = 0x8
LC_FVMFILE = 0x9
LC_PREPAGE = 0xa
LC_DYSYMTAB = 0xb
LC_LOAD_DYLIB = 0xc
LC_ID_DYLIB = 0xd
LC_LOAD_DYLINKER = 0xe
LC_ID_DYLINKER = 0xf
LC_PREBOUND_DYLIB = 0x10
LC_ROUTINES = 0x11
LC_SUB_FRAMEWORK = 0x12
LC_SUB_UMBRELLA = 0x13
LC_SUB_CLIENT = 0x14
LC_SUB_LIBRARY = 0x15
LC_TWOLEVEL_HINTS = 0x16
LC_PREBIND_CKSUM = 0x17
LC_LOAD_WEAK_DYLIB = (0x18 | LC_REQ_DYLD) 
LC_SEGMENT_64 = 0x19
LC_ROUTINES_64 = 0x1a
LC_UUID = 0x1b
LC_RPATH = (0x1c | LC_REQ_DYLD) 
LC_CODE_SIGNATURE = 0x1d
LC_SEGMENT_SPLIT_INFO = 0x1e
LC_REEXPORT_DYLIB = (0x1f | LC_REQ_DYLD) 
LC_LAZY_LOAD_DYLIB = 0x20
LC_ENCRYPTION_INFO = 0x21
LC_DYLD_INFO = 0x22
LC_DYLD_INFO_ONLY = (0x22|LC_REQ_DYLD)
LC_LOAD_UPWARD_DYLIB = (0x23 | LC_REQ_DYLD) 
LC_VERSION_MIN_MACOSX = 0x24
LC_VERSION_MIN_IPHONEOS = 0x25
LC_FUNCTION_STARTS = 0x26
LC_DYLD_ENVIRONMENT = 0x27
LC_MAIN = (0x28|LC_REQ_DYLD)
LC_DATA_IN_CODE = 0x29
LC_SOURCE_VERSION = 0x2A
LC_DYLIB_CODE_SIGN_DRS = 0x2B
LC_ENCRYPTION_INFO_64 = 0x2C
LC_LINKER_OPTION = 0x2D
LC_LINKER_OPTIMIZATION_HINT = 0x2E
LC_VERSION_MIN_TVOS = 0x2F
LC_VERSION_MIN_WATCHOS = 0x30
LC_NOTE = 0x31
LC_BUILD_VERSION = 0x32
LC_DYLD_EXPORTS_TRIE = (0x33 | LC_REQ_DYLD) 
LC_DYLD_CHAINED_FIXUPS = (0x34 | LC_REQ_DYLD) 
SG_HIGHVM = 0x1
SG_FVMLIB = 0x2
SG_NORELOC = 0x4
SG_PROTECTED_VERSION_1 = 0x8
SG_READ_ONLY = 0x10
SECTION_TYPE = 0x000000ff
SECTION_ATTRIBUTES = 0xffffff00
S_REGULAR = 0x0
S_ZEROFILL = 0x1
S_CSTRING_LITERALS = 0x2
S_4BYTE_LITERALS = 0x3
S_8BYTE_LITERALS = 0x4
S_LITERAL_POINTERS = 0x5
S_NON_LAZY_SYMBOL_POINTERS = 0x6
S_LAZY_SYMBOL_POINTERS = 0x7
S_SYMBOL_STUBS = 0x8
S_MOD_INIT_FUNC_POINTERS = 0x9
S_MOD_TERM_FUNC_POINTERS = 0xa
S_COALESCED = 0xb
S_GB_ZEROFILL = 0xc
S_INTERPOSING = 0xd
S_16BYTE_LITERALS = 0xe
S_DTRACE_DOF = 0xf
S_LAZY_DYLIB_SYMBOL_POINTERS = 0x10
S_THREAD_LOCAL_REGULAR = 0x11
S_THREAD_LOCAL_ZEROFILL = 0x12
S_THREAD_LOCAL_VARIABLES = 0x13
S_THREAD_LOCAL_VARIABLE_POINTERS = 0x14
S_THREAD_LOCAL_INIT_FUNCTION_POINTERS = 0x15
S_INIT_FUNC_OFFSETS = 0x16
SECTION_ATTRIBUTES_USR = 0xff000000
S_ATTR_PURE_INSTRUCTIONS = 0x80000000
S_ATTR_NO_TOC = 0x40000000
S_ATTR_STRIP_STATIC_SYMS = 0x20000000
S_ATTR_NO_DEAD_STRIP = 0x10000000
S_ATTR_LIVE_SUPPORT = 0x08000000
S_ATTR_SELF_MODIFYING_CODE = 0x04000000
S_ATTR_DEBUG = 0x02000000
SECTION_ATTRIBUTES_SYS = 0x00ffff00
S_ATTR_SOME_INSTRUCTIONS = 0x00000400
S_ATTR_EXT_RELOC = 0x00000200
S_ATTR_LOC_RELOC = 0x00000100
SEG_PAGEZERO = "__PAGEZERO"
SEG_TEXT = "__TEXT"
SECT_TEXT = "__text"
SECT_FVMLIB_INIT0 = "__fvmlib_init0"
SECT_FVMLIB_INIT1 = "__fvmlib_init1"
SEG_DATA = "__DATA"
SECT_DATA = "__data"
SECT_BSS = "__bss"
SECT_COMMON = "__common"
SEG_OBJC = "__OBJC"
SECT_OBJC_SYMBOLS = "__symbol_table"
SECT_OBJC_MODULES = "__module_info"
SECT_OBJC_STRINGS = "__selector_strs"
SECT_OBJC_REFS = "__selector_refs"
SEG_ICON = "__ICON"
SECT_ICON_HEADER = "__header"
SECT_ICON_TIFF = "__tiff"
SEG_LINKEDIT = "__LINKEDIT"
SEG_UNIXSTACK = "__UNIXSTACK"
SEG_IMPORT = "__IMPORT"
INDIRECT_SYMBOL_LOCAL = 0x80000000
INDIRECT_SYMBOL_ABS = 0x40000000
PLATFORM_MACOS = 1
PLATFORM_IOS = 2
PLATFORM_TVOS = 3
PLATFORM_WATCHOS = 4
PLATFORM_BRIDGEOS = 5
PLATFORM_MACCATALYST = 6
PLATFORM_MACCATALYST = 6
PLATFORM_IOSSIMULATOR = 7
PLATFORM_TVOSSIMULATOR = 8
PLATFORM_WATCHOSSIMULATOR = 9
PLATFORM_DRIVERKIT = 10
TOOL_CLANG = 1
TOOL_SWIFT = 2
TOOL_LD = 3
REBASE_TYPE_POINTER = 1
REBASE_TYPE_TEXT_ABSOLUTE32 = 2
REBASE_TYPE_TEXT_PCREL32 = 3
REBASE_OPCODE_MASK = 0xF0
REBASE_IMMEDIATE_MASK = 0x0F
REBASE_OPCODE_DONE = 0x00
REBASE_OPCODE_SET_TYPE_IMM = 0x10
REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB = 0x20
REBASE_OPCODE_ADD_ADDR_ULEB = 0x30
REBASE_OPCODE_ADD_ADDR_IMM_SCALED = 0x40
REBASE_OPCODE_DO_REBASE_IMM_TIMES = 0x50
REBASE_OPCODE_DO_REBASE_ULEB_TIMES = 0x60
REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB = 0x70
REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB = 0x80
BIND_TYPE_POINTER = 1
BIND_TYPE_TEXT_ABSOLUTE32 = 2
BIND_TYPE_TEXT_PCREL32 = 3
BIND_SPECIAL_DYLIB_SELF = 0
BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE = -1
BIND_SPECIAL_DYLIB_FLAT_LOOKUP = -2
BIND_SPECIAL_DYLIB_WEAK_LOOKUP = -3
BIND_SYMBOL_FLAGS_WEAK_IMPORT = 0x1
BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION = 0x8
BIND_OPCODE_MASK = 0xF0
BIND_IMMEDIATE_MASK = 0x0F
BIND_OPCODE_DONE = 0x00
BIND_OPCODE_SET_DYLIB_ORDINAL_IMM = 0x10
BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB = 0x20
BIND_OPCODE_SET_DYLIB_SPECIAL_IMM = 0x30
BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM = 0x40
BIND_OPCODE_SET_TYPE_IMM = 0x50
BIND_OPCODE_SET_ADDEND_SLEB = 0x60
BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB = 0x70
BIND_OPCODE_ADD_ADDR_ULEB = 0x80
BIND_OPCODE_DO_BIND = 0x90
BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB = 0xA0
BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED = 0xB0
BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB = 0xC0
BIND_OPCODE_THREADED = 0xD0
BIND_SUBOPCODE_THREADED_SET_BIND_ORDINAL_TABLE_SIZE_ULEB = 0x00
BIND_SUBOPCODE_THREADED_APPLY = 0x01
EXPORT_SYMBOL_FLAGS_KIND_MASK = 0x03
EXPORT_SYMBOL_FLAGS_KIND_REGULAR = 0x00
EXPORT_SYMBOL_FLAGS_KIND_THREAD_LOCAL = 0x01
EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE = 0x02
EXPORT_SYMBOL_FLAGS_WEAK_DEFINITION = 0x04
EXPORT_SYMBOL_FLAGS_REEXPORT = 0x08
EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER = 0x10
DICE_KIND_DATA = 0x0001
DICE_KIND_JUMP_TABLE8 = 0x0002
DICE_KIND_JUMP_TABLE16 = 0x0003
DICE_KIND_JUMP_TABLE32 = 0x0004
DICE_KIND_ABS_JUMP_TABLE32 = 0x0005

class lc_str(Union):
	_fields_ = [
		('offset', c_uint32),
		('ptr', c_char),
	]


class StructBase(Structure):
    def encode(self):
        return string_at(addressof(self), sizeof(self))

    def decode(self, data):
        memmove(addressof(self), data, sizeof(self))
        return len(data)


class mach_header(StructBase):
	_fields_ = [
		('magic', c_uint32),
		('cputype', c_int32),
		('cpusubtype', c_int32),
		('filetype', c_uint32),
		('ncmds', c_uint32),
		('sizeofcmds', c_uint32),
		('flags', c_uint32),
	]


class mach_header_64(StructBase):
	_fields_ = [
		('magic', c_uint32),
		('cputype', c_int32),
		('cpusubtype', c_int32),
		('filetype', c_uint32),
		('ncmds', c_uint32),
		('sizeofcmds', c_uint32),
		('flags', c_uint32),
		('reserved', c_uint32),
	]


class load_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
	]


class segment_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('segname', c_char*16),
		('vmaddr', c_uint32),
		('vmsize', c_uint32),
		('fileoff', c_uint32),
		('filesize', c_uint32),
		('maxprot', c_int32),
		('initprot', c_int32),
		('nsects', c_uint32),
		('flags', c_uint32),
	]


class segment_command_64(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('segname', c_char*16),
		('vmaddr', c_uint64),
		('vmsize', c_uint64),
		('fileoff', c_uint64),
		('filesize', c_uint64),
		('maxprot', c_int32),
		('initprot', c_int32),
		('nsects', c_uint32),
		('flags', c_uint32),
	]


class section(StructBase):
	_fields_ = [
		('sectname', c_char*16),
		('segname', c_char*16),
		('addr', c_uint32),
		('size', c_uint32),
		('offset', c_uint32),
		('align', c_uint32),
		('reloff', c_uint32),
		('nreloc', c_uint32),
		('flags', c_uint32),
		('reserved1', c_uint32),
		('reserved2', c_uint32),
	]


class section_64(StructBase):
	_fields_ = [
		('sectname', c_char*16),
		('segname', c_char*16),
		('addr', c_uint64),
		('size', c_uint64),
		('offset', c_uint32),
		('align', c_uint32),
		('reloff', c_uint32),
		('nreloc', c_uint32),
		('flags', c_uint32),
		('reserved1', c_uint32),
		('reserved2', c_uint32),
		('reserved3', c_uint32),
	]


class fvmlib(StructBase):
	_fields_ = [
		('name', lc_str),
		('minor_version', c_uint32),
		('header_addr', c_uint32),
	]


class fvmlib(StructBase):
	_fields_ = [
	]


class dylib(StructBase):
	_fields_ = [
		('name', lc_str),
		('timestamp', c_uint32),
		('current_version', c_uint32),
		('compatibility_version', c_uint32),
	]


class dylib(StructBase):
	_fields_ = [
	]


class sub_framework_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('umbrella', lc_str),
	]


class sub_client_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('client', lc_str),
	]


class sub_umbrella_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('sub_umbrella', lc_str),
	]


class sub_library_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('sub_library', lc_str),
	]


class prebound_dylib_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('name', lc_str),
		('nmodules', c_uint32),
		('linked_modules', lc_str),
	]


class dylinker_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('name', lc_str),
	]


class thread_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
	]


class routines_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('init_address', c_uint32),
		('init_module', c_uint32),
		('reserved1', c_uint32),
		('reserved2', c_uint32),
		('reserved3', c_uint32),
		('reserved4', c_uint32),
		('reserved5', c_uint32),
		('reserved6', c_uint32),
	]


class routines_command_64(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('init_address', c_uint64),
		('init_module', c_uint64),
		('reserved1', c_uint64),
		('reserved2', c_uint64),
		('reserved3', c_uint64),
		('reserved4', c_uint64),
		('reserved5', c_uint64),
		('reserved6', c_uint64),
	]


class symtab_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('symoff', c_uint32),
		('nsyms', c_uint32),
		('stroff', c_uint32),
		('strsize', c_uint32),
	]


class dysymtab_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('ilocalsym', c_uint32),
		('nlocalsym', c_uint32),
		('iextdefsym', c_uint32),
		('nextdefsym', c_uint32),
		('iundefsym', c_uint32),
		('nundefsym', c_uint32),
		('tocoff', c_uint32),
		('ntoc', c_uint32),
		('modtaboff', c_uint32),
		('nmodtab', c_uint32),
		('extrefsymoff', c_uint32),
		('nextrefsyms', c_uint32),
		('indirectsymoff', c_uint32),
		('nindirectsyms', c_uint32),
		('extreloff', c_uint32),
		('nextrel', c_uint32),
		('locreloff', c_uint32),
		('nlocrel', c_uint32),
	]


class dylib_table_of_contents(StructBase):
	_fields_ = [
		('symbol_index', c_uint32),
		('module_index', c_uint32),
	]


class dylib_module(StructBase):
	_fields_ = [
		('module_name', c_uint32),
		('iextdefsym', c_uint32),
		('nextdefsym', c_uint32),
		('irefsym', c_uint32),
		('nrefsym', c_uint32),
		('ilocalsym', c_uint32),
		('nlocalsym', c_uint32),
		('iextrel', c_uint32),
		('nextrel', c_uint32),
		('iinit_iterm', c_uint32),
		('ninit_nterm', c_uint32),
	]


class dylib_module_64(StructBase):
	_fields_ = [
		('module_name', c_uint32),
		('iextdefsym', c_uint32),
		('nextdefsym', c_uint32),
		('irefsym', c_uint32),
		('nrefsym', c_uint32),
		('ilocalsym', c_uint32),
		('nlocalsym', c_uint32),
		('iextrel', c_uint32),
		('nextrel', c_uint32),
		('iinit_iterm', c_uint32),
		('ninit_nterm', c_uint32),
	]


class dylib_reference(StructBase):
	_fields_ = [
		('isym:24,', c_uint32),
	]


class twolevel_hints_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('offset', c_uint32),
		('nhints', c_uint32),
	]


class twolevel_hint(StructBase):
	_fields_ = [
	]


class prebind_cksum_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('cksum', c_uint32),
	]


class uuid_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('uuid', c_uint8*16),
	]


class rpath_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('path', lc_str),
	]


class linkedit_data_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('dataoff', c_uint32),
		('datasize', c_uint32),
	]


class encryption_info_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('cryptoff', c_uint32),
		('cryptsize', c_uint32),
		('cryptid', c_uint32),
	]


class encryption_info_command_64(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('cryptoff', c_uint32),
		('cryptsize', c_uint32),
		('cryptid', c_uint32),
		('pad', c_uint32),
	]


class version_min_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('version', c_uint32),
		('sdk', c_uint32),
	]


class build_version_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('platform', c_uint32),
		('minos', c_uint32),
		('sdk', c_uint32),
		('ntools', c_uint32),
	]


class build_tool_version(StructBase):
	_fields_ = [
		('tool', c_uint32),
		('version', c_uint32),
	]


class dyld_info_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('rebase_off', c_uint32),
		('rebase_size', c_uint32),
		('bind_off', c_uint32),
		('bind_size', c_uint32),
		('weak_bind_off', c_uint32),
		('weak_bind_size', c_uint32),
		('lazy_bind_off', c_uint32),
		('lazy_bind_size', c_uint32),
		('export_off', c_uint32),
		('export_size', c_uint32),
	]


class linker_option_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('count', c_uint32),
	]


class symseg_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('offset', c_uint32),
		('size', c_uint32),
	]


class ident_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
	]


class fvmfile_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('name', lc_str),
		('header_addr', c_uint32),
	]


class entry_point_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('entryoff', c_uint64),
		('stacksize', c_uint64),
	]


class source_version_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('version', c_uint64),
	]


class data_in_code_entry(StructBase):
	_fields_ = [
		('offset', c_uint32),
		('length', c_uint16),
		('kind', c_uint16),
	]


# class tlv_descriptor(StructBase):
# 	_fields_ = [
# 		('kUnknownType', 	void*		(*thunk)(struct tlv_descriptor*);),
# 		('kUnknownType', 	unsigned long	key;),
# 		('kUnknownType', 	unsigned long	offset;),
# 	]


class note_command(StructBase):
	_fields_ = [
		('cmd', c_uint32),
		('cmdsize', c_uint32),
		('data_owner', c_char*16),
		('offset', c_uint64),
		('size', c_uint64),
	]


