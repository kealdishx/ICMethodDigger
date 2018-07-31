//
//  ICMethodDigger.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICMethodDigger.h"
#import "ICBlock.h"
#import "ICHandler.h"
#import "ICSwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>

/// calling deepth
static int deepth = -1;

#pragma mark - ICMethodDigger private interface

@interface ICMethodDigger()

@property (nonatomic, strong) NSMutableDictionary *blockCache;

+ (instancetype)sharedInstance;

- (void)setICBlock:(ICBlock *)block forKey:(NSString *)aKey;

- (ICBlock *)blockWithTarget:(id)target;

@end


#pragma mark - C function

//forwardInvocation:方法的新IMP
void ic_forwardInvocation(id target, SEL selector, NSInvocation *invocation) {
	NSArray *argList = ic_method_arguments(invocation);
	
	SEL originSelector = invocation.selector;
	
	NSString *originSelectorString = NSStringFromSelector(originSelector);
	
	//友盟的UMAOCTools会产生问题
	if ([originSelectorString rangeOfString:@"hook_"].location != NSNotFound) {
		return;
	}
	
	[invocation setSelector:ic_createNewSelector(originSelector)];
	[invocation setTarget:target];
	
	deepth++;
	
	ICBlock *block = [SHARED_DIGGER blockWithTarget:target];
	[block rundBefore:target sel:originSelector args:argList deep:deepth];
	
	NSDate *start = [NSDate date];
	
	[invocation invoke];
	
	NSDate *end = [NSDate date];
	NSTimeInterval interval = [end timeIntervalSinceDate:start];
	
	[block rundAfter:target sel:originSelector args:argList interval:interval deep:deepth retValue:getReturnValue(invocation)];
	
	deepth--;
}

//替换方法
BOOL ic_replaceMethod(Class cls, SEL originSelector, char *returnType) {
	Method originMethod = class_getInstanceMethod(cls, originSelector);
	if (originMethod == nil) {
		return NO;
	}
	const char *originTypes = method_getTypeEncoding(originMethod);
	IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
	if (ic_isStructType(returnType)) {
		//Reference JSPatch:
		//In some cases that returns struct, we should use the '_stret' API:
		//http://sealiesoftware.com/blog/archive/2008/10/30/objc_explain_objc_msgSend_stret.html
		//NSMethodSignature knows the detail but has no API to return, we can only get the info from debugDescription.
		NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:originTypes];
		if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
			msgForwardIMP = (IMP)_objc_msgForward_stret;
		}
	}
#endif
	
	IMP originIMP = method_getImplementation(originMethod);
	
	if (originIMP == nil || originIMP == msgForwardIMP) {
		return NO;
	}
	
	//把原方法的IMP换成_objc_msgForward，使之触发forwardInvocation方法
	class_replaceMethod(cls, originSelector, msgForwardIMP, originTypes);
	
	//把方法forwardInvocation的IMP换成ic_forwardInvocation
	class_replaceMethod(cls, @selector(forwardInvocation:), (IMP)ic_forwardInvocation, "v@:@");
	
	//创建一个新方法，IMP就是原方法的原来的IMP，那么只要在ic_forwardInvocation调用新方法即可
	SEL newSelecotr = ic_createNewSelector(originSelector);
	BOOL isAdd = class_addMethod(cls, newSelecotr, originIMP, originTypes);
	if (!isAdd) {
		DEV_LOG(@"class_addMethod fail");
	}
	
	return YES;
}

void ic_logMethod(Class aClass, BOOL(^condition)(SEL sel)) {
	unsigned int outCount;
	Method *methods = class_copyMethodList(aClass,&outCount);
	
	for (int i = 0; i < outCount; i ++) {
		Method tempMethod = *(methods + i);
		SEL selector = method_getName(tempMethod);
		char *returnType = method_copyReturnType(tempMethod);
		
		BOOL isCan = ic_isCanHook(tempMethod, returnType);
		
		if (isCan && condition) {
			isCan = condition(selector);
		}
		
		if (isCan) {
			if (ic_replaceMethod(aClass, selector, returnType)) {
				DEV_LOG(@"success hook method:%@ types:%s", NSStringFromSelector(selector), method_getDescription(tempMethod)->types);
			} else {
				DEV_LOG(@"fail method:%@ types:%s", NSStringFromSelector(selector), method_getDescription(tempMethod)->types);
			}
		} else {
			DEV_LOG(@"can not hook method:%@ types:%s", NSStringFromSelector(selector), method_getDescription(tempMethod)->types);
		}
		free(returnType);
	}
	free(methods);
}


#pragma mark - ICMethodDigger implementation

@implementation ICMethodDigger

+ (void)logMethodWithClass:(Class)aClass
								 condition:(ICConditionBlock) condition
										before:(ICBeforeBlock) before
										 after:(ICAfterBlock) after {
#ifndef DEBUG
	return;
#endif
	
	if (aClass) {

		ICBlock *block = [[ICBlock alloc] init];
		block.targetClassName = NSStringFromClass(aClass);
		block.condition = condition;
		block.before = before;
		block.after = after;
		[SHARED_DIGGER setICBlock:block forKey:block.targetClassName];
	}
	
	ic_logMethod(aClass, condition);
	
	/// Get meta class and handle class methods
	Class metaClass = object_getClass(aClass);
	ic_logMethod(metaClass, condition);
}

+ (instancetype)sharedInstance {

	static ICMethodDigger *_sharedICMethodDigger = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedICMethodDigger = [[self alloc] init];
		_sharedICMethodDigger.blockCache = [NSMutableDictionary dictionary];
	});
	
	return _sharedICMethodDigger;
}

- (void)setICBlock:(ICBlock *)block forKey:(NSString *)aKey {
	@synchronized (self) {
		[self.blockCache setObject:block forKey:aKey];
	}
}

- (ICBlock *)blockWithTarget:(id)target {

	Class class = [target class];
	ICBlock *block = [self.blockCache objectForKey:NSStringFromClass(class)];

	while (block == nil) {
		
		class = [class superclass];
		if (class == nil) {
			break;
		}
		block = [self.blockCache objectForKey:NSStringFromClass(class)];
		
	}

	return block;
}

@end

