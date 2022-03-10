//
//  AppDelegate.h
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/23.
//

#import <UIKit/UIKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <BackgroundTasks/BackgroundTasks.h>
#import <HealthKit/HealthKit.h>
#import "Common.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIViewController *mainVC;
@property (strong, nonatomic) WCSession *session;
@property (strong, nonatomic) HKHealthStore *healthStore;

// イベントが追加された時の通知先を登録する
- (void)registerLifeLogAddNotificationTo:(id)target selector:(SEL)selector;

@end

