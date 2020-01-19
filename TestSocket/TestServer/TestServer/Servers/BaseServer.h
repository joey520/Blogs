//
//  BaseServer.h
//  TestServer
//
//  Created by Joey Cao on 2019/12/10.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonFunctions.h"

NS_ASSUME_NONNULL_BEGIN

@class BaseServer;
@protocol TestServerDelegate <NSObject>

- (void)server:(BaseServer *)server didReceiveBuffer:(char *)buffer length:(int)length socket:(int)client_fd;

- (void)server:(BaseServer *)server didUpdateConnectedClients:(NSArray *)client_fds;

@end

@protocol TestServerInterfaces <NSObject>

@optional

- (BOOL)startListen;

- (BOOL)stopListen;

- (void)sendMsg:(NSString *)msg toSocket:(int)client_fd;

- (BOOL)isRunning;


@end

@interface BaseServer : NSObject <TestServerInterfaces>

@property (nonatomic, weak) id <TestServerDelegate> delegtate;

@end

NS_ASSUME_NONNULL_END
