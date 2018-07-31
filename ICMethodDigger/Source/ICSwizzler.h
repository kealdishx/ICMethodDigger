//
//  ICSwizzler.h
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN void ic_addSwizzle(Class cls);

FOUNDATION_EXTERN BOOL ic_isInSkipList(NSString *methodName);
