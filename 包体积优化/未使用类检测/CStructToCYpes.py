# coding=utf-8
import os
import sys
import re


inputPath = ""
outputPath = ""
kUnknownType = "kUnknownType"

TypeMap = {
    "uint32_t": "c_uint32",
    "uint8_t": "c_uint8",
    "uint16_t": "c_uint16",
    "uint64_t": "c_uint64",
    "char": "c_char",
    "float": "c_float",
    "double": "c_double",
}

TypeDefinesMap = {
    "cpu_type_t": "c_int32",
    "cpu_subtype_t": "c_int32",
    "cpu_threadtype_t": "c_int32",
    "vm_prot_t": "c_int32",
}

HeaderBaseString = """
# coding=utf-8
from ctypes import *


"""

BaseStructString = """
class StructBase(Structure):
    def encode(self):
        return string_at(addressof(self), sizeof(self))

    def decode(self, data):
        memmove(addressof(self), data, sizeof(self))
        return len(data)
"""

class StructureType():
    unkonwn = 0
    struct = 1
    union = 2


class TokenIdentifiers():
    define = "#define"
    struct = "struct"
    union = "union"
    typedef = "typedef"
    equal = "="
    blank = " "
    lineFeed = "\n"
    add = "+"
    minus = "-"
    rBktL = "("
    rBktR = ")"
    asterisk = "*"
    colon = ":"
    comma = ","
    semicolon = ";"
    divide = "/"
    agBktL = "<"
    agBktR = ">"
    quotM = "\""
    pSign = "#"
    braceL = "{"
    braceR = "}"
    bktL = "["
    bktR = "]"
    qM = "?"
    upArrow = "^"


def lineWithLevel(line, level):
        string = ""
        for _ in range(level):
            string += "\t"
        string += line
        return string

def covert2Ctype(name, originalType):
    if originalType in TypeMap:
        return TypeMap[originalType]
    if originalType in TypeDefinesMap:
        return TypeDefinesMap[originalType]
    print("❌❌find Unknow type at struct: %s, type: %s" % (name, originalType))
    return originalType

class DefinePair():
    name = ""
    value = ""

    def __init__(self, name=None, value=None):
        self.name = name
        self.value = value
        pass


class VarPair():

    def __init__(self, name, valueType):
        self.name = name
        self.valueType = valueType

class Union():
    def __init__(self, name=None):
        self.name = name
        self.__fields = []

    def addVarPair(self, pair):
        self.__fields.append(pair)
        pass

    def toString(self):
        currentLevel = 0
        toStr = ""
        line = ("class " + self.name + "(Union):\n")
        toStr += lineWithLevel(line, currentLevel)
        currentLevel += 1
        line = "_fields_ = [\n"
        toStr += lineWithLevel(line, currentLevel)
        currentLevel += 1
        for pair in self.__fields:
            if isinstance(pair, VarPair):
                varName = pair.name
                varType = covert2Ctype(self.name, pair.valueType)
                # 数组
                if "[" in varName:
                    vars = varName.split("[")
                    varName = vars[0]
                    for i in range(1, len(vars)):
                        count = vars[i][0: len(vars[i]) - 1]
                        varType += ("*" + count)
                line = "('%s', %s),\n" % (varName, varType)
                toStr += lineWithLevel(line, currentLevel)
            else:
                print("❌❌ Union: %s unknow pair", self.name)
                print(pair)
                print("\n")

        currentLevel -= 1
        toStr += lineWithLevel("]\n", currentLevel)
        toStr += "\n"
        return toStr


class Struct():

    def __init__(self, name=None):
        self.name = name
        self.__fields = []

    def setName(self, name):
        self.name = name

    def addVarPair(self, pair):
        self.__fields.append(pair)
        pass

    def toString(self):
        currentLevel = 0
        toStr = ""
        line = ("class " + self.name + "(StructBase):\n")
        toStr += lineWithLevel(line, currentLevel)
        currentLevel += 1
        line = "_fields_ = [\n"
        toStr += lineWithLevel(line, currentLevel)
        currentLevel += 1
        for pair in self.__fields:
            if isinstance(pair, VarPair):
                varName = pair.name
                varType = covert2Ctype(self.name, pair.valueType)
                # 数组
                if "[" in varName:
                    vars = varName.split("[")
                    varName = vars[0]
                    for i in range(1, len(vars)):
                        count = vars[i][0: len(vars[i]) - 1]
                        varType += ("*" + count)
                line = "('%s', %s),\n" % (varName, varType)
                toStr += lineWithLevel(line, currentLevel)
            else:
                print("❌❌ struct: %s unknow pair", self.name)
                print(pair)
                print("\n")

        currentLevel -= 1
        toStr += lineWithLevel("]\n", currentLevel)
        toStr += "\n\n"
        return toStr


