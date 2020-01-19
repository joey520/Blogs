//
//  CommonFunctions.hpp
//  TestSocket
//
//  Created by Joey Cao on 2019/12/10.
//  Copyright © 2019 joey cao. All rights reserved.
//

#ifndef CommonFunctions_hpp
#define CommonFunctions_hpp

#define CLIENT_LOG(format, ...) LogTag("[CLIENT] ", format, ##__VA_ARGS__);
#define CLIENT1_LOG(format, ...) LogTag("[CLIENT1] ", format, ##__VA_ARGS__);
#define CLIENT2_LOG(format, ...) LogTag("[CLIENT2] ", format, ##__VA_ARGS__);

#ifdef __cplusplus
extern "C" {
#endif

void LogTag(const char *tag, const char *format, ...);

#ifdef __cplusplus
} // extern "C"
#endif

#import <Foundation/Foundation.h>

extern void ShowResult(NSString *format, ...);
extern void ShowResultAutoDismiss(NSString *format, ...);

#endif /* CommonFunctions_hpp */
