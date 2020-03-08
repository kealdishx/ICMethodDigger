//
//  ICMessageStub.h
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICMessageStub : NSObject

@property (nonatomic, unsafe_unretained) id target;

@property (nonatomic) SEL selector;

- (instancetype)initWithTarget:(id)target selector:(SEL)temporarySEL;

@end

NS_ASSUME_NONNULL_END
