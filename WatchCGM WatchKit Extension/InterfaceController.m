//
//  InterfaceController.m
//  WatchCGM WatchKit Extension
//
//  Created by Yos Hashimoto on 2022/03/05.
//

static id myObj; //C関数からselfへのアクセスポインタ

#import "InterfaceController.h"
#import "ComplicationController.h"
#import "Common.h"
#import "ShareData.h"

WCSession *session;

@interface InterfaceController ()
@end


@implementation InterfaceController

- (IBAction)buttonPushed {
}

- (void)awakeWithContext:(id)context {
	[super awakeWithContext:context];

	// Cの関数でObjective-Cのメソッドを呼び出すための準備
	myObj = self;
	
	// iOS側からの通知を受け取る準備
	[self addObserver];

	// Phone側へ送る準備
	session = [WCSession defaultSession];
	session.delegate = self;
	[session activateSession];

	[_labelBigCGMValue setTextColor:[UIColor cyanColor]];
}

- (void)willActivate {
	[super willActivate];

	// 最初に共有リストをクリア
	_shareList = [[NSMutableArray alloc] initWithCapacity:1];
	[ShareData saveSharedList:_shareList];
}

- (void)didDeactivate {
	[super didDeactivate];
}

#pragma mark - ボタンが押されたときの処理

- (IBAction)shootButtonPushed {
	
	// 現在時刻を追加
	[_shareList addObject:[NSDate new]];
		
	// 共有コンテナに保存
	[ShareData saveSharedList:_shareList];
	// 表示内容を更新
//	[self refreshInformation];
	// 相手の番
	[self yourTurn];
}

#pragma mark - 別プロセスとのヤリトリ

- (void)yourTurn {
		// 相手に通知
	[self sendEventToOwnerApp];
}

- (void)myTurn {
	_shareList = [[NSMutableArray alloc] initWithArray:[ShareData loadSharedList]];
	
	NSNumber *cgmValue = [ShareData objectForKey:@"currentCGM"];
	double currentCGM = [cgmValue doubleValue];

	// 表示内容を更新
//	[self refreshInformation];
}

// iOSアプリにボタン番号を伝達する
- (void)sendEventToOwnerApp {
	
	// 送信する情報
	NSDictionary *requst = @{@"info":@""};
	
	// iOSアプリへ情報を送信し、応答を受信する
	[[WCSession defaultSession] sendMessage:requst
								   replyHandler:^(NSDictionary<NSString *,id> * _Nonnull replyMessage) {
								   }
								   errorHandler:^(NSError * _Nonnull error) {
								   }];
/*
	// iOSアプリへ情報を送信し、応答を受信する
	[InterfaceController openParentApplication:requst reply:^(NSDictionary *replyInfo, NSError *error) {
		
		if (error) {
			NSLog(@"%@", error);	// エラー時の処理
		}
	}];
*/
}

// iOS側からの通知（プロセス間通知）を受け取る関数を事前登録しておく
- (void)addObserver {
	
	// iOS側から通知を受けた時のコールバック関数を登録
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
									(__bridge const void *)(self),
									MyCallBack,			// コールバック関数
									(CFStringRef)GLOBAL_NOTIFY_NAME,
									NULL,
									CFNotificationSuspensionBehaviorDrop);
}

// iOS側から通知を受けた時に呼び出される関数
static void MyCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	
	// Objective-CのmyTurnメソッドをコール
	SEL selector = @selector(myTurn);
	((void (*)(id, SEL))[myObj methodForSelector:selector])(myObj, selector);
}


- (void)session:(WCSession *)session didReceiveMessage:(nonnull NSDictionary<NSString *,id> *)message replyHandler:(nonnull void (^)(NSDictionary<NSString *,id> * _Nonnull))replyHandler
{
	if ([message objectForKey:@"currentCGM"])
	{
		NSNumber* num = [message objectForKey:@"currentCGM"];
		NSDate* datetime = [message objectForKey:@"currentDate"];
		NSLog(@"didReceiveMessage:%@ %@", num, datetime);
		[self setCurrentData:num datetime:datetime];
		[self requestComplicationUpdate];
		replyHandler(@{@"a":@"hello"});
	}
}

