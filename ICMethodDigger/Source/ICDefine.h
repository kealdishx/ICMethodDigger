//
//  ICDefine.h
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#ifndef ICDefine_h
#define ICDefine_h

typedef BOOL (^ICConditionBlock)(SEL selector);
typedef void (^ICBeforeBlock)(id target, SEL sel, NSArray *args, int deep);
typedef void (^ICAfterBlock)(id target, SEL sel, NSArray *args, NSTimeInterval interval, int deep, id retValue);

#endif /* ICDefine_h */
