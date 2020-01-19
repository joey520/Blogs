//
//  TestServer1.m
//  TestServer
//
//  Created by Joey Cao on 2019/12/10.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "TestServer1.h"
#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include <pthread.h>


#define MAX_BUFFER_SIZE (1024)
#define MAX_LISTEN_COUNT (10)
#define PORT (2234)
#define INVALID_SOCKET (-1)
#define MAX_BUFFER_SIZE (1024)

@interface TestServer1 () {
    BOOL _isClosed;
    int _server_socket_fd;
    NSMutableArray *_connectedClients;
    NSThread *_workQueue;
    NSThread *_recvQueue;

    pthread_mutex_t _lock;
}

@end

@implementation TestServer1

- (instancetype)init {
    self = [super init];
    if (self) {
        _server_socket_fd = INVALID_SOCKET;
        _isClosed = true;
        pthread_mutex_init(&_lock, NULL);
    }

    return self;
}

- (BOOL)initServer {
    if (_server_socket_fd != INVALID_SOCKET) {
        return YES;
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
        SERVER1_LOG("Create Socket Failed!, errno: %s\n", strerror(errno));
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

    long arg;
    if ((arg = fcntl(server_socket, F_GETFL, NULL)) < 0) {
        SERVER1_LOG("fcntl failed: (%s)\n", strerror(errno));
        close(server_socket);
        return NO;
    }
    //设置为非阻塞式
    arg |= O_NONBLOCK;
    //如果要设置为阻塞式
    //    arg &= ~O_NONBLOCK;
    if (fcntl(server_socket, F_SETFL, arg) < 0) {
        SERVER1_LOG("fcntl failed: (%s)\n", strerror(errno));
        close(server_socket);
        return NO;
    }

    //使socket绑定到对应的地址
    int ret = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (ret != 0) {
        SERVER1_LOG("Server Bind port : %d Failed!, errno: %s \n", PORT, strerror(errno));
        return false;
    }

    //设置最大连接数，并开始监听
    ret = listen(server_socket, MAX_LISTEN_COUNT);

    if (ret != 0) {
        SERVER1_LOG("Server Listen Failed!, errno: %s\n", strerror(errno));
        return false;
    }
    _server_socket_fd = server_socket;
    _isClosed = false;

    return true;
}

- (void)run {
    while (_server_socket_fd != INVALID_SOCKET && !_isClosed) {
        //尝试accept，此时我们不关注client的地址，只保存client
        int client_socket_fd = accept(_server_socket_fd, NULL, NULL);
        if (client_socket_fd != INVALID_SOCKET) {
            fd_set error_set;
            FD_ZERO(&error_set);
            FD_SET(_server_socket_fd, &error_set);

            struct timeval tm;
            tm.tv_sec = 2;
            tm.tv_usec = 0;
            //由于是非阻塞,使用select来查看文件描述符的变化
            int ret = select(client_socket_fd + 1, NULL, NULL, &error_set, &tm);
            //如果文件描述符有变化
            if (ret > 0) {
                //如果client有errno
                if (FD_ISSET(client_socket_fd, &error_set)) {
                    SERVER1_LOG("client error: %s", strerror(errno));
                    close(client_socket_fd);
                }
            }
            //错误误
            else if (ret < 0) {
                SERVER1_LOG("client error: %s", strerror(errno));
                close(client_socket_fd);

            }
            //连接成功
            else {
                pthread_mutex_lock(&_lock);
                [_connectedClients addObject:@(client_socket_fd)];
                NSArray *tempArray = _connectedClients.copy;
                pthread_mutex_unlock(&_lock);

                if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didUpdateConnectedClients:)]) {
                    [self.delegtate server:self didUpdateConnectedClients:tempArray];
                }
            }
        }
    }
}

- (BOOL)startListen {
    if (!_isClosed) {
        ShowResultAutoDismiss(@"Server has already started");
        return YES;
    }
    BOOL ret = [self initServer];
    if (ret) {
        _connectedClients = [NSMutableArray array];
        _workQueue = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [_workQueue setName:@"Server1 Work Queue"];
        [_workQueue start];

        _recvQueue = [[NSThread alloc] initWithTarget:self selector:@selector(startRecv) object:nil];
        [_recvQueue setName:@"Server1 recv Queue"];
        [_recvQueue start];
    }
    return ret;
}

