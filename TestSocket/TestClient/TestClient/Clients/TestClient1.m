//
//  TestClient1.m
//  TestSocket
//
//  Created by Joey Cao on 2019/12/8.
//  Copyright © 2019 joey cao. All rights reserved.
//

#import "TestClient1.h"
#include <stdio.h>
#include <unistd.h>
#include <strings.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <sys/filio.h>
#include <sys/select.h>
#include <sys/time.h>
#include <pthread.h>

#define INVALID_SOCKET (-1)
#define MAX_BUFFER_SIZE (1024)
#define RECONNECT_TIME (3)

@interface TestClient1 () {
    NSString *_host;
    int _port;
    int _server_socket_fd;
    struct sockaddr_in _serverAddress;
    BOOL _isServiceRunning;//是否在运行

    NSThread *_workQueue;
    //为了提高效率避免重复开辟空间
    uint8_t *_read_buffer;

    //buffer
    uint8_t *_send_buffer;
    int _send_buffer_length;
}

@end

@implementation TestClient1

- (void)dealloc {
    CLIENT1_LOG("%s", __func__);
    free(_send_buffer);
    free(_read_buffer);
    _send_buffer = NULL;
    _send_buffer_length = 0;
}

- (instancetype)initWithHost:(NSString *)host port:(int)port {
    self = [super init];
    if (self) {
        _host = host;
        _port = port;
        _server_socket_fd = INVALID_SOCKET;
        _send_buffer = malloc(MAX_BUFFER_SIZE);
        _read_buffer = malloc(MAX_BUFFER_SIZE);
    }
    return self;
}

- (void)start {
    if (_isServiceRunning) {
        CLIENT1_LOG("Socket is already started");
        return;
    }
    _isServiceRunning = true;
    _workQueue = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [_workQueue setName:@"Client1 work queue"];
    [_workQueue start];
}

- (void)run {
    //如果此时socket已经连接上
    if (self->_server_socket_fd != INVALID_SOCKET) {
        [self runReceiveData];
        return;
    }

    int tmpSocket = socket(AF_INET, SOCK_STREAM, 0);
    struct linger l;
    l.l_linger = 0;
    l.l_onoff = 1;
    int intval = 1;
    //设置Time_WAIT
    setsockopt(tmpSocket, SOL_SOCKET, SO_LINGER, &l, sizeof(struct linger));
    //设置可以重用socket addr
    setsockopt(tmpSocket, SOL_SOCKET, SO_REUSEADDR, &intval, sizeof(int));
    //取消Nagle算法
    setsockopt(tmpSocket, IPPROTO_TCP, TCP_NODELAY, &intval, sizeof(int));
    //进制抛出SIGPIPE信号
    setsockopt(tmpSocket, SOL_SOCKET, SO_NOSIGPIPE, &intval, sizeof(int));

    long arg;
    //获取文件描述符参数
    if ((arg = fcntl(tmpSocket, F_GETFL, NULL)) < 0) {
        CLIENT1_LOG("Error fcntl(..., F_GETFL) (%s)\n", strerror(errno));
        close(tmpSocket);
        CLIENT1_LOG("connect failed: 106, errno: %s", strerror(errno));
        return;
    }
    //设置为非阻塞模式
    arg |= O_NONBLOCK;
    //如果要阻塞
    //arg &= ~O_NONBLOCK
    if (fcntl(tmpSocket, F_SETFL, arg) < 0) {
        CLIENT1_LOG("Error fcntl(..., F_SETFL) (%s)\n", strerror(errno));
        CLIENT1_LOG("connect failed: 107, errno: %s", strerror(errno));
        close(tmpSocket);
        return;
    }
    //如果地址不合法
    if (![self handleHost]) {
        close(tmpSocket);
        CLIENT1_LOG("connect failed: 108, errno: %s", strerror(errno));
        return;
    }

    //connect如果连接失败
    int ret = connect(tmpSocket, (const struct sockaddr *)&_serverAddress, sizeof(struct sockaddr));
    if (ret < 0) {
        //如果失败并且不是EINPROGRESS错误，表示服务端不可用，停掉socket
        //在TCP连接中3次握手需要一些时间去完成，而非阻塞模式下可能等不了，而产生EINPROGRESS错误
        //此时采用select来连短暂等待检测文件描述符的读写状况
        if (errno != EINPROGRESS) {
            CLIENT1_LOG("Connect failed");
            close(tmpSocket);
            return;
        }

        do {
            //通过select来尝试检测文件描述符
            struct timeval tv;//= {0, 1};
            tv.tv_sec = 0;
            tv.tv_usec = 0.1 * USEC_PER_SEC;

            //初始化write set
            fd_set writeSet;
            FD_ZERO(&writeSet);
            //注册socket
            FD_SET(tmpSocket, &writeSet);

            //检测文件是否可写。 注意文件描述符范围一般为socket_fd + 1。
            ret = select(tmpSocket + 1, NULL, &writeSet, NULL, &tv);
            //如果当前文件描述符可读, 跳出循环检测
            if (ret > 0 && FD_ISSET(tmpSocket, &writeSet)) {
                CLIENT1_LOG("Connect Success");
                break;
            }
        } while (_isServiceRunning);
    }


    //虽然连上了，但是用户把service停了
    if (!_isServiceRunning) {
        [self closeServer];
        return;
    }

    _server_socket_fd = tmpSocket;

    //终于连接成功了。。。
    if (self.delegate && [self.delegate respondsToSelector:@selector(service:didReceiveEvent:)]) {
        [self.delegate service:self didReceiveEvent:TestClientEventConnectSuccess];
    }

    //开始接收数据
    [self runReceiveData];
}

