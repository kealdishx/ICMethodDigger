//
//  ICMethodHelper.h
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICDefine.h"

@class ICBlock;

NS_ASSUME_NONNULL_BEGIN

@interface ICMethodHelper : NSObject

+ (void)logMethodWithClass:(Class)aClass
                 condition:(ICConditionBlock)condition
                    before:(nullable ICBeforeBlock)before
                     after:(nullable ICAfterBlock)after;

+ (instancetype)sharedInstance;

- (ICBlock *)blockWithTarget:(id)target;

@property (nonatomic, strong) NSMutableDictionary<NSString *, ICBlock *> *blockCache;

@end

NS_ASSUME_NONNULL_END