- (void)startRecv {
    //当有连接的client时，尝试recv
    while (self.isRunning && _server_socket_fd != INVALID_SOCKET) {
        pthread_mutex_lock(&_lock);
        NSArray *tempArray = _connectedClients.copy;
        pthread_mutex_unlock(&_lock);
        for (NSNumber *clientValue in tempArray) {
            int tmp_cilent_socket_fd = clientValue.intValue;
            fd_set read_set;
            FD_ZERO(&read_set);
            FD_SET(tmp_cilent_socket_fd, &read_set);

            struct timeval tm;
            tm.tv_sec = 1;
            tm.tv_usec = 0;

            int ret = select(tmp_cilent_socket_fd + 1, &read_set, NULL, NULL, &tm);
            //如果文件有可读
            if (ret > 0) {
                //如果发现文件描述符可读
                if (FD_ISSET(tmp_cilent_socket_fd, &read_set)) {
                    char buffer[MAX_BUFFER_SIZE] = { 0 };
                    int recv_size = (int)recv(tmp_cilent_socket_fd, buffer, MAX_BUFFER_SIZE, 0);
                    SERVER1_LOG("recv data from socket: %d, length: %d, msg: %s", tmp_cilent_socket_fd, recv_size, buffer);
                    //如果正确收到了数据
                    if (recv_size > 0) {
                        if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didReceiveBuffer:length:socket:)]) {
                            [self.delegtate server:self didReceiveBuffer:buffer length:recv_size socket:tmp_cilent_socket_fd];
                        }
                    }
                    //说明客户端已经关闭
                    else if (recv_size == 0) {
                        SERVER1_LOG("client: %d, has closed", tmp_cilent_socket_fd);
                        close(tmp_cilent_socket_fd);
                        [_connectedClients removeObject:clientValue];
                        if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didUpdateConnectedClients:)]) {
                            [self.delegtate server:self didUpdateConnectedClients:_connectedClients.copy];
                        }
                    }
                }
            }
            //如果有问题
            else if (ret < 0) {
                close(tmp_cilent_socket_fd);
                pthread_mutex_lock(&_lock);
                [_connectedClients removeObject:clientValue];
                NSArray *tempArray = _connectedClients.copy;
                pthread_mutex_unlock(&_lock);

                if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didUpdateConnectedClients:)]) {
                    [self.delegtate server:self didUpdateConnectedClients:tempArray];
                }
                SERVER1_LOG("client: %d select errno: %s, close it", tmp_cilent_socket_fd, strerror(errno));
            }
        }
    }
}

- (BOOL)stopListen {
    pthread_mutex_lock(&_lock);
    for (NSNumber *clientValue in _connectedClients) {
        close(clientValue.intValue);
    }
    [_connectedClients removeAllObjects];
    close(_server_socket_fd);
    _server_socket_fd = INVALID_SOCKET;
    _isClosed = true;
    pthread_mutex_unlock(&_lock);
    return YES;
}

- (void)sendMsg:(NSString *)msg toSocket:(int)client_fd {
    if (!self.isRunning || _server_socket_fd == INVALID_SOCKET) {
        SERVER1_LOG("sendMsg failed! server has been closed");
        return;
    }

    if (![_connectedClients containsObject:@(client_fd)]) {
        SERVER1_LOG("sendMsg failed! client:%d has been closed", client_fd);
        return;
    }

    const char *buffer = [msg cStringUsingEncoding:NSUTF8StringEncoding];
    int length = (int)msg.length;
    int needSendLength = length;
    //检测一下client是否有可写空间
    while (1) {
        fd_set write_set;
        FD_ZERO(&write_set);
        FD_SET(client_fd, &write_set);

        struct timeval tm;
        tm.tv_sec = 2;
        tm.tv_usec = 0;

        int ret = select(client_fd + 1, NULL, &write_set, NULL, &tm);
        if (ret > 0) {
            //可写
            if (FD_ISSET(client_fd, &write_set)) {

                int send_size = (int)send(client_fd, buffer, needSendLength, 0);
                //发送成功，且socket能全部写入缓存
                if (send_size == length) {
                    SERVER1_LOG("send msg success! client: %d, length: %d, msg: %s", client_fd, send_size, buffer);
                    break;
                }
                //发送失败
                else if (send_size < 0) {
                    //表明client已经断了
                    if (errno == SIGPIPE) {
                        close(client_fd);
                        [_connectedClients removeObject:@(client_fd)];
                        if (self.delegtate && [self.delegtate respondsToSelector:@selector(server:didUpdateConnectedClients:)]) {
                            [self.delegtate server:self didUpdateConnectedClients:_connectedClients.copy];
                        }
                    }
                    SERVER1_LOG("sendMsg failed! errno: %s", strerror(errno));
                    break;
                }
                //发送长度不够，说明缓冲区不足
                else {
                    buffer += send_size;
                    needSendLength -= send_size;
                    SERVER1_LOG("Only send length: %d! errno: %s", send_size, strerror(errno));
                }
            }
        }
    }
}

- (BOOL)isRunning {
    return !_isClosed;
}

@end
