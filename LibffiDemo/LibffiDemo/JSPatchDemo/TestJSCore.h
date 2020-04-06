//
//  TestJSCore.h
//  LibffiDemo
//
//  Created by Joey Cao on 2020/4/5.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TestJSCore : NSObject

+ (void)test;

+ (id)func1:(NSNumber *)idx;

- (id)func2:(NSNumber *)idx;

@end

NS_ASSUME_NONNULL_END
