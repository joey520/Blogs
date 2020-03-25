#include <iostream>
#include "clang/AST/AST.h"
#include "clang/AST/ASTConsumer.h"
#include "clang/AST/RecursiveASTVisitor.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Frontend/FrontendPluginRegistry.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"
#include <vector>
#include <map>
#include <string>

using namespace clang;
using namespace std;
using namespace llvm;
using namespace ast_matchers;

namespace UnusedCodePlugin
    {
    
    class JMethod
    {
    public:
        JMethod(string id, string sel, string cls, string filePath)
        : methodID(id), selName(sel), className(cls), filePath(filePath) {
        }
        ~JMethod() {
        }
        
        JMethod(bool isInstanceMethod, string sel, string cls, string filePath)
        : JMethod(string(), sel, cls, filePath) {
            string methodID = isInstanceMethod ? "-" : "+";
            methodID += ("[" + cls + " ");
            methodID += (sel + "]");
            this->methodID = methodID;
        }
        size_t hashCode() {
            return hash<string>()(methodID);
        }
        
        string methodID;//唯一标志符
        string selName;
        
        string className;
        string filePath;//所在文件路径
        int lineStart;//所在行
        int lineEnd;
    };
    
    class JProtocol
    {
    public:
        JProtocol() {
        }
        JProtocol(string name, string path)
        : name_(name), filePath(path) {
        }
        ~JProtocol() {
        }
        string name_;
        string filePath;
        vector<JMethod> methods;
        
        void appendProtocols(vector<string> protocols) {
            this->inheritProtcocolNames.insert(this->inheritProtcocolNames.end(), protocols.begin(), protocols.end());
        }
        vector<string> inheritProtcocolNames;
        
        //    vector<JProtocol> inheritProtcocols;
        //    void appendProtocols(vector<JProtocol> protocols) {
        //        this->inheritProtcocols.insert(this->inheritProtcocols.end(), protocols.begin(), protocols.end());
        //    }
    private:
    };
    
    class JClass
    {
    public:
        JClass(string name, string path)
        : name_(name), filePath(path){};
        ~JClass() {
        }
        string name_;
        string filePath;
        vector<string> protcolNames;
        string superClassName;
        vector<JMethod> methods;
        
        void appenProtocols(vector<string> &protoVec) {
            this->protcolNames.insert(this->protcolNames.end(), protoVec.begin(), protoVec.end());
        }
        
        void setSuperClassName(string name) {
            this->superClassName = name;
        }
        
        //    vector<JProtocol> protcols;
        //    void appenProtocols(vector<JProtocol> &protoVec) {
        //        this->protcols.insert(this->protcols.end(), protoVec.begin(), protoVec.end());
        //    }
        
    };
    
    static map<string, JClass> classMap;
    static map<string, JProtocol> protocolMap;
    static map<string, JMethod> allMethods;
    static map<string, JMethod> usedMethods;
    
    class MyASTVisitor : public RecursiveASTVisitor<MyASTVisitor>
    {
    private:
        ASTContext *context;
        string ObjcInterfaceName;//
        string ObjcProtocolName;
        string ObjcImplementationName;
        
    public:
        bool recursiveSearchProtocolMethod(string protocolName, JMethod &method) {
            //找到头了
            if (strcmp(protocolName.c_str(), "NSObject") == 0) {
                return false;
            }
            auto it = protocolMap.find(protocolName);
            if (it == protocolMap.end()) {
                return false;
            }
            JProtocol &protocol = it->second;
            for (JMethod tmpmethod : protocol.methods) {
                //此时只对比selector
                if (tmpmethod.selName == method.selName) {
                    return true;
                }
            }
            //如果这个协议没找到。看一下有没有可能是继承链上的
            for (string protocolName : protocol.inheritProtcocolNames) {
                return recursiveSearchProtocolMethod(protocolName, method);
            }
            return false;
        }
        
        //由于在递归的过程中，
        bool
        recursiveSearchClassMethod(string className, JMethod &method) {
            //找到头了
            if (strcmp(className.c_str(), "NSObject") == 0) {
                return false;
            }
            auto it = classMap.find(className);
            if (it == classMap.end()) {
                return false;
            }
            JClass cls = it->second;
            for (string protocolName : cls.protcolNames) {
                if (recursiveSearchProtocolMethod(protocolName, method)) {
                    return true;
                }
            }
            
            //如果没找到，查找父类
            it = classMap.find(cls.superClassName);
            if (it == classMap.end()) {
                return false;
            }
            return recursiveSearchClassMethod(cls.superClassName, method);
        }
        
        void parseData() {
            cout << "开始解析数据" << endl;
            vector<JMethod> unusedMethods;
            cout << "所有方法" << endl;
            for (pair<string, JMethod> pair : allMethods) {
                cout << pair.first << endl;
            }
            
            cout << "使用的方法" << endl;
            for (pair<string, JMethod> pair : usedMethods) {
                cout << pair.first << endl;
            }
            
            for (map<string, JMethod>::const_iterator it = allMethods.begin(); it != allMethods.end(); it++) {
                string methodID = it->first;
                JMethod method = it->second;
                auto it1 = usedMethods.find(methodID);
                if (it1 == usedMethods.end()) {
                    //先判断下是不是delegate
                    //如果delegate中也找不到
                    if (recursiveSearchClassMethod(method.className, method) == false) {
                        unusedMethods.push_back(it->second);
                    }
                }
            }
            
            cout << "未使用的方法" << endl;
            for (JMethod method : unusedMethods) {
                cout << method.methodID << " 路径: " << method.filePath << endl;
            }
        }
        
        void setContext(ASTContext &context) {
            this->context = &context;
        }
        
        bool VisitDecl(Decl *decl) {
            //在解析这三种数据前先重置一下数据，避免对应到了其它类
            if (isa<ObjCInterfaceDecl>(decl) || isa<ObjCImplDecl>(decl) || isa<ObjCProtocolDecl>(decl)) {
                ObjcInterfaceName = string();
                ObjcProtocolName = string();
                ObjcImplementationName = string();
            }
            
            //解析到Interface。把protocol存下来，因为当前
            if (isa<ObjCInterfaceDecl>(decl)) {
                ObjCInterfaceDecl *interfDecl = (ObjCInterfaceDecl *)decl;
                ObjcInterfaceName = interfDecl->getNameAsString();
                vector<string> protoVec;
                string filePath = this->context->getSourceManager().getFilename(interfDecl->getSourceRange().getBegin()).str();
                //如果解析到一个OC的interface定义。则把其所有引用的protocol记录下来。
                for (ObjCList<ObjCProtocolDecl>::iterator it = interfDecl->all_referenced_protocol_begin(); it != interfDecl->all_referenced_protocol_end(); it++) {
                    protoVec.push_back((*it)->getNameAsString());
                }
                auto it = classMap.find(ObjcInterfaceName);
                JClass cls(ObjcInterfaceName, filePath);
                if (it != classMap.end()) cls = it->second;
                cls.appenProtocols(protoVec);
                if (interfDecl->getSuperClass()) {
                    cls.setSuperClassName(interfDecl->getSuperClass()->getNameAsString());
                }
                classMap.insert(make_pair(ObjcInterfaceName, cls));
            }
            //category和类一视同仁。。。
            if (isa<ObjCCategoryDecl>(decl)) {
                ObjCCategoryDecl *categoryDecl = (ObjCCategoryDecl *)decl;
                ObjcInterfaceName = categoryDecl->getClassInterface()->getNameAsString();
                string filePath = this->context->getSourceManager().getFilename(categoryDecl->getSourceRange().getBegin()).str();
                vector<string> protoVec;
                for (ObjCList<ObjCProtocolDecl>::iterator it = categoryDecl->protocol_begin(); it != categoryDecl->protocol_end(); it++) {
                    protoVec.push_back((*it)->getNameAsString());
                }
                auto it = classMap.find(ObjcInterfaceName);
                JClass cls(ObjcInterfaceName, filePath);
                if (it != classMap.end()) cls = it->second;
                cls.appenProtocols(protoVec);
                classMap.insert(make_pair(ObjcInterfaceName, cls));
            }
            
            //当前为Protocol
            if (isa<ObjCProtocolDecl>(decl)) {
                ObjCProtocolDecl *protoDecl = (ObjCProtocolDecl *)decl;
                ObjcProtocolName = protoDecl->getNameAsString();
                string filePath = this->context->getSourceManager().getFilename(protoDecl->getSourceRange().getBegin()).str();
                
                vector<string> refProtos;
                //如果解析到protocol的定义。 则因此记录下这些protcol的名字（protocol继承链）
                for (ObjCProtocolList::iterator it = protoDecl->protocol_begin(); it != protoDecl->protocol_end(); it++) {
                    refProtos.push_back((*it)->getNameAsString());
                }
                JProtocol protocl(ObjcProtocolName, filePath);
                protocl.appendProtocols(refProtos);
                protocolMap.insert(make_pair(ObjcProtocolName, protocl));
            }
            
            //如果是OC的implementation的定义
            if (isa<ObjCImplDecl>(decl)) {
                ObjCImplDecl *interDecl = (ObjCImplDecl *)decl;
                string interName = interDecl->getClassInterface()->getNameAsString();
                //拿到implementation名
                ObjcImplementationName = interName;
            }
            
            
            //如果当前定义为OC方法
            if (isa<ObjCMethodDecl>(decl)) {
                ObjCMethodDecl *methodDecl = (ObjCMethodDecl *)decl;
                string selName = methodDecl->getSelector().getAsString();
                string filePath = this->context->getSourceManager().getFilename(methodDecl->getSourceRange().getBegin()).str();
                //通常implementation晚于interface和protocol
                //所以此时说明解到了implementation。 我们只管方法的定义
                if (ObjcImplementationName.length()) {
                    bool isInstanceMethod = methodDecl->isInstanceMethod();
                    string filePath = this->context->getSourceManager().getFilename(methodDecl->getSourceRange().getBegin()).str();
                    JMethod method(isInstanceMethod, selName, ObjcImplementationName, filePath);
                    
                    allMethods.insert(make_pair(method.methodID, method));
                    
                    LangOptions LangOpts;
                    LangOpts.ObjC = true;
                    PrintingPolicy Policy(LangOpts);
                    string sMethod;
                    raw_string_ostream paramMethod(sMethod);
                    methodDecl->print(paramMethod, Policy);
                    sMethod = paramMethod.str();
                    //如果是ibaction方法，则认为是被使用的
                    if (sMethod.find("__attribute__((ibaction))") != string::npos) {
                        usedMethods.insert(make_pair(method.methodID, method));
                    }
                }
                //protocol中的也要保存下来
                else if (ObjcProtocolName.length()) {
                    bool isInstanceMethod = methodDecl->isInstanceMethod();
                    string filePath = this->context->getSourceManager().getFilename(methodDecl->getSourceRange().getBegin()).str();
                    //这种的methodID就以protocol命名把，后面比较selector
                    JMethod method(isInstanceMethod, selName, ObjcProtocolName, filePath);
                    //把方法加入到protocol中。
                    JProtocol protocol = protocolMap[ObjcProtocolName];
                    protocol.methods.push_back(method);
                }
                //头文件中的不管。因为如果没有定义可以通过Clang的warning知道。 一般不会存在这种情况
            }
            
            return true;
        }
        
        bool VisitStmt(Stmt *s) {
            if (isa<ObjCMessageExpr>(s)) {
                //转换为OC表达式
                ObjCMessageExpr *objcExpr = (ObjCMessageExpr *)s;
                //获取调用的接受者是类方法or实例方法
                ObjCMessageExpr::ReceiverKind kind = objcExpr->getReceiverKind();
                //获取callee
                string calleeSel = objcExpr->getSelector().getAsString();
                string receiverType = objcExpr->getReceiverType().getAsString();
                ObjCInterfaceDecl *interfaceDecl = objcExpr->getReceiverInterface();
                bool isInstanceMethod = true;
                LangOptions LangOpts;
                LangOpts.ObjC = true;
                PrintingPolicy Policy(LangOpts);
                switch (kind) {
                    case ObjCMessageExpr::Class:
                    case ObjCMessageExpr::SuperClass:
                        isInstanceMethod = false;
                        break;
                    default:
                        break;
                }
                
                if (!interfaceDecl || (receiverType.find("<") != string::npos && receiverType.find(">") != string::npos)) {
                    cout << "未知接受者: " << receiverType + " " + calleeSel << endl;
                }
                
                int paramCount = objcExpr->getNumArgs();
                //            cout << "receiverType: " << receiverType << " " << calleeSel + " argCount: " << paramCount << endl;
                bool isSelectorCall = false;
                //遍历参数
                for (int i = 0; i < paramCount; i++) {
                    Expr *argExpr = objcExpr->getArg(i);
                    if (!argExpr) {
                        cout << "argExpr is None" << endl;
                        continue;
                    }
                    
                    //如果某个参数是ObjCSelectorExpr说明通过selector调用
                    if (isa<ObjCSelectorExpr>(argExpr)) {
                        isSelectorCall = true;
                        ObjCSelectorExpr *selExpr = (ObjCSelectorExpr *)argExpr;
                        //说明是非显式对象调用，应该是通过delegate，这种直接放在后面遍历类的delegate
                        if (!interfaceDecl) {
                            cout << "非显式调用: " << receiverType << selExpr->getSelector().getAsString() << endl;
                        }
                        //显式调用，可以直接加到使用的方法的列表中
                        else {
                            //如果是timer，Notification，NSTread
                            string cls = interfaceDecl->getNameAsString();
                            if (strstr(cls.c_str(), "NSTimer") ||
                                strstr(cls.c_str(), "NSNotificationCenter") ||
                                strstr(cls.c_str(), "NSThread") ||
                                strstr(cls.c_str(), "CADisplayLink")) {
                                cls = ObjcImplementationName;
                            }
                            string cls = interfaceDecl->getNameAsString();
                            string sel = selExpr->getSelector().getAsString();
                            JMethod method(isInstanceMethod, sel, cls, "");
                            cout << "显式调用: " << method.methodID << endl;
                            usedMethods.insert(make_pair(method.methodID, method));
                        }
                    }
                }
                //正常调用
                if (!isSelectorCall) {
                    //说明是非显式对象调用，应该是通过delegate，这种直接放在后面遍历类的delegate
                    if (!interfaceDecl) {
                        cout << "非显式调用: " << receiverType << calleeSel << endl;
                    } else {
                        string cls = interfaceDecl->getNameAsString();
                        JMethod method(isInstanceMethod, calleeSel, cls, string());
                        usedMethods.insert(make_pair(method.methodID, method));
                    }
                }
            }
            //还有一种特殊情况是通过msgSend直接调用的。不过仍然需要传入selector
            //这一种C风格的调用
            //        if (isa<CallExpr> (s)) {
            //            CallExpr *callExpr = (CallExpr *)s;
            //            callExpr->getArgs();
            //            Expr *calleeExpr = callExpr->getCallee();
            //            callExpr->
            //        }
            //
            //        if (isa<ObjCSelectorExpr>(s)) {
            //            ObjCSelectorExpr *selectorExpr = (ObjCSelectorExpr *)s;
            //            string selName = selectorExpr->getSelector().getAsString();
            //
            //        }
            
            return true;
        }
    };
    
    class MyASTConsumer : public ASTConsumer
    {
    private:
        MyASTVisitor visitor;
        void HandleTranslationUnit(ASTContext &context) {
            visitor.setContext(context);
            visitor.TraverseDecl(context.getTranslationUnitDecl());
            //没解析一个Object更新一次数据
            visitor.parseData();
        }
    };
    class MyASTAction : public PluginASTAction
    {
    public:
        unique_ptr<ASTConsumer> CreateASTConsumer(CompilerInstance &Compiler, StringRef InFile) {
            return unique_ptr<MyASTConsumer>(new MyASTConsumer);
        }
        bool ParseArgs(const CompilerInstance &CI, const std::vector<std::string> &args) {
            for (string arg : args) {
                cout << arg << endl;
            }
            return true;
        }
        
    };
    }
static clang::FrontendPluginRegistry::Add
< UnusedCodePlugin::MyASTAction > X("MyPlugin",
                                    "MyPlugin");
