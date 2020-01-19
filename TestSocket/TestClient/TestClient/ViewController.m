//
//  ViewController.m
//  TestSocket
//
//  Created by Joey Cao on 2019/12/8.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "ViewController.h"
#import "TestClient.h"
#import "TestClient1.h"
#import "CommonFunctions.h"

#define TEST_DJI (1)
#define CLIENT_INDEX (1)

@interface ViewController () <TestClientDelegate> {
    BaseClient *_client;

    NSMutableString *_msgs;
}
@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (weak, nonatomic) IBOutlet UITextView *recvTextField;
@property (weak, nonatomic) IBOutlet UITextField *sendTextField;
@property (weak, nonatomic) IBOutlet UIButton *connectBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _hostTextField.text = @"127.0.0.1";
    _portTextField.text = @"2234";
}

- (IBAction)onConnectBtnClicked:(id)sender {
    if (!_client) {
        switch (CLIENT_INDEX) {
            case 0:
                _client = [[TestClient alloc] initWithHost:self.hostTextField.text port:self.portTextField.text.intValue];
                break;
            case 1:
                _client = [[TestClient1 alloc] initWithHost:self.hostTextField.text port:self.portTextField.text.intValue];
                break;

            default:
                break;
        }
        _client.delegate = self;
    }
    [_client start];
    _msgs = [NSMutableString string];
}

- (IBAction)onCloseBtnClicked:(id)sender {
    [_client closeServer];
}
- (IBAction)onSendBtnClicked:(id)sender {
    [_client sendMsg:_sendTextField.text];
}

- (void)service:(BaseClient *)service didReceiveEvent:(int)event {
    NSLog(@"receive event: %d", event);
}

- (void)service:(BaseClient *)service didReadBuffer:(uint8_t *)buffer length:(int)length {
    NSString *str = [NSString stringWithCString:(char *)buffer encoding:NSUTF8StringEncoding];
    [_msgs appendFormat:@"%@\n", str];
    dispatch_sync(dispatch_get_main_queue(), ^{
        self.recvTextField.text = _msgs;
    });
}

@end
