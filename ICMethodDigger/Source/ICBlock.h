//
//  ICBlock.h
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICBlock : NSObject

@property (nonatomic, copy) NSString *targetClassName;

@property (nonatomic, copy) ICConditionBlock condition;

@property (nonatomic, copy) ICBeforeBlock before;

@property (nonatomic, copy) ICAfterBlock  after;

- (BOOL)runCondition:(SEL)sel;

- (void)rundBefore:(id)target sel:(SEL)sel args:(NSArray *)args;

- (void)rundAfter:(id)target sel:(SEL)sel args:(NSArray *)args interval:(NSTimeInterval)interval retValue:(id)retValue;

@end

NS_ASSUME_NONNULL_END
