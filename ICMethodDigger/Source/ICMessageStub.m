//
//  ICMessageStub.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICMessageStub.h"
#import "ICBlock.h"
#import "ICMethodHelper.h"
#import "ICHandler.h"
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
	
	NSArray *args = ic_method_arguments(anInvocation);
	
	NSString *originSELString = NSStringFromSelector(self.selector);
	
	/// UMAOCTools will cause unexpected result.
	if ([originSELString rangeOfString:@"hook_"].location != NSNotFound) {
		return;
	}
	
	anInvocation.target = self.target;
	anInvocation.selector = self.selector;
	
	NSString *originSELstr = [NSStringFromSelector(self.selector) stringByReplacingOccurrencesOfString:@"__ICMessageFinal_" withString:@""];
	SEL originSEL = NSSelectorFromString(originSELstr);
	
	ICBlock *block = [[ICMethodHelper sharedInstance] blockWithTarget:self.target];
	[block rundBefore:self.target sel:originSEL args:args];
	
	NSTimeInterval start = CFAbsoluteTimeGetCurrent();
	
	[anInvocation invoke];
	
	NSTimeInterval interval = CFAbsoluteTimeGetCurrent() - start;
	
	[block rundAfter:self.target sel:originSEL args:args interval:interval retValue:getReturnValue(anInvocation)];
	
}

@end
