# coding=utf-8
from ctypes import *
import os
import sys
import struct
from MachODefines import *

"""
有一些是工具类，只是为了import头文件，可以加入白名单
有一些SDK的文件只有测试层会用，加入白名单
有一些只有类虽然没用但是仍需要保留，加入白名单
"""
whiteListPath = ""

class MachOConstants():
    classlist = "__objc_classlist"
    classref = "__objc_classrefs"
    nlclasslist = "__objc_nlclslist"
    linkedit = "__LINKEDIT"
    textsegment = "__TEXT"
    pagezero = "__PAGEZERO"


class OBJCClass():
    def __init__(self, address, clz, ro, name=None):
        self.baseinfo = clz
        self.ro = ro
        self.name = name
        self.address = address

    def setName(self, name):
        self.name = name

    def isSuperClassOf(self, cls):
        if cls.baseinfo.superclass == self.address:
            return True
        return False

    def isEqual(self, cls):
        return self.name == cls.name

    def copy(self):
        newClz = OBJCClass(self.address, self.baseinfo, self.ro, self.name)
        return newClz


class Pointer(StructBase):
    _fields_ = [
        ('raw', c_uint64),
    ]


class OBJCClz64_t(StructBase):
    _fields_ = [
        ('isa', c_uint64),
        ('superclass', c_uint64),
        ('cache', c_uint64),
        ('vtable', c_uint64),
        ('data', c_uint64),
    ]


class OBJCClsRO64_t(StructBase):
    _fields_ = [
        ('flags', c_uint32),
        ('instanceStart', c_uint32),
        ('instanceSize', c_uint32),
        ('reserved', c_uint32),
        ('ivarLayout', c_uint64),
        ('name', c_uint64),
        ('baseMethods', c_uint64),
        ('baseProtocols', c_uint64),
        ('ivars', c_uint64),
        ('weakIvarLayout', c_uint64),
        ('baseProperties', c_uint64),
	]


