//
//  ICHandler.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import "ICHandler.h"
#import "ICDefine.h"
#import "ICIMPBridge.h"
#import <objc/message.h>
#import <UIKit/UIKit.h>

/// Use to debug
#define OPEN_DEV_LOG

#ifdef OPEN_DEV_LOG
#define DEV_LOG(format, ...) NSLog(format, ## __VA_ARGS__)
#else
#define DEV_LOG(format, ...)
#endif

// reference: https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
NSDictionary *ic_canHandleTypeDic() {
	
	static NSDictionary *dic = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		dic = @{[NSString stringWithUTF8String:@encode(char)] : @"(char)",
						[NSString stringWithUTF8String:@encode(int)] : @"(int)",
						[NSString stringWithUTF8String:@encode(short)] : @"(short)",
						[NSString stringWithUTF8String:@encode(long)] : @"(long)",
						[NSString stringWithUTF8String:@encode(long long)] : @"(long long)",
						[NSString stringWithUTF8String:@encode(unsigned char)] : @"(unsigned char))",
						[NSString stringWithUTF8String:@encode(unsigned int)] : @"(unsigned int)",
						[NSString stringWithUTF8String:@encode(unsigned short)] : @"(unsigned short)",
						[NSString stringWithUTF8String:@encode(unsigned long)] : @"(unsigned long)",
						[NSString stringWithUTF8String:@encode(unsigned long long)] : @"(unsigned long long)",
						[NSString stringWithUTF8String:@encode(float)] : @"(float)",
						[NSString stringWithUTF8String:@encode(double)] : @"(double)",
						[NSString stringWithUTF8String:@encode(BOOL)] : @"(BOOL)",
						[NSString stringWithUTF8String:@encode(void)] : @"(void)",
						[NSString stringWithUTF8String:@encode(char *)] : @"(char *)",
						[NSString stringWithUTF8String:@encode(id)] : @"(id)",
						[NSString stringWithUTF8String:@encode(Class)] : @"(Class)",
						[NSString stringWithUTF8String:@encode(SEL)] : @"(SEL)",
						[NSString stringWithUTF8String:@encode(CGRect)] : @"(CGRect)",
						[NSString stringWithUTF8String:@encode(CGPoint)] : @"(CGPoint)",
						[NSString stringWithUTF8String:@encode(CGSize)] : @"(CGSize)",
						[NSString stringWithUTF8String:@encode(CGVector)] : @"(CGVector)",
						[NSString stringWithUTF8String:@encode(CGAffineTransform)] : @"(CGAffineTransform)",
						[NSString stringWithUTF8String:@encode(UIOffset)] : @"(UIOffset)",
						[NSString stringWithUTF8String:@encode(UIEdgeInsets)] : @"(UIEdgeInsets)",
						@"@?":@"(block)"
						};
	});
	
	return dic;
}

BOOL ic_isCanHandle(NSString *typeEncode) {
	return [ic_canHandleTypeDic().allKeys containsObject:typeEncode];
}

BOOL ic_isCanHook(Method method, const char *returnType) {
	
	NSString *selectorName = NSStringFromSelector(method_getName(method));
	if (ic_isInSkipList(selectorName)) {
		return NO;
	}
	
	if ([selectorName rangeOfString:@"ic_"].location != NSNotFound) {
		return NO;
	}
	
	NSString *returnTypeString = [NSString stringWithUTF8String:returnType];
	
	BOOL isCanHook = YES;
	if (!ic_isCanHandle(returnTypeString)) {
		isCanHook = NO;
	}
	
	for(int k = 2 ; k < method_getNumberOfArguments(method); k++) {
		char argument[250];
		memset(argument, 0, sizeof(argument));
		method_getArgumentType(method, k, argument, sizeof(argument));
		NSString *argumentString = [NSString stringWithUTF8String:argument];
		
		if (!ic_isCanHandle(argumentString)) {
			isCanHook = NO;
			break;
		}
		
	}
	
	return isCanHook;
}

BOOL ic_isStructType(const char *argumentType) {
	NSString *typeString = [NSString stringWithUTF8String:argumentType];
	return ([typeString hasPrefix:@"{"] && [typeString hasSuffix:@"}"]);
}

NSString *ic_structName(const char *argumentType) {
	
	NSString *typeString = [NSString stringWithUTF8String:argumentType];
	NSUInteger start = [typeString rangeOfString:@"{"].location;
	NSUInteger end = [typeString rangeOfString:@"="].location;
	
	if (end > start) {
		return [typeString substringWithRange:NSMakeRange(start + 1, end - start - 1)];
	} else {
		return nil;
	}
}

BOOL isCGRect           (const char *type) { return [ic_structName(type) isEqualToString:@"CGRect"];}

BOOL isCGPoint          (const char *type) { return [ic_structName(type) isEqualToString:@"CGPoint"];}

