//
//  ICMethodDigger.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICMethodDigger.h"
#import "ICMethodHelper.h"

void icm_logMethod(Class cls, ICConditionBlock condition, ICBeforeBlock before, ICAfterBlock after) {
	#if defined(__arm64__)
	[ICMethodHelper logMethodWithClass:cls condition:condition before:before after:after];
	#endif
}
