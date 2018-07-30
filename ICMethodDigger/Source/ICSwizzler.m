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
//#import <dlfcn.h>

bool ic_swizzleMethod(Class cls, SEL origSEL) {

	Method origMethod = class_getInstanceMethod(cls, origSEL);
	if (!origMethod) return false;
	
	const char *origin_type = method_getTypeEncoding(origMethod);
	IMP originIMP = method_getImplementation(origMethod);
	
//	Dl_info info;
//	dladdr(originIMP, &info);
//
//	NSString *binaryName = [NSString stringWithUTF8String:info.dli_fname];
//	if (![binaryName hasSuffix:@"UIKit"]) return NO;
	
	SEL forwardingSEL = NSSelectorFromString([NSString stringWithFormat:@"__WZQMessageTemporary_%@_%@",
																						NSStringFromClass(cls),
																						NSStringFromSelector(origSEL)]);
	
	IMP forwardingIMP = imp_selector_bridge(forwardingSEL);
	
	method_setImplementation(origMethod, forwardingIMP);
	
	SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"__WZQMessageFinal_%@_%@",
																					NSStringFromClass(cls),
																					NSStringFromSelector(origSEL)]);
	
	
	return class_addMethod(cls, newSelector, originIMP, origin_type);
}

void ic_addSwizzle(Class cls) {
	
	#ifndef DEBUG
		return;
	#endif
	
	unsigned int method_count = 0;
	Method *methods = class_copyMethodList(cls, &method_count);
	
	for (unsigned int i = 0; i < method_count; i++) {
		Method m = *(methods + i);
		SEL sel = method_getName(m);
		
//		if (should_skip_swizzle_this_method(NSStringFromSelector(sel))) {
//			continue;
//		}
		
		bool ret = ic_swizzleMethod(cls, sel);
		if (!ret) {
			assert(false);
		}
	}
	
	free(methods);
	methods = NULL;
}
