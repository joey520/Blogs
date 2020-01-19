//
//  TestClient.m
//  TestSocket
//
//  Created by Joey Cao on 2019/12/8.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "TestClient.h"
#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

#define INVALID_SOCKET (-1)
#define MAX_BUFFER_SIZE (1024)

@interface TestClient () {
    BOOL _isConnected;
    NSString *_host;
    int _port;

    int server_socket_fd;

    struct sockaddr_in _serverAddress;
}

@end

@implementation TestClient

- (instancetype)initWithHost:(NSString *)host port:(int)port {
    self = [super init];
    if (self) {
        _host = host;
        _port = port;
    }
    return self;
}

- (void)start {
    //IPV4 字节流
    int temp_socket_fd = socket(AF_INET, SOCK_STREAM, 0);
    //创建用于internet的流协议(TCP)socket,
    //用server_socket代表服务器socket
    if (temp_socket_fd < 0) {
        CLIENT1_LOG("Create Socket Failed!, errno: %s", strerror(errno));
        return;
    }

    if ([self handleAddress] == false) {
        close(temp_socket_fd);
        CLIENT_LOG("handle host failed, errno: %s", strerror(errno));
        return;
    }


    int ret = connect(temp_socket_fd, (const struct sockaddr *)&_serverAddress, sizeof(_serverAddress));
    if (ret < 0) {
        CLIENT_LOG("Connect failed, errno: %s", strerror(errno));
        return;
    }

    CLIENT_LOG("connect success: %d", server_socket_fd);
    server_socket_fd = temp_socket_fd;
    _isConnected = true;
    [NSThread detachNewThreadSelector:@selector(receiveMsg) toTarget:self withObject:nil];

    return;
}


- (BOOL)handleAddress {
    struct hostent *he;
    struct sockaddr_in server;

    NSString *ip = [_host copy];
    NSString *port = [NSString stringWithFormat:@"%d", _port];

    if ((he = gethostbyname([ip cStringUsingEncoding:NSUTF8StringEncoding])) == NULL) {
        CLIENT_LOG("gethostbyname error: %s", strerror(errno));
        return false;
    }

    bzero(&server, sizeof(server));

    server.sin_family = AF_INET;
    server.sin_port = htons([port intValue]);
    server.sin_addr = *((struct in_addr *)he->h_addr);

    _serverAddress = server;
    return true;
}

- (void)closeServer {
    close(server_socket_fd);
    server_socket_fd = INVALID_SOCKET;
    _isConnected = false;
}

- (void)sendMsg:(NSString *)msg {
    if (!_isConnected) {
        return;
    }
    size_t length = msg.length;
    void *buffer = (void *)[msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(server_socket_fd, buffer, length, 0);
}

- (void)receiveMsg {
    while (_isConnected && server_socket_fd != INVALID_SOCKET) {
        char buffer[MAX_BUFFER_SIZE];
        size_t recv_size = recv(server_socket_fd, buffer, MAX_BUFFER_SIZE, 0);
        if (recv_size > 0) {
            NSString *str = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
            CLIENT_LOG("recv: %ld, msg: %@", recv_size, str);
            if (self.delegate && [self.delegate respondsToSelector:@selector(service:didReadBuffer:length:)]) {
                [self.delegate service:self didReadBuffer:(uint8_t *)buffer length:(int)recv_size];
            }

        } else if (recv_size == 0) {
            CLIENT_LOG("server close down!");
            [self closeServer];
        } else {
            CLIENT_LOG("recv data error: %ld, errno: %s", recv_size, strerror(errno));
        }
    }
}

@end