- (void)session:(WCSession *)session didReceiveUserInfo:(nonnull NSDictionary<NSString *,id> *)userInfo
{
	if ([userInfo objectForKey:@"currentCGM"])
	{
		NSNumber* num = [userInfo objectForKey:@"currentCGM"];
		NSDate* datetime = [userInfo objectForKey:@"currentDate"];
		NSLog(@"didReceiveMessage:%@ %@", num, datetime);
		[self setCurrentData:num datetime:datetime];
		[self requestComplicationUpdate];
	}
}

NSMutableArray* datetimeArray = nil;
NSMutableArray* datetimeLabelArray = nil;
int receiveCount = 0;
#define DATETIME_LABEL_ARRAY_COUNT	5

- (void)setCurrentData:(NSNumber*)cgmValue datetime:(NSDate*)datetime
{
	if(!datetimeArray){
		datetimeArray = [NSMutableArray new];
		datetimeLabelArray = [NSMutableArray new];
		[datetimeLabelArray insertObject:_labelDate1 atIndex:0];
		[datetimeLabelArray insertObject:_labelDate2 atIndex:1];
		[datetimeLabelArray insertObject:_labelDate3 atIndex:2];
		[datetimeLabelArray insertObject:_labelDate4 atIndex:3];
		[datetimeLabelArray insertObject:_labelDate5 atIndex:4];
	}

	[ShareData setObject:cgmValue forKey:@"currentCGM"];
	[ShareData setObject:datetime forKey:@"currentDate"];
	[_labelCGMValue setText:[NSString stringWithFormat:@"%.0fmd/dL", [cgmValue doubleValue]]];
	[datetimeArray insertObject:datetime atIndex:0];

	[_labelBigCGMValue setText:[NSString stringWithFormat:@"%.0f", [cgmValue doubleValue]]];
	if(([cgmValue doubleValue]<=CGM_MIN_VAL)||([cgmValue doubleValue]>CGM_MAX_VAL)) {
		[_labelBigCGMValue setTextColor:[UIColor redColor]];
	}
	else {
		[_labelBigCGMValue setTextColor:[UIColor cyanColor]];
	}

	if(DATETIME_LABEL_ARRAY_COUNT<datetimeArray.count){
		[datetimeArray removeLastObject];
	}

	for(int i=0; i<DATETIME_LABEL_ARRAY_COUNT; i++){
		if(datetimeArray.count<=i){
			break;
		}
		NSDate* dt = (NSDate*)[datetimeArray objectAtIndex:i];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"MM/dd HH:mm";
		NSString* dateString = [dateFormatter stringFromDate:dt];
		WKInterfaceLabel *lblDt = (WKInterfaceLabel*)[datetimeLabelArray objectAtIndex:i];
		[lblDt setText:[NSString stringWithFormat:@"%@ %.0f", dateString, [cgmValue doubleValue]]];
	}

	receiveCount++;
	NSNumber* complicationUpdateCount = [ShareData objectForKey:@"complicationUpdateCount"];
	int count = [complicationUpdateCount intValue];
	NSNumber* backgroundCount = [ShareData objectForKey:@"backgroundCount"];
	int bgCount = [backgroundCount intValue];
	[_labelCounter setText:[NSString stringWithFormat:@"rcv%d dsp%d bak%d", receiveCount, count, bgCount]];
}

- (void)requestComplicationUpdate
{
	CLKComplicationServer* server = [CLKComplicationServer sharedInstance];
	for(CLKComplication *comp in server.activeComplications) {
		NSLog(@"### Prepare for next complication update");
		[server reloadTimelineForComplication:comp];
	}
}

@end



