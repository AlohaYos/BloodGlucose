//
//  InterfaceController.h
//  WatchCGM WatchKit Extension
//
//  Created by Yos Hashimoto on 2022/03/05.
//

#import <WatchKit/WatchKit.h>
#import <ClockKit/ClockKit.h>
#import <Foundation/Foundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface InterfaceController : WKInterfaceController
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelBigCGMValue;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelCGMValue;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelDate1;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelDate2;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelDate3;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelDate4;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelDate5;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *labelCounter;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *buttonPush;
@property (strong, nonatomic) NSMutableArray	*shareList;	// iPhoneとAppleWatchで共有するリスト
@end
