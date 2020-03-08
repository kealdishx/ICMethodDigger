//
//  ICHandler.h
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

NSDictionary *ic_canHandleTypeDic(void);

BOOL ic_isCanHandle(NSString *typeEncode);

BOOL ic_isStructType(const char *argumentType);

NSString *ic_structName(const char *argumentType);

BOOL isCGRect           (const char *type);

BOOL isCGPoint          (const char *type);

BOOL isCGSize           (const char *type);

BOOL isCGVector         (const char *type);

BOOL isUIOffset         (const char *type);

BOOL isUIEdgeInsets     (const char *type);

BOOL isCGAffineTransform(const char *type);

// Decide whether mthod can be hooked or not
BOOL ic_isCanHook(Method method, const char *returnType);

// Get return value at forwarding action
id getReturnValue(NSInvocation *invocation);

// Get method arugments at forwarding action
NSArray *ic_method_arguments(NSInvocation *invocation);

BOOL triggerForwardInvocation(Class cls, SEL originSEL, char *returnType);

BOOL ic_isInSkipList(NSString *methodName);

/// Subclass should swizzle method in order to constant circulation between IMP
/// of superclass and that of subclass
BOOL ic_swizzleMethod(Class cls, SEL origSEL);

void ic_logMethod(Class cls, BOOL(^condition)(SEL sel));
