//
//  AppDelegate.m
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/23.
//

#import <UserNotifications/UserNotifications.h>
#import "AppDelegate.h"
#import "ViewController.h"

NSString* logText = @"";

@interface AppDelegate () <CLLocationManagerDelegate>
	
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	[self logging:@"didFinishLaunchingWithOptions"];

	if ([WCSession isSupported]) {
		_session = [WCSession defaultSession];
		_session.delegate = self;
		[_session activateSession];
	}

	[self startUsingCoreLocation];
	
	// ヘルスキットのオブザーバー設置
	[self setupHealthKitObserve];

	// バックグラウンド処理を設置
	//[self registerBackgroundTasks];

	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(launchDefferedJob) userInfo:nil repeats:NO];
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(logUpdate) userInfo:nil repeats:YES];

	return YES;
}

- (void)launchDefferedJob
{
	[self logging:@"launchDefferedJob"];

	UIViewController* rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
	_mainVC = rootVC;
	
	[self prepareForNofify];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// SceneDelegate sceneDidEnterBackground:(UIScene *)scene から呼んでいる

	[self logging:@"applicationDidEnterBackground"];
//	[self scheduleNextBackgroundJob];	// 次のバックグラウンド処理
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// SceneDelegate sceneWillEnterForeground:(UIScene *)scene から呼んでいる

	[self logging:@"applicationWillEnterForeground"];
	if(_mainVC){
		[_mainVC performSelector:@selector(timerJob)];
	}
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[self requestRebootNotify];
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
	// Called when a new scene session is being created.
	// Use this method to select a configuration to create the new scene with.
	return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
	// Called when the user discards a scene session.
	// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
	// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	[self logging:@"didReceiveRemoteNotification"];
	NSLog(@"Received notification: %@", userInfo);
	
	completionHandler(UIBackgroundFetchResultNewData);
}

// WatchKit extensionとの会話
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply{
	
	[self logging:@"handleWatchKitExtensionRequest"];
	// 情報が更新されたことをViewControllerへアプリ内通知し、
	// Apple Watchから渡されたuserInfoパラメータ（内容はボタン番号）を渡す
	NSNotification *n =	[NSNotification notificationWithName:APP_NOTIFY_NAME object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:n];
	
	// Apple Watchへ応答を返す
	NSDictionary *response;
	response = @{@"response" : @""};
	reply(response);
}

- (void)session:(WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
	if ([message objectForKey:@"retrieveData"])
	{
		replyHandler(@{@"a":@"hello"});
	}
}

// 情報が更新された時の通知先（アプリ内）を登録する
- (void)registerLifeLogAddNotificationTo:(id)target selector:(SEL)selector {
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:target selector:selector name:APP_NOTIFY_NAME object:nil];
}

/*
#pragma mark - Backgound task

#define BACKGROUND_INTERVAL_MINUTES	10
int backgroundCount = 0;
static NSString* refreshTaskID = @"com.newtonjapan.bloodglucose.background.refresh";
static NSString* processingTaskID = @"com.newtonjapan.bloodglucose.background.process";

- (void)registerBackgroundTasks {
	[self logging:@"registerBackgroundTasks"];
	[[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:processingTaskID usingQueue:nil launchHandler:^(__kindof BGTask * _Nonnull task) {
		[self logging:@"registerForTaskWithIdentifier"];
		[self backgroundJob:task];
		[task setTaskCompletedWithSuccess:true];
	}];
}

- (void)backgroundJob:(BGProcessingTask *)task {
	[self logging:@"backgroundJob"];
	[self scheduleNextBackgroundJob];	// 次のバックグラウンド処理

	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperationWithBlock: ^{

		// DO THE JOB
		[self logging:@"refreshTask"];
		[_mainVC performSelector:@selector(refreshTask)];
		backgroundCount++;
		[ShareData setObject:[NSNumber numberWithInt:backgroundCount] forKey:@"backgroundCount"];
		[task setTaskCompletedWithSuccess:!queue.isSuspended];
	}];

	// タスクを完了させられずに終了した場合の処理
	[task setExpirationHandler:^{
		[queue cancelAllOperations];
	}];
}

- (void)scheduleNextBackgroundJob {
	[self logging:@"scheduleNextBackgroundJob"];
	BGProcessingTaskRequest *request = [[BGProcessingTaskRequest alloc] initWithIdentifier:processingTaskID];
	[request setRequiresNetworkConnectivity:NO];	// 通信が無い時間にも起動する
	[request setRequiresExternalPower:NO];	// 充電中でなくても実行する
	[request setEarliestBeginDate:[NSDate dateWithTimeIntervalSinceNow:10]]; //Start after 10 seconds

	NSError *requestError;
	[[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&requestError];
	if (requestError) {
		NSLog(@"Exception: %@", requestError);
		[self logging:[NSString stringWithFormat:@"submitTaskRequest Error: %@", requestError]];
		
	}
}
*/

