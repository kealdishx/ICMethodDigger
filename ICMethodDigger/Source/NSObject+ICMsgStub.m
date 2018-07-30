//
//  NSObject+ICMsgStub.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "NSObject+ICMsgStub.h"
#import "ICMessageStub.h"
#import <objc/runtime.h>

bool should_intercept_message(Class cls, SEL sel) {
	return [NSStringFromSelector(sel) hasPrefix:@"__WZQMessageTemporary"];
}

void method_swizzle(Class cls, SEL origSEL, SEL newSEL) {

	Method origMethod = class_getInstanceMethod(cls, origSEL);
	Method newMethod = class_getInstanceMethod(cls, newSEL);
	
	if (class_addMethod(cls, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
		class_replaceMethod(cls, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	} else {
		method_exchangeImplementations(origMethod, newMethod);
	}
	
}

@implementation NSObject (ICMsgStub)

+ (void)load {

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		method_swizzle(self, @selector(forwardingTargetForSelector:), @selector(ic_forwardingTargetForSelector:));
	});

}

/// Forward all messages to ICMessageStub, and ICMessageStub implements process logic
- (id)ic_forwardingTargetForSelector:(SEL)temporarySEL {

	if (should_intercept_message(object_getClass(self), temporarySEL) && ![self isKindOfClass:[ICMessageStub class]]) {
		return [[ICMessageStub alloc] initWithTarget:self selector:temporarySEL];
	}
	
	return [self ic_forwardingTargetForSelector:temporarySEL];
}

@end
