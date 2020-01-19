//
//  CommonFunctions.cpp
//  TestSocket
//
//  Created by Joey Cao on 2019/12/10.
//  Copyright © 2019 joey cao. All rights reserved.
//

#include "CommonFunctions.h"
#include <stdio.h>
#include <stdarg.h>
#import <UIKit/UIKit.h>
#include "time.h"

static int LOG_MAX_BUFFER = 1024;
static char *buffer;
#define AUTO_DISMISS_TIMEOUT (1)

static inline char *Getdate(void) {
    char *date_str = (char *)malloc(31);
    time_t timer = time(NULL);
    strftime(date_str, 20, "%Y-%m-%d %H:%M:%S", localtime(&timer));
    return date_str;
}

void LogTag(const char *tag, const char *format, ...) {
    if (buffer == NULL) {
        buffer = (char *)malloc(LOG_MAX_BUFFER);
    }
    memset(buffer, 0, LOG_MAX_BUFFER);
    va_list vg;
    va_list temp_vg;
    va_copy(temp_vg, vg);
    va_start(temp_vg, format);
    int size = vsnprintf(buffer, LOG_MAX_BUFFER, format, temp_vg);
    va_end(temp_vg);
    //如果长度超了，重新拷贝
    if (size > LOG_MAX_BUFFER) {
        //重置temp_vg;
        va_copy(temp_vg, vg);
        va_start(temp_vg, format);
        buffer = (char *)realloc(buffer, size);
        LOG_MAX_BUFFER = size;
        vsnprintf(buffer, LOG_MAX_BUFFER, format, temp_vg);
        va_end(temp_vg);
    }
    va_end(vg);
    char *date = Getdate();
    printf("%s %s %s\n", date, tag, buffer);
    free(date);
}

//MARK: - Toast
void ShowResultWithAutoDissmiss(BOOL autoDismiss, NSString *message);

UIViewController *_topViewController(UIViewController *vc) {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return _topViewController([(UINavigationController *)vc topViewController]);
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return _topViewController([(UITabBarController *)vc selectedViewController]);
    } else {
        return vc;
    }
    return nil;
}

UIViewController *topViewController() {
    UIViewController *resultVC;
    resultVC = _topViewController([[UIApplication sharedApplication].keyWindow rootViewController]);
    while (resultVC.presentedViewController) {
        resultVC = _topViewController(resultVC.presentedViewController);
    }
    return resultVC;
}


void ShowResult(NSString *format, ...) {
    va_list argumentList;
    va_start(argumentList, format);

    NSString *message = [[NSString alloc] initWithFormat:format arguments:argumentList];
    va_end(argumentList);
    ShowResultWithAutoDissmiss(false, message);
}

void ShowResultAutoDismiss(NSString *format, ...) {
    va_list argumentList;
    va_start(argumentList, format);

    NSString *message = [[NSString alloc] initWithFormat:format arguments:argumentList];
    va_end(argumentList);
    ShowResultWithAutoDissmiss(true, message);
}

void ShowResultWithAutoDissmiss(BOOL autoDismiss, NSString *message) {

    NSString *newMessage = [message hasSuffix:@":(null)"] ? [message stringByReplacingOccurrencesOfString:@":(null)" withString:@" successful!"] : message;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertViewController = [UIAlertController alertControllerWithTitle:nil message:newMessage preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertViewController addAction:okAction];
        __block UIViewController *topController = topViewController();

        void (^presentNewAlert)(void) = ^{
            [topController presentViewController:alertViewController animated:NO completion:nil];

            if (autoDismiss) {
                __weak typeof(alertViewController) weakAlert = alertViewController;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, AUTO_DISMISS_TIMEOUT * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    __strong typeof(weakAlert) strongAlert = weakAlert;
                    if (!strongAlert) {
                        return;
                    }

                    [strongAlert dismissViewControllerAnimated:NO completion:nil];

                });
            }
        };

        if ([topController isKindOfClass:[UIAlertController class]]) {
            [topController dismissViewControllerAnimated:NO
                                              completion:^{
                                                  topController = topViewController();
                                                  presentNewAlert();
                                              }];
        } else {
            presentNewAlert();
        }

    });
}
