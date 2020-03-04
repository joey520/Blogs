//
//  ViewController.m
//  TestSignal
//
//  Created by Joey Cao on 2020/1/15.
//  Copyright © 2020 joey cao. All rights reserved.
//

#import "ViewController.h"

#define func(a) (a = 10, 2)
//定义一个sigaction处理函数模板
typedef void(*SigactionHandler)(int signo, struct __siginfo *siginfo, void *context);
//利用静态变量保存已有的处理函数指针
static SigactionHandler preActionHandler;

//兼容signal
typedef void(*SignalHandler)(int signo);
static SignalHandler preSignalHandler;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    int a = 5;
    int b = func(a);
    
    [self testSigsuspend];
}

- (void)testSystemCall {
    signal(SIGALRM, signalHandler);
    write(STDOUT_FILENO, "joey", 4);
    
    raise(SIGALRM);    
}

static void signalHandler(int signalv) {
    NSLog(@"This is signal handler--%d", signalv);
    NSLog(@"thread: %@", [NSThread currentThread]);
}

- (void)testSignalHandler {
    signal(SIGALRM, signalHandler);
    signal(SIGUSR1, signalHandler);

    kill(getpid(), SIGALRM);
    kill(getpid(), SIGUSR1);
}

- (void)testSigprocmask {
    signal(SIGALRM, signalHandler);
    signal(SIGABRT, signalHandler);
    
    //获取old_set;
    
    //添加新的屏蔽字
    sigset_t old_set, new_set;
    sigemptyset(&new_set);
    //屏蔽alram，测试是否还能收到
    sigaddset(&new_set, SIGALRM);
    sigprocmask(SIG_UNBLOCK, &new_set, NULL);

    NSLog(@"before old set");
    sigemptyset(&old_set);
    int ret = sigprocmask(0, NULL, &old_set);
    if (ret != 0) {
        perror("fetch old_set failed");
    } else {
        printf("old_set: %8.8d\n", old_set);
        if (sigismember(&old_set, SIGALRM)) {
            NSLog(@"old_set contains SIGALRM");
        }
    }
    NSLog(@"after old set");

}

- (void)testSigpending {
    sigset_t new_set, old_set, pending_set;
    sigemptyset(&new_set);
    sigemptyset(&old_set);
    sigemptyset(&pending_set);
    //屏蔽这3个信号
    sigaddset(&new_set, SIGINT);
    sigaddset(&new_set, SIGQUIT);
    sigaddset(&new_set, SIGABRT);
    //阻塞new_set信号集
    sigprocmask(SIG_BLOCK, &new_set, &old_set);
    printf("new set is %8.8d, old set is:%8.8d\n", new_set, old_set);
    sigpending(&pending_set);
    printf("Pending set is %8.8d.\n", pending_set);
    kill(getpid(), SIGINT);
    sigpending(&pending_set);
    printf("Pending set is %8.8d.\n", pending_set);
    kill(getpid(), SIGQUIT);
    sigpending(&pending_set);
    printf("Pending set is %8.8d.\n", pending_set);
    kill(getpid(), SIGABRT);
    sigpending(&pending_set);
    printf("Pending set is %8.8d.\n", pending_set);
    //阻塞
//    sigprocmask( SIG_UNBLOCK, &new_set, &old_set );
    if (sigismember(&pending_set, SIGINT)) {
        printf("SIGINT was came.\n");
    }
    if (sigismember(&pending_set, SIGQUIT)) {
        printf("SIGQUIT was came.\n");
    }
    if (sigismember(&pending_set, SIGABRT)) {
        printf("SIGABRT was came.\n");
    }
    NSLog(@"code run here");
}

