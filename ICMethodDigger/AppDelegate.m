//
//  AppDelegate.m
//  ICMethodDigger
//
//  Created by iCeBlink on 2018/7/30.
//  Copyright © 2018年 iiiCeBlink. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "ICMethodDigger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
  [self logRunningMethods];
//  [self logAllMethods];
  
  return YES;
}

- (void)logAllMethods {
	
	icm_logMethod([ViewController class], ^BOOL(SEL sel) {
		return NO;
	}, nil, nil);
}

- (void)logRunningMethods {
	icm_logMethod([UIViewController class], ^BOOL(SEL sel) {
		return YES;
	}, nil, ^(id target, SEL sel, NSArray *args, NSTimeInterval interval, id retValue) {
		NSLog(@"target:%@ sel:%@ interval: %f s", target, NSStringFromSelector(sel), interval);
	});
}


@end
