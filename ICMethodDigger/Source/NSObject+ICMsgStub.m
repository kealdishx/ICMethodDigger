//
//  NSObject+ICMsgStub.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "NSObject+ICMsgStub.h"
#import "ICMessageStub.h"
#import "ICMethodHelper.h"
#import <objc/runtime.h>

@interface InterceptModel : NSObject

@property (nonatomic, assign) BOOL status;

@property (nonatomic, copy) NSString *targetClsName;

@end

@implementation InterceptModel

@end

BOOL isInterceptMessage(SEL selector) {
	return [NSStringFromSelector(selector) hasPrefix:@"__ICMessageTemporary"];
}

InterceptModel* checkTargetSubclassMessage(NSObject *obj, SEL sel) {
	NSArray *clsList = [ICMethodHelper sharedInstance].blockCache.allKeys;
	InterceptModel *ret = [InterceptModel new];
	
	for (NSString *clsName in clsList) {
		Class targetCls = NSClassFromString(clsName);
		
    // find obj superclass
		if ([obj isKindOfClass:targetCls] && ![obj isMemberOfClass:targetCls]) {
			ret.status = true;
			ret.targetClsName = clsName;
			break;
		}
	}
	
	return ret;
}

/// Exchange IMP between originSEL and newSEL
void method_swizzle(Class cls, SEL originSEL, SEL newSEL) {

	Method origMethod = class_getInstanceMethod(cls, originSEL);
	Method newMethod = class_getInstanceMethod(cls, newSEL);
	
	if (class_addMethod(cls, originSEL, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
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
	
	if (![self isKindOfClass:[ICMessageStub class]]) {
		if (isInterceptMessage(temporarySEL)) {
			return [[ICMessageStub alloc] initWithTarget:self selector:temporarySEL];
		} else {
			
			InterceptModel *ret = checkTargetSubclassMessage(self, temporarySEL);
			
			if (ret.status) {
				SEL newSEL = NSSelectorFromString([NSString stringWithFormat:@"__ICMessageTemporary_%@_%@",
																					 ret.targetClsName,
																					 NSStringFromSelector(temporarySEL)]);
				return [[ICMessageStub alloc] initWithTarget:self selector:newSEL];
			} else {
				return [self ic_forwardingTargetForSelector:temporarySEL];
			}
		}
	} else {
		return [self ic_forwardingTargetForSelector:temporarySEL];
	}
	
}

@end
