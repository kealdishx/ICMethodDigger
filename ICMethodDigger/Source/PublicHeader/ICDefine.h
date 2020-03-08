//
//  ICDefine.h
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/31.
//  Copyright © 2018年 kealdish. All rights reserved.
//

#ifndef ICDefine_h
#define ICDefine_h

typedef BOOL (^ICConditionBlock)(SEL selector);
typedef void (^ICBeforeBlock)(id target, SEL sel, NSArray *args);
typedef void (^ICAfterBlock)(id target, SEL sel, NSArray *args, NSTimeInterval interval, id retValue);

#endif /* ICDefine_h */