BOOL isCGSize           (const char *type) { return [ic_structName(type) isEqualToString:@"CGSize"];}

BOOL isCGVector         (const char *type) { return [ic_structName(type) isEqualToString:@"CGVector"];}

BOOL isUIOffset         (const char *type) { return [ic_structName(type) isEqualToString:@"UIOffset"];}

BOOL isUIEdgeInsets     (const char *type) { return [ic_structName(type) isEqualToString:@"UIEdgeInsets"];}

BOOL isCGAffineTransform(const char *type) { return [ic_structName(type) isEqualToString:@"CGAffineTransform"];}

id getReturnValue(NSInvocation *invocation) {
	
	const char *returnType = invocation.methodSignature.methodReturnType;
	if (returnType[0] == 'r') {
		returnType++;
	}
	
	#define WRAP_GET_VALUE(type) \
	do { \
	type val = 0; \
	[invocation getReturnValue:&val]; \
	return @(val); \
	} while (0)
	
	if (strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0 || strcmp(returnType, @encode(void (^)(void))) == 0) {
		__autoreleasing id returnObj;
		[invocation getReturnValue:&returnObj];
		return returnObj;
	} else if (strcmp(returnType, @encode(char)) == 0) {
		WRAP_GET_VALUE(char);
	} else if (strcmp(returnType, @encode(int)) == 0) {
		WRAP_GET_VALUE(int);
	} else if (strcmp(returnType, @encode(short)) == 0) {
		WRAP_GET_VALUE(short);
	} else if (strcmp(returnType, @encode(long)) == 0) {
		WRAP_GET_VALUE(long);
	} else if (strcmp(returnType, @encode(long long)) == 0) {
		WRAP_GET_VALUE(long long);
	} else if (strcmp(returnType, @encode(unsigned char)) == 0) {
		WRAP_GET_VALUE(unsigned char);
	} else if (strcmp(returnType, @encode(unsigned int)) == 0) {
		WRAP_GET_VALUE(unsigned int);
	} else if (strcmp(returnType, @encode(unsigned short)) == 0) {
		WRAP_GET_VALUE(unsigned short);
	} else if (strcmp(returnType, @encode(unsigned long)) == 0) {
		WRAP_GET_VALUE(unsigned long);
	} else if (strcmp(returnType, @encode(unsigned long long)) == 0) {
		WRAP_GET_VALUE(unsigned long long);
	} else if (strcmp(returnType, @encode(float)) == 0) {
		WRAP_GET_VALUE(float);
	} else if (strcmp(returnType, @encode(double)) == 0) {
		WRAP_GET_VALUE(double);
	} else if (strcmp(returnType, @encode(BOOL)) == 0) {
		WRAP_GET_VALUE(BOOL);
	} else if (strcmp(returnType, @encode(char *)) == 0) {
		WRAP_GET_VALUE(const char *);
	} else if (strcmp(returnType, @encode(void)) == 0) {
		return @"void";
	} else {
		
		NSUInteger valueSize = 0;
		NSGetSizeAndAlignment(returnType, &valueSize, NULL);
		unsigned char valueBytes[valueSize];
		[invocation getReturnValue:valueBytes];
		
		return [NSValue valueWithBytes:valueBytes objCType:returnType];
	}
	return nil;
}

