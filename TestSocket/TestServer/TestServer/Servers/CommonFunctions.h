//
//  CommonFunctions.hpp
//  TestSocket
//
//  Created by Joey Cao on 2019/12/10.
//  Copyright © 2019 joey cao. All rights reserved.
//

#ifndef CommonFunctions_hpp
#define CommonFunctions_hpp
#import <Foundation/Foundation.h>

#define SERVER_LOG(format, ...) LogTag("[SERVER] ", format, ##__VA_ARGS__);
#define SERVER1_LOG(format, ...) LogTag("[SERVER1] ", format, ##__VA_ARGS__);
#define SERVER2_LOG(format, ...) LogTag("[SERVER2] ", format, ##__VA_ARGS__);

#ifdef __cplusplus
extern "C" {
#endif

extern void LogTag(const char *tag, const char *format, ...);
extern void ShowResult(NSString *format, ...);
extern void ShowResultAutoDismiss(NSString *format, ...);

#ifdef __cplusplus
} // extern "C"
#endif



#endif /* CommonFunctions_hpp */
