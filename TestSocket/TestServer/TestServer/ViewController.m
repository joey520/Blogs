//
//  ViewController.m
//  TestServer
//
//  Created by Joey Cao on 2019/12/8.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "ViewController.h"
#import "TestServer.h"
#import "TestServer1.h"


#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <netinet/tcp.h>


#define TEST (0)
#define SERVER_INDEX (1)
@interface ViewController () <TestServerDelegate> {
    BaseServer *_server;
    NSMutableString *_msgs;
}
@property (weak, nonatomic) IBOutlet UITextView *recvTextField;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UITextField *clientTextField;
@property (weak, nonatomic) IBOutlet UILabel *connentedClientLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    switch (SERVER_INDEX) {
        case 0:
            _server = (BaseServer *)[TestServer new];
            break;
        case 1:
            _server = (BaseServer *)[TestServer1 new];
            break;

        default:
            break;
    }

    _server.delegtate = self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
}

- (IBAction)onStartClicked:(id)sender {
    [_server startListen];
    _msgs = [NSMutableString string];
}

- (IBAction)onStopClicked:(id)sender {
    [_server stopListen];
}
- (IBAction)onSendClicked:(id)sender {
#if TEST
    //模拟下千寻发包
    BOOL ret = [_server isRunning];
    if (!ret) {
        ret = [_server startListen];
    }

    if (ret) {
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                        repeats:YES
                                          block:^(NSTimer *_Nonnull timer) {
                                              int buffer[414];

                                              //                                                     for (int i = 0; i < 414; i++) {
                                              //                                                         int temp = arc4random();
                                              //                                                         buffer[i] = temp;
                                              [self->_server sendMsg:@"joey.cao" toSocket:[self.clientTextField.text intValue]];
                                              //                                                     }
                                          }];
    }
#endif
    [_server sendMsg:_sendTextField.text
            toSocket:[self.clientTextField.text intValue]];
}

- (void)server:(TestServer *)server didReceiveBuffer:(char *)buffer length:(int)length socket:(int)client_fd {
    NSString *str = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    [_msgs appendFormat:@"client: %d, msg: %@\n", client_fd, str];
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.recvTextField.text = _msgs;
    });
}

- (void)server:(TestServer *)server didUpdateConnectedClients:(nonnull NSArray *)client_fds {
    NSMutableString *str = [NSMutableString string];
    for (NSNumber *socketValue in client_fds) {
        [str appendFormat:@"%@, ", socketValue];
    }
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.connentedClientLabel.text = str;
        ShowResultAutoDismiss(@"current connected client:\n %@", client_fds);
    });
}

@end

