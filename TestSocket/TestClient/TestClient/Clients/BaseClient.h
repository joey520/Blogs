//
//  BaseClient.h
//  TestSocket
//
//  Created by Joey Cao on 2019/12/8.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonFunctions.h"

typedef NS_ENUM(NSUInteger, TestClientEvent) {
    TestClientEventConnectSuccess,   //连接成功
    TestClientEventConnectBroken,   //连接中断（连接被外部中断）
    TestClientEventConnectFailed,     //连接失败（连接不成功）
    TestClientEventConnectClosed,    //连接关闭（主动关闭连接）
};

@class BaseClient;

@protocol TestClientDelegate <NSObject>

- (void)service:(BaseClient *)service didReceiveEvent:(int)event;

- (void)service:(BaseClient *)service didReadBuffer:(uint8_t *)buffer length:(int)length;

@end

@protocol TestClientInterface <NSObject>

-(instancetype) initWithHost:(NSString*)host port:(int)port;

- (void)start;

- (void)closeServer;

- (void)sendMsg:(NSString *)msg;

@end

@interface BaseClient : NSObject <TestClientInterface>

@property (nonatomic, weak) id <TestClientDelegate>delegate;

@end
