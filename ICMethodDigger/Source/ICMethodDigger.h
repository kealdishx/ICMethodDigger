//
//  ICMethodDigger.h
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^ICConditionBlock)(SEL sel);
typedef void (^ICBeforeBlock)(id target, SEL sel, NSArray *args, int deep);
typedef void (^ICAfterBlock)(id target, SEL sel, NSArray *args, NSTimeInterval interval, int deep, id retValue);

@interface ICMethodDigger : NSObject

/**
 打印对象的方法调用
 
 @param aClass 要打印的类
 @param condition 根据此 block 来决定是否追踪方法（sel 是方法名）
 @param before 方法调用前会调用该 block（target 是检测的对象，sel 是方法名，args 是参数列表，deep 是调用层级）
 @param after 方法调用后会调用该 block（interval 是执行方法的耗时，retValue 是返回值）
 */
+ (void)logMethodWithClass:(Class)aClass
								 condition:(ICConditionBlock) condition
										before:(ICBeforeBlock) before
										 after:(ICAfterBlock) after;

@end

NS_ASSUME_NONNULL_END
