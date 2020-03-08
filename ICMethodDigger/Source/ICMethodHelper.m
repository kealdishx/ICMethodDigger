//
//  ICMethodHelper.m
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import "ICMethodHelper.h"
#import "ICBlock.h"
#import "ICHandler.h"

@interface ICMethodHelper()

@property (nonatomic, strong) dispatch_semaphore_t semaphore;

- (void)setICBlock:(ICBlock *)block forKey:(NSString *)aKey;

@end

@implementation ICMethodHelper

#pragma mark - Class Methods
+ (void)logMethodWithClass:(Class)aClass
                 condition:(ICConditionBlock)condition
                    before:(ICBeforeBlock)before
                     after:(ICAfterBlock)after {
#ifndef DEBUG
	return;
#endif
	
	if (aClass) {
		
		ICBlock *block = [[ICBlock alloc] init];
		block.targetClassName = NSStringFromClass(aClass);
		block.condition = condition;
		block.before = before;
		block.after = after;
		[[self sharedInstance] setICBlock:block forKey:block.targetClassName];
	}
	
	ic_logMethod(aClass, condition);
	
	/// Get meta class to handle class methods
    Class metaCls = object_getClass(aClass);
    ic_logMethod(metaCls, condition);
}

+ (instancetype)sharedInstance {
	
	static ICMethodHelper *_sharedICMethodDigger = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_sharedICMethodDigger = [[self alloc] init];
		_sharedICMethodDigger.blockCache = [NSMutableDictionary dictionary];
        _sharedICMethodDigger.semaphore = dispatch_semaphore_create(1);
	});
	
	return _sharedICMethodDigger;
}

- (void)setICBlock:(ICBlock *)block forKey:(NSString *)aKey {
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	[self.blockCache setObject:block forKey:aKey];
	dispatch_semaphore_signal(self.semaphore);
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