static void actionHandler(int signo, struct __siginfo *siginfo, void *context) {
    printf("this is new action handler\n");

//    printf("signo: %d\n", signo);
//    printf("si_signo: %d\n", siginfo->si_signo);
//    printf("si_errno: %d\n", siginfo->si_errno);
//    printf("si_code: %d\n", siginfo->si_code);
//    printf("si_pid: %d\n", siginfo->si_pid);
//    printf("si_uid: %d\n", siginfo->si_uid);
//    printf("si_status: %d\n", siginfo->si_status);
//    //如果是SIGSEGV即返回出现错误的根源地址
//    if (signo == SIGSEGV) {
//        printf("si_addr: %s\n", (char *)siginfo->si_addr);
//    }
//    printf("si_value: %d\n", siginfo->si_value.sival_int);
//    //如果是
//    if (signo == SIGPROF) {
//
//    }
//    printf("si_band: %ld\n", siginfo->si_band);
    
    if (preActionHandler) {
        printf("Pre handler exists\n");
        preActionHandler(signo, siginfo, context);
    }
    
    if (preSignalHandler) {
        preSignalHandler(signo);
    }
}

static void oldActionHandler(int signo, struct __siginfo *siginfo, void *context) {
    printf("this is old action handler\n");
}

- (void)testSigaction {
    
    //先测试其它地方用signal注册一个handler
    signal(SIGALRM, signalHandler);
    //再模拟其它地方用sigaction注册了一个handler
//    struct sigaction monitorAction;
//    bzero(&monitorAction, sizeof(sigaction));
//    //不阻塞
//    sigemptyset(&monitorAction.sa_mask);
//    //这里为了区分，换另个函数指针
//    monitorAction.sa_sigaction = oldActionHandler;
//    //这种flag，已经有了actionHnaler, 非阻塞
//    monitorAction.sa_flags = SA_SIGINFO | SA_NODEFER;
//    sigaction(SIGALRM, &monitorAction, NULL);
    
    struct sigaction old_action;
    //获取旧的action
    int ret = sigaction(SIGALRM, NULL, &old_action);
    if (ret < 0) {
        perror("sigaction failed");
    }
    printf("old_action sa_mask: %8.8d\n", old_action.sa_mask);
    printf("old_action sa_flags: %8.8d\n", old_action.sa_flags);
    //__sigaction_u是一个union，其实直接取__sa_sigaction即可
    //这个flag可以可以用于判断sa_flags信号，已经一些别的信息，例如是否old_sigaction已经有handler了
    if (old_action.sa_flags & SA_SIGINFO) {
        //这个宏可以简化书写其实就是去了handler指针.
        //把已有的处理函数指针保存下来
        preActionHandler = old_action.sa_sigaction;
    }
    if (old_action.sa_handler) {
        preSignalHandler = old_action.sa_handler;
    }
    
    //注册新的handler
    //清空屏蔽字
    struct sigaction new_action;
    bzero(&new_action, sizeof(sigaction));
    sigemptyset(&new_action.sa_mask);
    new_action.sa_sigaction = actionHandler;
    new_action.sa_flags  = SA_NODEFER | SA_SIGINFO | SIGALRM;

    //注册新的action
    ret = sigaction(SIGALRM, &new_action, NULL);
    if (ret < 0) {
        perror("sigaction new failed");
    }
    //发送信号
    alarm(1);
}

sigjmp_buf jmp;
- (void)testSigsetjmp {
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGALRM);
    int a = 20;
    int ret = sigsetjmp(jmp, 0);
    printf("ret: %d\n", ret);
    if (ret < 0) {
        printf("sig set jmp failed: %s", strerror(errno));
    } else if(ret > 0) {
        printf("after jmp: a: %d\n", a);
        return;
    }

    printf("before jmp: a: %d\n", a);
    [self changeNum:a];
}

- (void)changeNum:(int)num {
    num = 30;
    NSLog(@"jmp\n");
    siglongjmp(jmp, 2);
}

- (void)testSigsuspend {
    signal(SIGALRM, signalHandler);
    sigset_t set;
    sigemptyset(&set);
    sigaddset(&set, SIGALRM);
    [NSThread detachNewThreadWithBlock:^{
        printf("an other thread signal \n");
        alarm(1);
    }];
    printf("start suspend, will \n");
    printf("pause returned: %d\n, errno: %d\n", pause(), errno);
//    int ret = sigsuspend(&set);
//    if (ret < 0) {
//        printf("sigsuspend failed: %s\n", strerror(errno));
//    }
    
    printf("run here 1\n");
    
    alarm(1);
    
    printf("after signal\n");
}

@end