/*
// lldbコンソールでデバッグ実行する

// 時間経過をシミュレート
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateExpirationForTaskWithIdentifier:@"com.newtonjapan.bloodglucose.background.refresh"]
// タスクの起動をシミュレート
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.newtonjapan.bloodglucose.background.refresh"]


 */

#pragma mark - Logging

- (void)logging:(NSString*)logmessage
{
	NSDate* logDate = [NSDate now];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"HH:mm:ss";
	NSString* dateString = [dateFormatter stringFromDate:logDate];

	logText = [NSString stringWithFormat:@"%@ %@\n%@", dateString, logmessage,logText];
	NSLog(logmessage);
}

-(void)logUpdate
{
	if(_mainVC){
		[_mainVC performSelector:@selector(loggingWithClear:) withObject:logText];
	}
}

#pragma mark - HealthKit

// 血糖値の変動検知を登録
- (void)setupHealthKitObserve
{
	[self logging:@"setupHealthKitObserve"];
	if ([HKHealthStore isHealthDataAvailable]) {
		self.healthStore = [[HKHealthStore alloc] init];
		NSSet* readTypes = [NSSet setWithObject:[HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose]];
		
		[self.healthStore requestAuthorizationToShareTypes:nil
												 readTypes:readTypes
												completion:^(BOOL success, NSError *error)
		 {
			 if (!error && success)
			 {
				 [self observeHealthKit];

				 [self.healthStore enableBackgroundDeliveryForType:
						[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose]
						frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error){}];
			 }
		 }];
	}
}

int healthKitNotifyInProgress = NO;

// 値に変動があった場合に呼び出される
- (void)observeHealthKit
{
	[self logging:@"requestAuthorizationToShareTypes"];

	HKObserverQuery *query = [[HKObserverQuery alloc]initWithSampleType:[HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose]
						predicate:nil
	updateHandler:^(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error)
	{
		if(!healthKitNotifyInProgress){
			healthKitNotifyInProgress = YES;
			
			if (!error)
			{
				[self logging:@"HealthKit Notify"];
				
				if(_mainVC){
					[_mainVC performSelector:@selector(healthKitNotifyJob)];
					[self logging:@"Did HealthKit Notify job"];
				}
				if (completionHandler)
				{
					completionHandler();
				}

			//	[self queryWithCompletionHandler:completionHandler];
			}
			else
			{
				if (completionHandler)
				{
					completionHandler();
				}
			}
			healthKitNotifyInProgress = NO;
		}
		else {
			// Query already in progress
		}
		
	}];

	[self.healthStore executeQuery:query];
}

#pragma mark - Local notification

