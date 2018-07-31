//
//  ICSwizzler.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICSwizzler.h"
#import "ICIMPBridge.h"
#import <objc/runtime.h>

bool ic_swizzleMethod(Class cls, SEL origSEL) {

	Method origMethod = class_getInstanceMethod(cls, origSEL);
	if (!origMethod) return false;
	
	const char *origin_type = method_getTypeEncoding(origMethod);
	IMP originIMP = method_getImplementation(origMethod);
	
	SEL forwardingSEL = NSSelectorFromString([NSString stringWithFormat:@"__ICMessageTemporary_%@_%@",
																						NSStringFromClass(cls),
																						NSStringFromSelector(origSEL)]);
	
	IMP forwardingIMP = imp_selector_bridge(forwardingSEL);
	
	method_setImplementation(origMethod, forwardingIMP);
	
	SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"__ICMessageFinal_%@_%@",
																					NSStringFromClass(cls),
																					NSStringFromSelector(origSEL)]);
	
	
	return class_addMethod(cls, newSelector, originIMP, origin_type);
}

BOOL ic_isInSkipList(NSString *methodName) {

	static NSArray *defaultBlackList = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		defaultBlackList = @[/*UIViewController*/
												 @".cxx_destruct",
												 @"dealloc",
												 @"_isDeallocating",
												 @"release",
												 @"autorelease",
												 @"retain",
												 @"Retain",
												 @"_tryRetain",
												 @"copy",
												 /*UIView*/
												 @"nsis_descriptionOfVariable:",
												 /*NSObject*/
												 @"respondsToSelector:",
												 @"class",
												 @"methodSignatureForSelector:",
												 @"allowsWeakReference",
												 @"retainWeakReference",
												 @"init",
												 @"forwardInvocation:",
												 @"description",
												 @"debugDescription",
												 @"self",
												 @"beginBackgroundTaskWithExpirationHandler:",
												 @"beginBackgroundTaskWithName:expirationHandler:",
												 @"endBackgroundTask:",
												 @"lockFocus",
												 @"lockFocusIfCanDraw",
												 @"lockFocusIfCanDraw"
												 ];
	});
	
	return ([defaultBlackList containsObject:methodName]);
}

#pragma mark - Public Method
void ic_addSwizzle(Class cls) {
	
#ifndef DEBUG
	return;
#endif
	
	unsigned int method_count = 0;
	Method *methods = class_copyMethodList(cls, &method_count);
	
	for (unsigned int i = 0; i < method_count; i++) {
		Method m = *(methods + i);
		SEL sel = method_getName(m);
		
		if (ic_isInSkipList(NSStringFromSelector(sel))) {
			continue;
		}
		
		bool ret = ic_swizzleMethod(cls, sel);
		if (!ret) {
			assert(false);
		}
	}
	
	free(methods);
	methods = NULL;
}
