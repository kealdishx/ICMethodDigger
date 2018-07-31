//
//  ICMessageStub.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICMessageStub.h"
#import <objc/runtime.h>

@implementation ICMessageStub

- (instancetype)initWithTarget:(id)target selector:(SEL)temporarySEL {

	if (self = [super init]) {

		_target = target;
		
		NSString *finalSELStr = [NSStringFromSelector(temporarySEL) stringByReplacingOccurrencesOfString:@"__ICMessageTemporary_" withString:@"__ICMessageFinal_"];
		_selector = NSSelectorFromString(finalSELStr);
	}
	return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
	
	Method m = class_getInstanceMethod(object_getClass(self.target), self.selector);
	assert(m);
	return [NSMethodSignature signatureWithObjCTypes:method_getTypeEncoding(m)];
	
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
	
	anInvocation.target = self.target;
	anInvocation.selector = self.selector;
	
	if (![NSThread isMainThread]) {
		NSLog(@"===============[libMainThreadChecker.dylib]::%@ should be called within main thread only================\n", NSStringFromSelector(self.selector));
	}
	
	[anInvocation invoke];
}

@end
