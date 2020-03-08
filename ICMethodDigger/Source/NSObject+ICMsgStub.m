//
//  NSObject+ICMsgStub.m
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/30.
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

InterceptModel* checkTargetSubclassMessageForInstance(NSObject *obj, SEL sel) {
	NSArray *clsList = [ICMethodHelper sharedInstance].blockCache.allKeys;
	InterceptModel *ret = [InterceptModel new];
	
	for (NSString *clsName in clsList) {
		Class targetCls = NSClassFromString(clsName);
        // find obj superclass
		if ([obj isKindOfClass:targetCls] && ![obj isMemberOfClass:targetCls]) {
            // 标明父类被 hook 了
			ret.status = true;
			ret.targetClsName = clsName;
			break;
		}
	}
	
	return ret;
}

InterceptModel* checkTargetSubclassMessageForcls(Class cls, SEL sel) {
	NSArray *clsList = [ICMethodHelper sharedInstance].blockCache.allKeys;
	InterceptModel *ret = [InterceptModel new];
	
	for (NSString *clsName in clsList) {
		Class targetCls = NSClassFromString(clsName);
		
		// find obj superclass
		if ([cls isSubclassOfClass:targetCls]) {
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
		method_swizzle(self, @selector(forwardingTargetForSelector:), @selector(ic_instanceForwardingTargetForSelector:));
		method_swizzle(object_getClass([self class]), @selector(forwardingTargetForSelector:), @selector(ic_classForwardingTargetForSelector:));
	});

}

/// Forward all messages to ICMessageStub, and ICMessageStub implements process logic
- (id)ic_instanceForwardingTargetForSelector:(SEL)temporarySEL {
	
	if (![self isKindOfClass:[ICMessageStub class]]) {

        // 如果是中转到桥上的 selector ，则将消息转发给 ICMessageStub
		if (isInterceptMessage(temporarySEL)) {
			return [[ICMessageStub alloc] initWithTarget:self selector:temporarySEL];
		} else {
			
			InterceptModel *ret = checkTargetSubclassMessageForInstance(self, temporarySEL);
			
			if (ret.status) {
                // 如果父类被 hook 了，直接将消息发送给父类。
				SEL newSEL = NSSelectorFromString([NSString stringWithFormat:@"__ICMessageTemporary_%@_%@",
																					 ret.targetClsName,
																					 NSStringFromSelector(temporarySEL)]);
				return [[ICMessageStub alloc] initWithTarget:self selector:newSEL];
			} else {
				return [self ic_instanceForwardingTargetForSelector:temporarySEL];
			}
		}
	} else {
		return [self ic_instanceForwardingTargetForSelector:temporarySEL];
	}
	
}

+ (id)ic_classForwardingTargetForSelector:(SEL)temporarySEL {

	if (![[self class] isSubclassOfClass:[ICMessageStub class]]) {
		
		if (isInterceptMessage(temporarySEL)) {
			return [[ICMessageStub alloc] initWithTarget:self selector:temporarySEL];
		} else {
			
			InterceptModel *ret = checkTargetSubclassMessageForcls([self class], temporarySEL);
			
			if (ret.status) {
				SEL newSEL = NSSelectorFromString([NSString stringWithFormat:@"__ICMessageTemporary_%@_%@",
																					 ret.targetClsName,
																					 NSStringFromSelector(temporarySEL)]);
				return [[ICMessageStub alloc] initWithTarget:[self class] selector:newSEL];
			} else {
				return [self ic_classForwardingTargetForSelector:temporarySEL];
			}
		}
	} else {
		return [self ic_classForwardingTargetForSelector:temporarySEL];
	}
}

@end
