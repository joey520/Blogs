//
//  CrashHandler.h
//  TestSignal
//
//  Created by Joey Cao on 2020/1/18.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^_Nonnull CrashExceptionHandlerBlock)(NSException *_Nonnull);
typedef void (^_Nonnull CrashSignalActionBlock)(int signo, siginfo_t *info, void *context);

@interface CrashHandler : NSObject

//注入一个特定异常捕获时的操作
+ (void)registerExceptionHandler:(CrashExceptionHandlerBlock)handler;

//注入一个特定的信号捕获时的操作
+ (void)registerSignalAction:(CrashSignalActionBlock)action;

//传入需要捕获的Signal, 如果传空，则捕获一些常见的signal
+ (void)startWithSignals:(NSArray *_Nullable)array;

@end

NS_ASSUME_NONNULL_END
