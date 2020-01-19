#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>

int main(int argc, char **argv) {
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
    sigprocmask( SIG_UNBLOCK, &new_set, &old_set );
    if (sigismember(&pending_set, SIGINT)) {
        printf("SIGINT was came.\n");
    }
    if (sigismember(&pending_set, SIGQUIT)) {
        printf("SIGQUIT was came.\n");
    }
    if (sigismember(&pending_set, SIGABRT)) {
        printf("SIGABRT was came.\n");
    }
    printf("code run here\n");
}
