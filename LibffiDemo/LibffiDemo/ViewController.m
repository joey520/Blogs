//
//  ViewController.m
//  LibffiDemo
//
//  Created by Joey Cao on 2020/4/4.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

// Block internals.
typedef NS_OPTIONS(int, AspectBlockFlags) {
    AspectBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    AspectBlockFlagsHasSignature = (1 << 30)
};

typedef struct _AspectBlock {
    __unused Class isa;
    AspectBlockFlags flags;
    __unused int reserved;
    void(__unused *invoke)(struct _AspectBlock *block, ...);
    //Descriptor中保存了Block结构信息
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires AspectBlockFlagsHasCopyDisposeHelpers
        //如果是__NSMallocBlock__则方法签名保存在copy
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires AspectBlockFlagsHasSignature
        //如果是__NSGlobalBlock__，则方法签名保存signature
        const char *signature;
        const char *layout;
    } * descriptor;
    // imported variables
} * AspectBlockRef;

#import "TestJSCore.h"
#import "TestLibffi.h"

#import <JavaScriptCore/JavaScriptCore.h>
@interface ViewController () {
}

@property (nonatomic) NSString *name;
@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic) NSOperationQueue *opQueue;

@property (nonatomic) int sem;

@end

@implementation ViewController

@dynamic name;

void test(int a) {
    NSLog(@"--%d", a);
}

- (void)viewDidLoad {
    [super viewDidLoad];

    
    
//    [TestJSCore test];
    [TestLibffi test];
}


@end
