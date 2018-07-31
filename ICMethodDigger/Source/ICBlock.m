//
//  ICBlock.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/31.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import "ICBlock.h"

@implementation ICBlock

- (BOOL)runCondition:(SEL)sel {
	
	if (self.condition) {
		return self.condition(sel);
	} else {
		return YES;
	}
	
}

- (void)rundBefore:(id)target sel:(SEL)sel args:(NSArray *)args deep:(int) deepth {
	if (self.before) {
		self.before(target, sel, args, deepth);
	}
}

- (void)rundAfter:(id)target sel:(SEL)sel args:(NSArray *)args interval:(NSTimeInterval)interval deep:(int)deepth retValue:(id)retValue{
	
	if (self.after) {
		self.after(target, sel, args, interval, deepth, retValue);
	}
	
}

@end