class Parser(object):
    __defines = []
    __structs = []
    __unions = []

    def __init__(self):
        pass

    def parse(self):
        with open(inputPath, 'r') as f:
            content = f.read()
            # 去掉注释
            content = self.__removeAnnotation(content)
            self.__parseData(content)

    def __parseDefines(self, content):
        tokens = self.__tokens(content)
        if len(tokens) < 3:
            print("❌❌ no used define: " + content)
            return
        if len(tokens[1]) > 0 and len(tokens[2]) > 0:
            name = tokens[1]
            value = ""
            if len(tokens) == 3:
                value = tokens[2]
            else:
                for i in range(2, len(tokens)):
                    value += (str(tokens[i]).replace("@", "") + " ")
            oneDefine = DefinePair(name, value)
            self.__defines.append(oneDefine)

    def _parseUnions(self, content):
        unionName = ""
        oneUnion = Union()
        lines = content.split(TokenIdentifiers.lineFeed)
        lastToken = ""
        for line in lines:
            tokens = self.__tokens(line)
            # 如果union内部嵌套别的东东，先不管，手动修改
            if len(unionName) > 0 and len(tokens) > 2:
                print("❌❌ Union: %s find union: %s， 请手动确认union格式" % (unionName, tokens[1]))
            elif len(unionName) > 0 and len(tokens) == 2:
                pair = VarPair(tokens[1], tokens[0])
                oneUnion.addVarPair(pair)
            for token in tokens:
                # 借到一个struct
                if lastToken == TokenIdentifiers.union:
                    unionName = token
                    oneUnion = Union(unionName)
                lastToken = token
        self.__unions.append(oneUnion)


    def __parseStruct(self, content):
        structName = ""
        oneStruct = Struct()
        lines = content.split(TokenIdentifiers.lineFeed)
        lastToken = ""
        for line in lines:
            tokens = self.__tokens(line)
            # 找到一个strcut，但是内部有uoin或者其它类型，先标记出来,手动确认比较安全
            if len(structName) > 0 and len(tokens) > 2:
                # 如果是嵌套结构体
                if TokenIdentifiers.struct in tokens and len(tokens) == 3:
                    oneStruct.addVarPair(VarPair(tokens[2], tokens[1]))
                elif TokenIdentifiers.union in tokens and len(tokens) == 3:
                    # 如果是union，先保存下来，手动添加union
                    oneStruct.addVarPair(VarPair(tokens[2], tokens[1]))
                    print("❌❌ struct: %s find union: %s" % (structName, tokens[1]))
                else:
                    oneStruct.addVarPair(VarPair(kUnknownType, line))
            elif len(structName) > 0 and len(tokens) == 2:
                pair = VarPair(tokens[1], tokens[0])
                oneStruct.addVarPair(pair)
                # print(oneStruct.toString())
            for token in tokens:
                # 借到一个struct
                if lastToken == TokenIdentifiers.struct:
                    structName = token
                    oneStruct = Struct(structName)
                lastToken = token
        self.__structs.append(oneStruct)


    def __parseData(self, content):
        lines = content.split(TokenIdentifiers.lineFeed)
        # 匹配花括号
        leftbraceLCount = 0
        structContent = ""
        begin = 0
        contentType = StructureType.unkonwn

        for line in lines:
            # 开始解析。空行直接略过
            if len(line) <= 0 or line == TokenIdentifiers.lineFeed:
                continue
            tokens = self.__tokens(line)
            # 如果是宏命令
            if TokenIdentifiers.define in tokens:
                self.__parseDefines(line)
                continue

            # 找到struct
            if TokenIdentifiers.struct in tokens and contentType == StructureType.unkonwn:
                # 忽略typedef
                if not TokenIdentifiers.typedef in tokens:
                    contentType = StructureType.struct
                    begin = 1
                

            if TokenIdentifiers.union in tokens and contentType == StructureType.unkonwn:
                contentType = StructureType.union
                begin = 1

            for token in tokens:
                if token == TokenIdentifiers.braceL:
                    leftbraceLCount += 1
                    # print("leftbraceLCount+1 : " + str(leftbraceLCount))
                # 匹配到一个右花括号
                elif token == TokenIdentifiers.braceR:
                    leftbraceLCount -= 1
                    # print("leftbraceLCount-1 : " + str(leftbraceLCount))
                    if leftbraceLCount == 0:
                        begin = 0
                        # print("begin 清零")

            if begin == 1:
                structContent += (line + "\n")
            else:
                structContent += (line + "\n")
                if contentType == StructureType.struct:
                    # print("解析struct: " + structContent)
                    self.__parseStruct(structContent)
                elif contentType == StructureType.union:
                    # print("解析union: " + structContent)
                    self._parseUnions(structContent)
                # 重置数据
                contentType = StructureType.unkonwn
                structContent = ""

        # 解析完毕写文件
        self.__witreFile()

    def __witreFile(self):
        # 写文件
        fileContent = HeaderBaseString
        for define in self.__defines:
            line = "%s = %s\n" % (define.name, define.value)
            fileContent += line
        # 空两行
        fileContent += "\n"
        # 添加union
        for union in self.__unions:
            fileContent += union.toString()

        # 添加base struct
        fileContent += BaseStructString
        # 空两行
        fileContent += "\n\n"
        # 添加struct
        for stu in self.__structs:
            # print("写一个struct: " + stu.toString())
            fileContent += stu.toString()
        with open(outputPath, 'w') as f:
            f.write(fileContent)

    def __tokens(self, line):
        # 连续空格只保留一盒
        line = re.sub(re.compile("\s+", re.S), " ", line)
        # 去掉;
        line = line.replace(TokenIdentifiers.semicolon, "")
        tokens = line.strip().split(TokenIdentifiers.blank)
        tokens = [token for token in tokens if token != " "]
        return tokens

    def __removeAnnotation(self, content):
        blockPattern = "/\\*[\\s\\S]*?\\*/"
        linePatter = "//.*?\\n"
        ret = re.sub(re.compile(blockPattern, re.S), "", content)
        ret = re.sub(re.compile(linePatter, re.S), "", ret)
        return ret


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("请输入源路径和输出路径")
        exit(0)
    inputPath = sys.argv[1]
    outputPath = sys.argv[2]
    parser = Parser()
    parser.parse()
