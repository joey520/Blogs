//
//  TestServer.m
//  TestSocket
//
//  Created by Joey Cao on 2019/12/8.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "TestServer.h"
#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <netinet/tcp.h>

#define MAX_BUFFER_SIZE (1024)
#define MAX_LISTEN_COUNT (10)
#define PORT (2234)
#define INVALID_SOCKET (-1)
#define MAX_BUFFER_SIZE (1024)

@interface TestServer () {
    BOOL _isClosed;
    int _server_socket_fd;
    NSMutableArray *_connectedClients;
    NSThread *_workQueue;
}

@end

@implementation TestServer

- (instancetype)init {
    self = [super init];
    if (self) {
        _server_socket_fd = INVALID_SOCKET;
    }

    return self;
}

- (BOOL)initServer {
    if (_server_socket_fd != INVALID_SOCKET) {
        return true;
    }
    //设置一个服务器地址
    struct sockaddr_in server_addr;
    //初始化数据为0
    bzero(&server_addr, sizeof(server_addr));
    //IPV4网络
    server_addr.sin_family = AF_INET;
    //INADDR_ANY表示不需要绑定特定的IP，此时会使用本地主机localhost
    server_addr.sin_addr.s_addr = htons(INADDR_ANY);
    //设置端口号
    server_addr.sin_port = htons(PORT);

    //初始化socket, 传输方式为TCP
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        SERVER_LOG("Create Socket Failed!, errno: %s\n", strerror(errno));
        return false;
    }

    //设置参数
    struct linger l;
    l.l_linger = 0;
    l.l_onoff = 1;
    int intval = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_LINGER, &l, sizeof(struct linger));
    //设置可以重用地址，否则端口不能重复绑定
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &intval, sizeof(int));
    //设置取消`Nagle`算法
    setsockopt(server_socket, IPPROTO_TCP, TCP_NODELAY, &intval, sizeof(int));
    //设置取消`SIGPIPE`信号
    setsockopt(server_socket, SOL_SOCKET, SO_NOSIGPIPE, &intval, sizeof(int));

    fd_set read_sets;
    FD_ZERO(&read_sets);
    FD_SET(server_socket, &read_sets);

    //使socket绑定到对应的地址
    int ret = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (ret != 0) {
        SERVER_LOG("Server Bind port : %d Failed!, errno: %s \n", PORT, strerror(errno));
        return false;
    }

    //设置最大连接数，并开始监听
    ret = listen(server_socket, MAX_LISTEN_COUNT);
    if (ret != 0) {
        SERVER_LOG("Server Listen Failed!, errno: %s\n", strerror(errno));
        return false;
    }
    _server_socket_fd = server_socket;

    return true;
}

- (void)run {
    _isClosed = false;
    SERVER_LOG("Server start......\n");
    //为了避免线程终止，需要一直run
    while (!_isClosed && _server_socket_fd != -1) {
        @autoreleasepool {
            //定义客户端的socket地址结构client_addr
            struct sockaddr_in client_addr;
            socklen_t length = sizeof(client_addr);

            //接受一个到server_socket代表的socket的一个连接
            //如果没有连接请求,就会阻塞在这里等待第一个连接到来
            //accept函数返回一个新的socket,这个new_server_socket即连接的客户端socket
            int new_client_socket = accept(_server_socket_fd, (struct sockaddr *)&client_addr, &length);
            if (new_client_socket < 0) {
                SERVER_LOG("Server Accept Failed, errno: %s!\n", strerror(errno));
                break;
            }
            [_connectedClients addObject:@(new_client_socket)];
            if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didUpdateConnectedClients:)]) {
                [self.delegtate server:self didUpdateConnectedClients:_connectedClients.copy];
            }
            SERVER_LOG(" one client connted: %d\n", new_client_socket);
            //单个socket的通信应该放在自己的线程中
            [NSThread detachNewThreadSelector:@selector(readData:)
                                     toTarget:self
                                   withObject:[NSNumber numberWithInt:new_client_socket]];
        }
    }
    //走到这里说明需要关闭监听用的socket
    close(_server_socket_fd);
    SERVER_LOG("Close server\n");
}

// 读客户端数据
- (void)readData:(NSNumber *)clientSocket {
    char buffer[MAX_BUFFER_SIZE];
    int intSocket = [clientSocket intValue];

    //这里我们规定当客户端发来"-"时表示需要终止连接
    while (buffer[0] != '-' && _server_socket_fd != -1 && [_connectedClients containsObject:clientSocket]) {
        @autoreleasepool {
            bzero(buffer, MAX_BUFFER_SIZE);
                   //接收客户端发送来的信息到buffer中
                   size_t recv_length = recv(intSocket, buffer, MAX_BUFFER_SIZE, 0);
                   SERVER_LOG("recv length : %ld\n", recv_length);
                   if (recv_length > 0) {
                       SERVER_LOG("client:%s\n", buffer);
                       if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didReceiveBuffer:length:socket:)]) {
                           [self.delegtate server:self didReceiveBuffer:buffer length:(int)recv_length socket:clientSocket.intValue];
                       }
                   } else if (recv_length == 0) {
                       SERVER_LOG("Client disconnected\n");
                       [self closeClient:clientSocket];
                   } else {
                       SERVER_LOG("receive data error: %s\n", strerror(errno));
                   }
        }
    }
    //关闭与客户端的连接
    SERVER_LOG("client:close\n");
    close(intSocket);
}

- (void)closeClient:(NSNumber *)client {
    SERVER_LOG("close client: %d", client);
    int client_fd = [client intValue];
    close(client_fd);
    [_connectedClients removeObject:client];
}

- (void)sendMsg:(NSString *)msg toSocket:(int)client_fd {
    if (![_connectedClients containsObject:@(client_fd)]) {
        SERVER_LOG("client invalid");
        return;
    }
    size_t length = msg.length;
    const char *buffer = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(client_fd, buffer, length, 0);
}

- (BOOL)startListen {
    BOOL ret = [self initServer];
    if (ret) {
        _connectedClients = [NSMutableArray array];
        _workQueue = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [_workQueue setName:@"Server Work Queue"];
        [_workQueue start];

    }
    
    return ret;
}

- (BOOL)stopListen {
    _isClosed = true;
    close(_server_socket_fd);
    _server_socket_fd = -1;
    _workQueue = nil;
    return true;
}

- (BOOL)isRunning {
    return (!_isClosed && _server_socket_fd != INVALID_SOCKET);
}
@end
