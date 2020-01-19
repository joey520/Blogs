//
//  CrashHandler.m
//  TestSignal
//
//  Created by Joey Cao on 2020/1/18.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import "CrashHandler.h"
#define DEBUGLOG (0)
static NSUncaughtExceptionHandler *preExceptionHandler = nil;
static NSArray *needCatchedSignals = NULL;
static CrashSignalActionBlock signalActionBlock;
static CrashExceptionHandlerBlock exceptionHandlerBlock;

//保存上一次的sa_sigaction
typedef void (*SignalActionTemplate)(int signo, siginfo_t *info, void *context);
//保存上一次的sa_handler
typedef void (*SignalHandlerTemplate)(int signo);
static SignalActionTemplate preSignalActions[32];
static SignalHandlerTemplate preSignalHandlers[32];

@implementation CrashHandler

+ (void)registerSignalAction:(CrashSignalActionBlock)action {
    signalActionBlock = action;
}

+ (void)registerExceptionHandler:(CrashExceptionHandlerBlock)handler {
    exceptionHandlerBlock = handler;
}

+ (void)startWithSignals:(NSArray *)array {
    if (array.count > 0) {
        needCatchedSignals = [array copy];
    } else {
        [self defaultCatchedSignals];
    }
}

+ (void)defaultCatchedSignals {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        needCatchedSignals = @[ @(SIGHUP),
                                @(SIGINT),
                                @(SIGQUIT),
                                @(SIGABRT),
                                @(SIGILL),
                                @(SIGSEGV),
                                @(SIGFPE),
                                @(SIGBUS),
                                @(SIGPIPE) ];
    });
}

//MARK: - Exception
static void ExceptionHandler(NSException *exception) {
    if (exceptionHandlerBlock) {
        exceptionHandlerBlock(exception);
    }
}

- (void)startExceptionCatch {
    if (NSGetUncaughtExceptionHandler()) {
        preExceptionHandler = NSGetUncaughtExceptionHandler();
    }
    NSSetUncaughtExceptionHandler(ExceptionHandler);
}

//MARK: - Signals
static void SignalAction(int signo, siginfo_t *info, void *context) {
    if (signalActionBlock) {
        signalActionBlock(signo, info, context);
    }
    //把信号传递出去
    if (preSignalActions[signo]) {
        SignalActionTemplate tmpAction = preSignalActions[signo];
        tmpAction(signo, info, context);
    }
    
    if (preSignalHandlers[signo]) {
        SignalHandlerTemplate tmpHandler = preSignalHandlers[signo];
        tmpHandler(signo);
    }
}

- (void)startSignalCatch {
    for (NSNumber *signalValue in needCatchedSignals) {
        int signo = signalValue.intValue;
        //首先获取old_action
        struct sigaction old_action;
        bzero(&old_action, sizeof(sigaction));
        //获取旧的action
        int ret = sigaction(signo, NULL, &old_action);
        if (ret < 0) {
            printf("sigaction old action failed: %s\n", strerror(errno));
        }
#if DEBUGLOG
        printf("old_action sa_mask: %8.8d\n", old_action.sa_mask);
        printf("old_action sa_flags: %8.8d\n", old_action.sa_flags);
#endif
        //如果已经有注册的sigaction
        if (old_action.sa_flags & SA_SIGINFO) {
            //这个宏可以简化书写其实就是去了handler指针.
            //把已有的处理函数指针保存下来
            preSignalActions[signo] = old_action.sa_sigaction;
        }
        //注意sa_handler和sa_sigaction是不能共存的
        else if (old_action.sa_handler) {
            preSignalHandlers[signo] = old_action.sa_handler;
        }

        //注册新的handler
        //清空屏蔽字
        struct sigaction new_action;
        bzero(&new_action, sizeof(sigaction));
        sigemptyset(&new_action.sa_mask);
        new_action.sa_sigaction = SignalAction;
        //设置SA_SIGINFO标记位
        new_action.sa_flags = SA_NODEFER | SA_SIGINFO;

        //注册新的action
        ret = sigaction(SIGALRM, &new_action, NULL);
        if (ret < 0) {
            printf("sigaction new action failed: %s\n", strerror(errno));
        }
    }
}

@end
