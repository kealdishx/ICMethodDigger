//
//  AppDelegate.m
//  ICMethodDigger
//
//  Created by iCeBlink on 2018/7/30.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import "AppDelegate.h"
#import "ICMethodDigger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	[self logRunningMethods];
	
  return YES;
}

- (void)logAllMethods {
	
	icm_logMethod([UIViewController class], ^BOOL(SEL sel) {
		NSLog(@"%@", NSStringFromSelector(sel));
		return NO;
	}, ^(id target, SEL sel, NSArray *args) {
		NSLog(@"target:%@ sel:%@", target, NSStringFromSelector(sel));
	}, ^(id target, SEL sel, NSArray *args, NSTimeInterval interval, id retValue) {

	});
}

- (void)logRunningMethods {
	icm_logMethod([UIViewController class], ^BOOL(SEL sel) {
		return YES;
	}, ^(id target, SEL sel, NSArray *args) {
		
	}, ^(id target, SEL sel, NSArray *args, NSTimeInterval interval, id retValue) {
		NSLog(@"target:%@ sel:%@ interval: %f", target, NSStringFromSelector(sel), interval);
	});
}


@end
