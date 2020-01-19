//
//  BaseServer.m
//  TestServer
//
//  Created by Joey Cao on 2019/12/10.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "BaseServer.h"

@implementation BaseServer
- (BOOL)isRunning {
    return false;
}

- (void)sendMsg:(nonnull NSString *)msg toSocket:(int)client_fd {
}

- (BOOL)startListen {
    return true;
}

- (BOOL)stopListen {
    return true;
}

@end
