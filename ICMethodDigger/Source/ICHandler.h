//
//  ICHandler.h
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

FOUNDATION_EXTERN NSDictionary *ic_canHandleTypeDic(void);

FOUNDATION_EXTERN BOOL ic_isCanHandle(NSString *typeEncode);

FOUNDATION_EXTERN SEL ic_createNewSelector(SEL originalSelector);

FOUNDATION_EXTERN BOOL ic_isStructType(const char *argumentType);

FOUNDATION_EXTERN NSString *ic_structName(const char *argumentType);

FOUNDATION_EXTERN BOOL isCGRect           (const char *type);

FOUNDATION_EXTERN BOOL isCGPoint          (const char *type);

FOUNDATION_EXTERN BOOL isCGSize           (const char *type);

FOUNDATION_EXTERN BOOL isCGVector         (const char *type);

FOUNDATION_EXTERN BOOL isUIOffset         (const char *type);

FOUNDATION_EXTERN BOOL isUIEdgeInsets     (const char *type);

FOUNDATION_EXTERN BOOL isCGAffineTransform(const char *type);

// Decide whether mthod can be hooked or not
FOUNDATION_EXTERN BOOL ic_isCanHook(Method method, const char *returnType);

// Get return value at forwarding action
FOUNDATION_EXTERN id getReturnValue(NSInvocation *invocation);

// Get method arugments at forwarding action
FOUNDATION_EXTERN NSArray *ic_method_arguments(NSInvocation *invocation);

