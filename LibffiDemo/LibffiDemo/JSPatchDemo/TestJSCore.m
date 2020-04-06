//
//  TestJSCore.m
//  LibffiDemo
//
//  Created by Joey Cao on 2020/4/5.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import "TestJSCore.h"
#import "JPEngine.h"


@implementation TestJSCore

+ (void)test {
    [JPEngine startEngine];

    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"TestJSCore" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:sourcePath encoding:NSUTF8StringEncoding error:nil];
    [JPEngine evaluateScript:script];
    
    sleep(2);
    
}


+ (id)func1:(NSNumber *)idx {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return @(10);
}

- (id)func2:(NSNumber *)idx {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return @(20);
}
@end
