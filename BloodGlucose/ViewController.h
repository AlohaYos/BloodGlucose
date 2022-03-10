//
//  ViewController.h
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/23.
//

@import Photos;
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <HealthKit/HealthKit.h>
#import <WatchConnectivity/WatchConnectivity.h>
#import <Charts/Charts-umbrella.h>
#import "Common.h"
#import "DateValueFormatter.h"
#import "PhotoInfo.h"
#import "AppDelegate.h"
#import "ShareData.h"

@interface ViewController : UIViewController
{
	AppDelegate* appDelegate;
	CAShapeLayer *circleLayer;
	NSMutableArray *shareList;	// iPhoneとWatchで共有するデータ

//@protected
//	NSArray *parties;
}

@property (strong, nonatomic) HKHealthStore *healthStore;
@property (strong, nonatomic) NSMutableArray *glucoseValue;
@property (strong, nonatomic) NSMutableArray<PhotoInfo*>* photoInfoArray;	// 写真のassetオブジェクトを管理する（日付などを表示できるように）

@property (nonatomic, strong) IBOutlet UIButton *optionsButton;
@property (nonatomic, strong) IBOutlet NSArray *options;
@property (nonatomic, assign) BOOL shouldHideData;


//- (void)handleOption:(NSString *)key forChartView:(ChartViewBase *)chartView;
- (void)updateChartData;
- (void)setupPieChartView:(PieChartView *)chartView;
- (void)setupRadarChartView:(RadarChartView *)chartView;
- (void)setupBarLineChartView:(BarLineChartViewBase *)chartView;

+ (NSSet<HKSampleType *> *)sampleTypes;
- (void)getBloodGlucose;
- (void)getPhotoAround:(NSDate*)centerDate minutesWidthBefore:(int)minutesWidthBefore minutesWidthAfter:(int)minutesWidthAfter;
- (void)clearPhotoInfos;
- (void)addPhotoInfo:(PhotoInfo*)photoInfo;
//- (void)addPhoto:(UIImage*)photoImage ofIndex:(int)index toSelf:(ViewController*)_self;
- (void)photoTapped:(UIGestureRecognizer *)sender;

- (void)logging:(NSString*)logmessage;
- (void)loggingWithClear:(NSString*)logmessage;

- (void)healthKitNotifyJob;


@end