- (void)runReceiveData {
    while (_isServiceRunning && _server_socket_fd != INVALID_SOCKET) {
        //采用自动释放池避免内存达到峰值
        @autoreleasepool {
            struct timeval tm;
            tm.tv_sec = 2;
            tm.tv_usec = 0;
            //检测文件描述符是否可读，
            fd_set read_set;
            FD_ZERO(&read_set);
            //注册fd_set
            FD_SET(_server_socket_fd, &read_set);

            fd_set error_set;
            FD_ZERO(&error_set);
            FD_SET(_server_socket_fd, &error_set);
            int result = select(_server_socket_fd + 1, &read_set, NULL, &error_set, &tm);
            //文件描述符有变化
            if (result > 0) {
                //如果有错误
                if (FD_ISSET(_server_socket_fd, &error_set)) {
                    //停止连接
                    [self closeServer];
                    CLIENT1_LOG("close server for error_set: errno: %s", strerror(errno));
                    return;
                }
                //如果文件描述符可读
                if (FD_ISSET(_server_socket_fd, &read_set)) {
                    memset(_read_buffer, 0, MAX_BUFFER_SIZE);
                    int recv_size = (int)recv(_server_socket_fd, _read_buffer, MAX_BUFFER_SIZE, 0);
                    CLIENT1_LOG("recv data: %s, length: %d", _read_buffer, recv_size);
                    if (recv_size > 0) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(service:didReadBuffer:length:)]) {
                            [self.delegate service:self didReadBuffer:_read_buffer length:recv_size];
                        }
                    }
                    //服务端断开
                    else if (recv_size == 0) {
                        [self closeServer];
                        CLIENT1_LOG("server had disconnected,errno: %s", strerror(errno));
                    } else {
                        CLIENT1_LOG("receive invalid data,errno: %s", strerror(errno));
                        break;
                    }
                }
            }
        }
    }
}

- (BOOL)handleHost {
    struct addrinfo hints;
    memset(&hints, 0, sizeof(struct addrinfo));

    hints.ai_flags = AI_PASSIVE;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;

    struct addrinfo *local = NULL;
    NSString *serverPort = [NSString stringWithFormat:@"%d", _port];

    if (0 != getaddrinfo([_host UTF8String], [serverPort UTF8String], &hints, &local)) {
        if (local) {
            freeaddrinfo(local);
        }
        return NO;
    }

    if (local->ai_addrlen != sizeof(struct sockaddr_in)) {
        if (local) {
            freeaddrinfo(local);
        }
        return NO;
    }

    _serverAddress = *(struct sockaddr_in *)local->ai_addr;

    if (local) {
        freeaddrinfo(local);
    }

    return YES;
}

- (void)closeServer {
    _isServiceRunning = false;
    close(_server_socket_fd);
    _server_socket_fd = INVALID_SOCKET;
}

- (void)sendMsg:(NSString *)msg {
    if (!_isServiceRunning) {
        return;
    }
    size_t length = msg.length;
    void *buffer = (void *)[msg cStringUsingEncoding:NSUTF8StringEncoding];
    send(_server_socket_fd, buffer, length, 0);
}


@end