- (void)prepareForNofify {

	NSUserDefaults *userdefault = [NSUserDefaults standardUserDefaults];
	NSString* prepared = [userdefault objectForKey:@"prepareForNofify"];
	
	if(![prepared isEqualToString:@"Prepared"]){
#if 1
		NSString *title    = @"通知許可のお願い";
		NSString *message  = @"BloodGlucoseアプリからの情報を表示するために、通知を許可してください。";
		NSString *yesLabel = @"OK";
#else
		NSString *title    = NSLocalizedString(@"Notify_Permission", nil);	//"通知許可のお願い";
		NSString *message  = NSLocalizedString(@"Please_grant_permission_to_notify", nil);	//"Tellus-HMIアプリからの情報を表示するために、通知を許可してください。";
		NSString *yesLabel = NSLocalizedString(@"OK_button_title", nil);	// "OK";
#endif
		// 事前了解メッセージ
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:yesLabel style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:
			 (UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert ) completionHandler:^(BOOL granted, NSError *_Nullable error) {
				if(granted) {
				}
				NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
				[ud setValue:@"Prepared" forKey:@"prepareForNofify"];
			 }];
			[[UIApplication sharedApplication]  registerForRemoteNotifications];
		}]];
		
		UIViewController* baseVC = [UIApplication sharedApplication].keyWindow.rootViewController;
		if(baseVC.presentedViewController){
			baseVC = baseVC.presentedViewController;
		}
		if(baseVC){
			[baseVC presentViewController:alertController animated:YES completion:nil];
		}
	}
}

- (void)requestRebootNotify
{
#if 1
	NSString *mainMessage = @"BloodGlucoseを常に起動";
	NSString *detailMessage = @"ここをタップしてBloodGlucoseアプリへ戻ります。";
#else
	NSString *mainMessage = NSLocalizedString(@"Tap_here_to_return_to_TellusHMI_app", nil);	//"ここをタップしてTellus-HMIアプリへ戻ります";
	NSString *detailMessage = NSLocalizedString(@"You_can_also_tap_TellusHMI_icon_to_return_to_app", nil);	//"Tellus-HMIアイコンをタップして戻ることもできます。";
#endif
	
	[self requestNotifyMessage:mainMessage detailMessage:detailMessage];
}

- (void)requestNotifyMessage:(NSString*)mainMessage detailMessage:(NSString*)detailMessage
{
	// 通知を作成
	UNMutableNotificationContent *unMutableNotice = [UNMutableNotificationContent new];
	// title、body、soundを設定
	unMutableNotice.title = mainMessage;
	unMutableNotice.body = detailMessage;
	unMutableNotice.sound = [UNNotificationSound defaultSound];
	UNTimeIntervalNotificationTrigger *triger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
	UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"bloodGlucoseNotifyID" content:unMutableNotice trigger:triger];
	[UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request withCompletionHandler:nil];
}

#pragma mark - Location update

CLLocationManager* locationManager;
BOOL deferringUpdates = NO;

- (void)startUsingCoreLocation
{
	CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
	if(status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied){
		return;
	}
	
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	
	if(status == kCLAuthorizationStatusNotDetermined){
		if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
		//	[locationManager requestWhenInUseAuthorization];
		}

		if ([locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
			[locationManager requestAlwaysAuthorization];
		}
	}
	
	if(locationManager.locationServicesEnabled==NO){
		return;
	}
	
	locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
	locationManager.distanceFilter = 100;
	
	[locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
  {
	  [self logging:@"didUpdateToLocation"];

	  if(deferringUpdates==NO && [CLLocationManager deferredLocationUpdatesAvailable]){
		  [locationManager allowDeferredLocationUpdatesUntilTraveled:CLLocationDistanceMax timeout:(NSTimeInterval)1*60];
		  deferringUpdates = YES;
		  return;
	  }
	  
	  //This method will show us that we recieved the new location
	  NSLog(@"Latitude = %f",newLocation.coordinate.latitude );
	  NSLog(@"Longitude =%f",newLocation.coordinate.longitude);

	  
	  if(_mainVC){
		  [_mainVC performSelector:@selector(locationUpdateJob)];
		  [self logging:@"Did location job"];
	  }
  }

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error{
	[self logging:@"didFinishDeferredUpdatesWithError"];

	if(_mainVC){
		[_mainVC performSelector:@selector(locationUpdateJob)];
		[self logging:@"Did location job"];
	}

	deferringUpdates = NO;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
  {
	//Failed to recieve user's location
	[self logging:@"failed to receive location"];
  }

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
	[self logging:@"locationManagerDidPauseLocationUpdates"];
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
	[self logging:@"locationManagerDidResumeLocationUpdates"];
//	deferringUpdates = YES;
}

@end
