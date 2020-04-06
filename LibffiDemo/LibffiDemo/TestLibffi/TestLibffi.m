//
//  TestLibffi.m
//  LibffiDemo
//
//  Created by Joey Cao on 2020/4/5.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import "TestLibffi.h"
#import "ffi.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation TestLibffi

int fun1(int a, int b) {
    return a + b;
}

int fun2(int a, int b) {
    return 2 * a + b;
}

+ (void)test {

//    [self tsetffi_cif];

//    [self testffi_prep_closure_loc];

    [self testHookedOC];
}

+ (void)tsetffi_cif {
    //参数类型
    ffi_type **types;
    //typeEncoding
    types = malloc(sizeof(ffi_type *) * 2);
    //两个int
    types[0] = &ffi_type_sint;
    types[1] = &ffi_type_sint;
    //返回值类型
    ffi_type *retType = &ffi_type_sint;

    //设置参数
    void **args = malloc(sizeof(void *) * 2);
    int x = 1, y = 2;
    args[0] = &x;
    args[1] = &y;

    int ret;

    //ffi调用模板
    ffi_cif cif;
    //初始化模板，传入 ABI, 参数个数， 返回值类型和方法签名
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, retType, types);
    // 动态调用fun1
    ffi_call(&cif, (void (*)(void))fun1, &ret, args);

    NSLog(@"--- %d", ret);
}

void ffi_hookFunc(ffi_cif *cif, void *ret, void **args, void *userdata) {
    NSLog(@"Hook function");
    
    __unused TestLibffi *libffi = (__bridge TestLibffi *)userdata;
    //这里再进行消息转发。
}

+ (void)testffi_prep_closure_loc {
//    替换方法。 由于替换的类方法，这里需要取到metaClass
    SEL sel = @selector(test:name:);
    Method m = class_getClassMethod(self, sel);
    const char *typeEncoding = method_getTypeEncoding(m);

    ffi_type **types;
    //构建参数类型
    types = malloc(sizeof(ffi_type *) * 2);
    //两个参数，第一个为int，第二个为NSSting *
    types[0] = &ffi_type_sint;
    types[1] = &ffi_type_pointer;
    //返回值类型
    ffi_type *retType = &ffi_type_void;
    //创建函数调用模板
    ffi_cif cif;
    ffi_prep_cif(&cif, FFI_DEFAULT_ABI, 2, retType, types);

    //声明一个函数指针
    void *imp = NULL;
    //创建closure,就是一个函数闭包。 它包含了一个函数指针。
    ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&imp);

    //该方法通过closure把 函数原型，函数实体，上下文已经函数指针关联起来。
    //第一个参数closure
    //第二个参数是调用模板
    //第三个是Hook后的函数指针
    //第四个是传入的userdata。 你可以传入任何数据，作为传递时的调用。 这样在外部调用是就会把self作为userdata传递过去
    //第五个是之前闭包的指针。
    ffi_prep_closure_loc(closure, &cif, ffi_hookFunc, (__bridge void *)(self), imp);
    
    //释放闭包
    ffi_closure_free(closure);

    //如果当前没有这个方法，尝试添加，如果有的话替换IMP。 此时imp就指向了ffi封装好的那个方法。并且在调用是把会userdata传入
    if (!class_addMethod(object_getClass(self), sel, imp, typeEncoding)) {
        class_replaceMethod(object_getClass(self), sel, imp, typeEncoding);
    }

    //调用一下。可以发现直接走到了ffi_function
    NSLog(@"hook 返回的: %@", [self test:28 name:@"joey.cao"]);
}

+ (NSString *)test:(int)age name:(NSString *)name {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [NSString stringWithFormat:@"My name is %@, age: %d", name, age];
}


+ (void)testHookedOC {
    Class cls = object_getClass(self);
    IMP msgForwardIMP = _objc_msgForward;
    class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)hookMsgForward, "v@:@");

    //再把test替换为forward
    SEL selector = @selector(test4444);
    Method method = class_getInstanceMethod(cls, selector);
    char *typeDescription = (char *)method_getTypeEncoding(method);
    if (typeDescription == NULL) {
        typeDescription = "v@:@";
    }
    if (!class_addMethod(cls, selector, msgForwardIMP, typeDescription)) {
        class_replaceMethod(cls, selector, msgForwardIMP, typeDescription);
    }

    //调用一下。可以发现直接走到了ffi_function
    NSLog(@"--- %@", [self test4444]);
}

+ (NSString *)test4444 {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return @"joey";
}
int hookOCFunc(id self, SEL _cmd, ...) {
    NSLog(@"-- Hooked OC");
    
    return 100;
}

void hookMsgForward(id self, SEL _cmd, NSInvocation *invocation) {
    __autoreleasing NSString *a = @"cao";
    [invocation setReturnValue:&a];
}

@end