NSArray *ic_method_arguments(NSInvocation *invocation) {
	
	NSMethodSignature *methodSignature = [invocation methodSignature];
	NSMutableArray *argList = (methodSignature.numberOfArguments > 2 ? [NSMutableArray array] : nil);
	for (NSUInteger i = 2; i < methodSignature.numberOfArguments; i++) {
		const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
		id arg = nil;
		
		if (ic_isStructType(argumentType)) {
	
		#define GET_STRUCT_ARGUMENT(_type)\
		if (is##_type(argumentType)) {\
		_type arg_temp;\
		[invocation getArgument:&arg_temp atIndex:i];\
		arg = NSStringFrom##_type(arg_temp);\
		}
			GET_STRUCT_ARGUMENT(CGRect)
			else GET_STRUCT_ARGUMENT(CGPoint)
				else GET_STRUCT_ARGUMENT(CGSize)
					else GET_STRUCT_ARGUMENT(CGVector)
						else GET_STRUCT_ARGUMENT(UIOffset)
							else GET_STRUCT_ARGUMENT(UIEdgeInsets)
								else GET_STRUCT_ARGUMENT(CGAffineTransform)
									
									if (arg == nil) {
										arg = @"{unknown}";
									}
		}
		
		#define GET_ARGUMENT(_type)\
		if (0 == strcmp(argumentType, @encode(_type))) {\
		_type arg_temp;\
		[invocation getArgument:&arg_temp atIndex:i];\
		arg = @(arg_temp);\
		}
		
		else GET_ARGUMENT(char)
			else GET_ARGUMENT(int)
				else GET_ARGUMENT(short)
					else GET_ARGUMENT(long)
						else GET_ARGUMENT(long long)
							else GET_ARGUMENT(unsigned char)
								else GET_ARGUMENT(unsigned int)
									else GET_ARGUMENT(unsigned short)
										else GET_ARGUMENT(unsigned long)
											else GET_ARGUMENT(unsigned long long)
												else GET_ARGUMENT(float)
													else GET_ARGUMENT(double)
														else GET_ARGUMENT(BOOL)
															else if (0 == strcmp(argumentType, @encode(id))) {
																__unsafe_unretained id arg_temp;
																[invocation getArgument:&arg_temp atIndex:i];
																arg = arg_temp;
															}
															else if (0 == strcmp(argumentType, @encode(SEL))) {
																SEL arg_temp;
																[invocation getArgument:&arg_temp atIndex:i];
																arg = NSStringFromSelector(arg_temp);
															}
															else if (0 == strcmp(argumentType, @encode(char *))) {
																char *arg_temp;
																[invocation getArgument:&arg_temp atIndex:i];
																arg = [NSString stringWithUTF8String:arg_temp];
															}
															else if (0 == strcmp(argumentType, @encode(void *))) {
																void *arg_temp;
																[invocation getArgument:&arg_temp atIndex:i];
																arg = (__bridge id _Nonnull)arg_temp;
															}
															else if (0 == strcmp(argumentType, @encode(Class))) {
																Class arg_temp;
																[invocation getArgument:&arg_temp atIndex:i];
																arg = arg_temp;
															}
		
		if (!arg) {
			arg = @"unknown";
		}
		[argList addObject:arg];
	}
	return argList;
}

BOOL triggerForwardInvocation(Class cls, SEL selector, char *returnType) {
	Method method = nil;
	
	/// For meta class, class_getInstanceMethod() and class_getClassMethod() are same.
	method = class_getInstanceMethod(cls, selector);

	
	if (method == nil) {
		return NO;
	}
	
	IMP msg_forwardIMP = _objc_msgForward;
	IMP originIMP = method_getImplementation(method);
	
	if (originIMP == nil || originIMP == msg_forwardIMP) {
		return NO;
	}
	
	/// trigger forwardInvocation method
	const char *typeEncoding = method_getTypeEncoding(method);
	class_replaceMethod(cls, selector, msg_forwardIMP, typeEncoding);
	
	return YES;
	
}

BOOL ic_swizzleMethod(Class cls, SEL origSEL) {
	
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
	
	BOOL returnValue = class_addMethod(cls, newSelector, originIMP, origin_type);
	
	return returnValue;
}

BOOL ic_isInSkipList(NSString *methodName) {
	
	static NSArray *defaultBlackList = nil;
	static dispatch_once_t onceToken;
	
	dispatch_once(&onceToken, ^{
		defaultBlackList = @[/* UIViewController */
												 @".cxx_destruct",
												 @"dealloc",
												 @"_isDeallocating",
												 @"release",
												 @"autorelease",
												 @"retain",
												 @"Retain",
												 @"_tryRetain",
												 @"copy",
												 /* UIView */
												 @"nsis_descriptionOfVariable:",
												 /* NSObject */
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
												 @"lockFocusIfCanDraw",
												 @"setValue:forKey:"
												 ];
	});
	
	return ([defaultBlackList containsObject:methodName]);
}

void ic_logMethod(Class cls, BOOL(^condition)(SEL sel)) {
	
#ifndef DEBUG
	return;
#endif
	
	unsigned int methodCount;
	Method *methods = class_copyMethodList(cls,&methodCount);
	
	for (int i = 0; i < methodCount; i ++) {
		Method curMethod = *(methods + i);
		SEL selector = method_getName(curMethod);
		char *returnType = method_copyReturnType(curMethod);
		
		BOOL isCanHook = ic_isCanHook(curMethod, returnType);
		
		if (isCanHook && condition) {
			isCanHook = condition(selector);
		}
		
		if (isCanHook) {
			
			bool ret = ic_swizzleMethod(cls, selector);
			
			assert(ret);
			
			if (triggerForwardInvocation(cls, selector, returnType)) {
				DEV_LOG(@"success hook cls: %@ method: %@ types: %s", NSStringFromClass(cls), NSStringFromSelector(selector), method_getDescription(curMethod)->types);
			} else {
        DEV_LOG(@"fail hook cls: %@ method: %@ types: %s", NSStringFromClass(cls), NSStringFromSelector(selector), method_getDescription(curMethod)->types);
			}
		} else {
      DEV_LOG(@"can not hook cls: %@ method: %@ types: %s", NSStringFromClass(cls), NSStringFromSelector(selector), method_getDescription(curMethod)->types);
		}
		free(returnType);
		returnType = NULL;
	}
	free(methods);
	methods = NULL;
}
