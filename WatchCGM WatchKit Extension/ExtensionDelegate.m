//
//  ExtensionDelegate.m
//  WatchCGM WatchKit Extension
//
//  Created by Yos Hashimoto on 2022/03/05.
//

#import <ClockKit/ClockKit.h>
#import "ExtensionDelegate.h"
#import "ShareData.h"

#define D_BACKGROUND_INTERVAL	(60*5)	// second

@implementation ExtensionDelegate

// Watch Extension内でのバックグラウンド動作を登録
- (void)setScheduleBackgroundRefresh
{
	NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:D_BACKGROUND_INTERVAL];
	[[WKExtension sharedExtension] scheduleBackgroundRefreshWithPreferredDate:fireDate userInfo:nil scheduledCompletion:^(NSError * _Nullable error) {
		if(error == nil) {
			NSLog(@"background refresh task re-scheduling successfuly  ");
		}
		else{
			NSLog(@"Error occurred while re-scheduling background refresh: %@",error.localizedDescription);
		}
	}];
}

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
	[self setScheduleBackgroundRefresh];
}

int backgroundCount = 0;

- (void)handleBackgroundTasks:(NSSet<WKRefreshBackgroundTask *> *)backgroundTasks {
	NSLog(@"### Watch background task");
	backgroundCount++;
	[ShareData setObject:[NSNumber numberWithInt:backgroundCount] forKey:@"backgroundCount"];

    // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
    for (WKRefreshBackgroundTask * task in backgroundTasks) {
        // Check the Class of each task to decide how to process it
        if ([task isKindOfClass:[WKApplicationRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKApplicationRefreshBackgroundTask *backgroundTask = (WKApplicationRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKSnapshotRefreshBackgroundTask class]]) {
            // Snapshot tasks have a unique completion call, make sure to set your expiration date
            WKSnapshotRefreshBackgroundTask *snapshotTask = (WKSnapshotRefreshBackgroundTask*)task;
            [snapshotTask setTaskCompletedWithDefaultStateRestored:YES estimatedSnapshotExpiration:[NSDate distantFuture] userInfo:nil];
        } else if ([task isKindOfClass:[WKWatchConnectivityRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKWatchConnectivityRefreshBackgroundTask *backgroundTask = (WKWatchConnectivityRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKURLSessionRefreshBackgroundTask class]]) {
            // Be sure to complete the background task once you’re done.
            WKURLSessionRefreshBackgroundTask *backgroundTask = (WKURLSessionRefreshBackgroundTask*)task;
            [backgroundTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKRelevantShortcutRefreshBackgroundTask class]]) {
            // Be sure to complete the relevant-shortcut task once you’re done.
            WKRelevantShortcutRefreshBackgroundTask *relevantShortcutTask = (WKRelevantShortcutRefreshBackgroundTask*)task;
            [relevantShortcutTask setTaskCompletedWithSnapshot:NO];
        } else if ([task isKindOfClass:[WKIntentDidRunRefreshBackgroundTask class]]) {
            // Be sure to complete the intent-did-run task once you’re done.
            WKIntentDidRunRefreshBackgroundTask *intentDidRunTask = (WKIntentDidRunRefreshBackgroundTask*)task;
            [intentDidRunTask setTaskCompletedWithSnapshot:NO];
        } else {
            // make sure to complete unhandled task types
            [task setTaskCompletedWithSnapshot:NO];
        }
		
		[self setScheduleBackgroundRefresh];
		
		CLKComplicationServer* server = [CLKComplicationServer sharedInstance];
		for(CLKComplication *comp in server.activeComplications) {
			NSLog(@"### Prepare for next complication update");
			[server reloadTimelineForComplication:comp];
		}

    }
	
}

@end
