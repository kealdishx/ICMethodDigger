//
//  ICDefine.h
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#ifndef ICDefine_h
#define ICDefine_h

#define SHARED_DIGGER [ICMethodDigger sharedInstance]

//#define OPEN_TARGET_LOG

#ifdef OPEN_TARGET_LOG
#define TARGET_LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define TARGET_LOG(format, ...)
#endif

//#define OPEN_DEV_LOG

#ifdef OPEN_DEV_LOG
#define DEV_LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DEV_LOG(format, ...)
#endif

typedef BOOL (^ICConditionBlock)(SEL sel);
typedef void (^ICBeforeBlock)(id target, SEL sel, NSArray *args, int deep);
typedef void (^ICAfterBlock)(id target, SEL sel, NSArray *args, NSTimeInterval interval, int deep, id retValue);

#endif /* ICDefine_h */