class MachO():
    def __init__(self, filePath):
        self.filePath = filePath
        # 保存所有section
        self.sections = []
        self.linkBase = 0

    def fastLoad(self):
        if not os.path.exists(self.filePath):
            print("❌❌ file is not exist")
            exit(0)
        with open(self.filePath, 'rb') as f:
            offset = 0
            offset += self.__parseHeader(f, offset)
            offset += self.__parseLoadCommands(f, offset)
            if not self.dysym or not self.sym or len(self.sections) <= 0:
                print("❌❌ data Invalid")

    def __parseHeader(self, f, offset):
        f.seek(offset)
        header = mach_header_64()
        data = f.read(sizeof(header))
        header.decode(data)
        print(header.magic, header.cputype, header.filetype, header.ncmds)
        self.header = header
        return sizeof(mach_header_64)

    def __parseLoadCommands(self, f, offset):
        for _ in range(0, self.header.ncmds):
            if self.__safeSeek(f, offset) is False:
                    continue
            lc = load_command()
            data = f.read(sizeof(load_command))
            lc.decode(data)
            # 这里还得重置回去
            if self.__safeSeek(f, offset) is False:
                continue
            # print(lc.cmd, lc.cmdsize)
            # 如果是seg
            if lc.cmd == LC_SEGMENT_64:
                seg = segment_command_64()
                data = f.read(sizeof(segment_command_64))
                seg.decode(data)
                print(seg.cmd, seg.cmdsize, seg.filesize, seg.segname, seg.nsects)
                # 找到__LinkEdit
                if str(seg.segname, encoding='utf-8') == MachOConstants.pagezero:
                    self.linkBase = seg.vmsize
                    pass
                offset += sizeof(segment_command_64)
                for i in range(0, seg.nsects):
                    sect = section_64()
                    if self.__safeSeek(f, offset) is False:
                        continue
                    data = f.read(sizeof(section_64))
                    sect.decode(data)
                    # 找到classlist
                    print("segname: %s, sect name: %s" % (sect.segname, sect.sectname))
                    self.sections.append(sect)
                    offset += sizeof(section_64)
            # symtabl
            elif lc.cmd == LC_SYMTAB:
                sym = symtab_command()
                sym.decode(data)
                offset += lc.cmdsize
                self.sym = sym
            # dystmtab
            elif lc.cmd == LC_DYSYMTAB:
                dysym = dysymtab_command()
                dysym.decode(data)
                offset += lc.cmdsize
                self.dysym = dysym
            else:
                offset += lc.cmdsize
        return offset

    def __findSectionByName(self, name):
        for sect in self.sections:
            # print(str(sect.sectname, encoding='utf-8'), name)
            if str(sect.sectname, encoding='utf-8') == name:
                return sect

    # 这个方法专门解析指针指向的符号
    def __parsePointer(self, address, count):
        ptrs = []
        address -= self.linkBase
        with open(self.filePath, 'rb') as f:
            for i in range(0, count):
                if self.__safeSeek(f, address + i * 8) is False:
                    continue
                data = f.read(8)
                ptr = Pointer()
                ptr.decode(data)
                ptrs.append(ptr.raw)
        return ptrs

    def __parseClassForPointer(self, addresses):
        """
        指针指向的__objc_data段，这里存放类的基本信息,是一个OBJCClz64_t结构体
        data段指向ro。这一段数据防止__objc_const，存放着类的具体信息
        ro中的name指向的是classname段。 这一段也是属于程序段的，大概因为需要通过类名进行方法解析
        classname是与methname连接的字符串数据段，以\0分割每个字符串
        """

        clzs = list()
        with open(self.filePath, 'rb') as f:
            for address in addresses:
                address -= self.linkBase
                if self.__safeSeek(f, address) is False:
                    continue
                data = f.read(sizeof(OBJCClz64_t))
                clz = OBJCClz64_t()
                clz.decode(data)
                # 找到ro
                ro_address = clz.data - self.linkBase
                if self.__safeSeek(f, ro_address) is False:
                    continue
                data = f.read(sizeof(OBJCClsRO64_t))
                ro = OBJCClsRO64_t()
                ro.decode(data)
                oneCls = OBJCClass(address+self.linkBase, clz, clz, ro)
                clzs.append(oneCls)
                # 这里是一个联系的字符串
                if self.__safeSeek(f, ro.name - self.linkBase) is False:
                    continue
                data = f.read(50)
                # ptyhon怎么到空字符自动结束？ 貌似会自己续上
                logs = data.split(b'\x00')
                if len(logs) > 0:
                    name = str(logs[0], 'utf-8')
                    oneCls.setName(name)
        return clzs

    def __safeSeek(self, f, address):
        if address > sys.maxsize - 1 or address <= 0:
            # print("❌ invalid address: " + str(address))
            return False
        f.seek(address)
        return True

    def findUnusedClass(self):
        classrefSection = self.__findSectionByName(MachOConstants.classref)
        classlistSection = self.__findSectionByName(MachOConstants.classlist)
        if not classlistSection:
            print("❌❌ can not find classlist or classref")
            exit(0)
        # 注意这里为了节省内存，采用的位移
        align = 1 << classlistSection.align
        classlistPtrs = self.__parsePointer(classlistSection.addr, int(classlistSection.size / align))
        classrefPtrs = self.__parsePointer(classrefSection.addr, int(classrefSection.size / align))
        # print("classlist: ")
        # for ptr in classlistPtrs:
        #     print(hex(ptr))
        # print("classref: ")
        # print(classrefPtrs)
        """
        原则上在classlist 和nlclasslist 但是不在classref的认为未使用
        不过只是命名上没有被另一个引用而已，如果是父类或者仅仅是xib使用的也会被认为是未使用的
        为了提高准确率，过滤掉作为父类存在的。
        """
        class_unsed = set()
        for ptr in classlistPtrs:
            if ptr not in class_unsed:
                class_unsed.add(ptr)
        for ptr in classrefPtrs:
            if ptr in class_unsed:
                class_unsed.remove(ptr)

        # 过滤掉是父类
        unused_clzs = self.__parseClassForPointer(class_unsed)
        all_clzs = self.__parseClassForPointer(classlistPtrs)
        copylist = unused_clzs[:]
        for clz in copylist:
            for used_clz in all_clzs:
                if clz.isSuperClassOf(used_clz):
                    unused_clzs.remove(clz)
                    break

        names = []
        for clz in unused_clzs:
            names.append(clz.name)
        return names


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("请输入源mach-o文件路径, 如果需要导出结果，请同时输入输出文件路径")
    path = sys.argv[1]
    macho = MachO(path)
    macho.fastLoad()
    unused_class_names = macho.findUnusedClass()
    print("🔥🔥 count: " + str(len(unused_class_names)))
    if len(sys.argv) > 2:
        path = sys.argv[2]
        log = "\n".join(unused_class_names)
        with open(path, 'w') as f:
            f.write(log)
