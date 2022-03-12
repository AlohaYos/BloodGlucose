//
//  ViewController.m
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/23.
//

#import "ViewController.h"
#import "SampleData.h"

#define D_MOVEAVE_MAX			10		// 移動平均の演算の数
#define D_MINUTES_WIDTH_BEFORE	240		// その時点から何分前のイベントまで検索するか
#define D_MINUTES_WIDTH_AFTER	15		// その時点から何分後のイベントまで検索するか
#define D_DATA_FETCH_INTERVAL	(60.0*1)
#define D_CHECK_DAYS	2					// 何日前までグラフにするか
#define D_THUMBNAIL_MARGIN	5

double currentCGM = 0;
NSDate* currentDate = nil;

@interface ViewController ()

@property (nonatomic, strong) IBOutlet UIView *myView;
@property (nonatomic, strong) IBOutlet LineChartView *chartView;
@property (nonatomic, strong) IBOutlet UISlider *sliderX;
@property (nonatomic, strong) IBOutlet UILabel *sliderTextX;
@property (nonatomic, strong) IBOutlet UILabel *labelEntryDate;
@property (nonatomic, strong) IBOutlet UILabel *labelGluValue;

@property (nonatomic, strong) IBOutlet UILabel *labelInfomation;
@property (nonatomic, strong) IBOutlet UILabel *labelBigValue;
@property (nonatomic, strong) IBOutlet UILabel *labelBigDate;
@property (nonatomic, strong) IBOutlet UILabel *labelBigUnit;
@property (nonatomic, strong) IBOutlet UITextView *textviewLog;
@property (nonatomic, strong) IBOutlet UIButton* logToggleButton;

// 写真リスト
@property (nonatomic, strong) IBOutlet UIScrollView *scrollBaseview;
@property (nonatomic, strong) IBOutlet UIView *scrollContentView;

// 写真１枚の拡大
@property (nonatomic, strong) IBOutlet UIScrollView *photoZoomBaseview;
@property (nonatomic, strong) IBOutlet UIImageView *photoZoomContentView;
@property (nonatomic, strong) IBOutlet UIView *photoZoomBackgroundView;
@property (nonatomic, strong) IBOutlet UIButton* photoCloseButton;
@property (nonatomic, strong) IBOutlet UILabel *labelPhotoDate;

@end

@implementation ViewController

- (NSSet<HKSampleType *> *)sampleTypes {
	NSArray<HKSampleType *> *types = @[
		[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose]
	];
	return [NSSet setWithArray:types];
}

//- (void)viewWillLayoutSubviews{
- (void)viewDidLayoutSubviews{
/*
	// SafeAreaの調整（グラフが全部表示されるように）
	UIWindow* keyWin = [[UIApplication sharedApplication] keyWindow];
	int topInset    =  [keyWin safeAreaInsets].top;		// 縦:50　横:00
	int bottomInset =  [keyWin safeAreaInsets].bottom;	// 縦:34　横:21
	int rightInset  =  [keyWin safeAreaInsets].right;	// 縦:00　横:50
	int leftInset   =  [keyWin safeAreaInsets].left;	// 縦:00　横:50
	bottomInset *= 1;
//	NSLog(@"T:%d,B:%d,R:%d,L:%d", topInset,bottomInset,rightInset,leftInset);

	UIDeviceOrientation orientation = UIDevice.currentDevice.orientation;
	
	switch(orientation){
		case UIDeviceOrientationLandscapeLeft:
//			NSLog(@"LandscapeLeft");
			topInset = 20;
			bottomInset = 0;
			rightInset = 0;
			leftInset = 40;
			break;
		case UIDeviceOrientationLandscapeRight:
//			NSLog(@"LandscapeRight");
			topInset = 20;
			bottomInset = 0;
			rightInset = 40;
			leftInset = 0;
			break;
		case UIDeviceOrientationPortrait:
//			NSLog(@"Portrait");
			topInset = 44;
			bottomInset = 20;
			rightInset = 0;
			leftInset = 0;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
//			NSLog(@"PortraitUpsideDown");
			topInset = 0;
			bottomInset = 20;
			rightInset = 0;
			leftInset = 0;
			break;
	}

//	topInset = 0;
//	bottomInset = 0;
//	rightInset = 0;
//	leftInset = 0;

	_myView.translatesAutoresizingMaskIntoConstraints = NO;
	NSLayoutConstraint* topAnchor    = [_myView.topAnchor constraintEqualToAnchor:_chartView.safeAreaLayoutGuide.topAnchor constant:topInset];
	NSLayoutConstraint* bottomAnchor = [_myView.bottomAnchor constraintEqualToAnchor:_chartView.safeAreaLayoutGuide.bottomAnchor constant:bottomInset];
	NSLayoutConstraint* rightAnchor  = [_myView.rightAnchor constraintEqualToAnchor:_chartView.safeAreaLayoutGuide.rightAnchor constant:rightInset];
	NSLayoutConstraint* leftAnchor   = [_myView.leftAnchor constraintEqualToAnchor:_chartView.safeAreaLayoutGuide.leftAnchor constant:leftInset];
	[topAnchor setActive:YES];
	[bottomAnchor setActive:YES];
	[rightAnchor setActive:YES];
	[leftAnchor setActive:YES];
	[_chartView addConstraint:topAnchor];
	[_chartView addConstraint:bottomAnchor];
	[_chartView addConstraint:rightAnchor];
	[_chartView addConstraint:leftAnchor];
//	[_chartView removeConstraint:topAnchor];
	
*/
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.photoZoomContentView;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	appDelegate = [UIApplication sharedApplication].delegate;
	appDelegate.mainVC = self;
	currentDate = [NSDate now];
	
	[self initializeWatchJob];
	
	self.myView.hidden=YES;
	self.scrollBaseview.hidden=YES;
	self.photoCloseButton.hidden=YES;
	self.photoZoomBaseview.maximumZoomScale =4.0;
	self.photoZoomBaseview.minimumZoomScale =1.0;
	self.photoZoomBaseview.delegate = self;
	self.photoZoomBaseview.userInteractionEnabled = YES;
	self.photoZoomBaseview.hidden = YES;


	self.photoInfoArray = [NSMutableArray new];
	
	for(UIView *view in [self.scrollContentView subviews]){
		[view removeFromSuperview];
	}

	self.healthStore = [HKHealthStore new];
	self.glucoseValue = [NSMutableArray new];
	
	// ヘルスキットの認証
	__weak __typeof(self) weakself = self;
	[self.healthStore requestAuthorizationToShareTypes:nil readTypes:[self sampleTypes] completion:^(BOOL success, NSError *error) {
		if (error) {
			NSLog(@"HKHealthStoreRequestAuthorization Error: %@", error);
			return;
		}
		if (success) {
			[weakself getBloodGlucose];
		}
	}];

	self.title = @"Time Line Chart";

	// タッチ操作などの委譲
	_chartView.delegate = self;

	// チャートの挙動設定
	_chartView.chartDescription.enabled = NO;
	_chartView.dragEnabled = YES;
	_chartView.pinchZoomEnabled = NO;
	_chartView.drawGridBackgroundEnabled = NO;
	_chartView.highlightPerDragEnabled = YES;
	_chartView.backgroundColor = UIColor.blackColor;
	_chartView.legend.enabled = NO;
	_chartView.rightAxis.enabled = NO;
	_chartView.legend.form = ChartLegendFormLine;
	[_chartView setScaleEnabled:YES];
	[_chartView animateWithXAxisDuration:2.0 yAxisDuration:2.0];

	// 横軸の設定
	ChartXAxis *xAxis = _chartView.xAxis;
	xAxis.labelPosition = XAxisLabelPositionBottomInside;
//	xAxis.labelPosition = XAxisLabelPositionTopInside;
	xAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.f];
	xAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
	xAxis.drawAxisLineEnabled = NO;
	xAxis.drawGridLinesEnabled = YES;
	xAxis.centerAxisLabelsEnabled = YES;
	xAxis.granularity = 3600.0;
	xAxis.valueFormatter = [[DateValueFormatter alloc] init];
	
	// 縦軸の設定
	ChartYAxis *leftAxis = _chartView.leftAxis;
	leftAxis.labelPosition = YAxisLabelPositionInsideChart;
	leftAxis.labelFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:12.f];
	leftAxis.labelTextColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
	leftAxis.drawGridLinesEnabled = YES;
	leftAxis.granularityEnabled = YES;
	leftAxis.axisMinimum = 0.0;
	leftAxis.axisMaximum = 500.0;
	leftAxis.yOffset = -9.0;
	leftAxis.labelTextColor = [UIColor colorWithRed:255/255.0 green:192/255.0 blue:56/255.0 alpha:1.0];
	
	// 移動平均スライダーの設定
	_sliderX.value = 1.0;
	_sliderX.maximumValue = D_MOVEAVE_MAX;
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(slidersValueChanged:) userInfo:nil repeats:NO];
	[self timerJob];
	[NSTimer scheduledTimerWithTimeInterval:D_DATA_FETCH_INTERVAL target:self selector:@selector(timerJob) userInfo:nil repeats:YES];
	
	// ヘルスキットの血糖値がアップデートされたらコールバックされるように登録
	//[self registerBloodGlucoseObserver];
}

int originalFrameZoomHeight = -1;
int originalTopInset = -1;

#define D_SCROLLBASE_HEIGHT_NORMAL	128
#define D_SCROLLBASE_HEIGHT_SMALL	64

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	CGRect frame = [[UIScreen mainScreen] applicationFrame];
	
	CGRect frameScroll = _scrollBaseview.frame;
	CGRect frameZoom = _photoZoomBaseview.frame;
	UIWindow* keyWin = [[UIApplication sharedApplication] keyWindow];
	int topInset = [keyWin safeAreaInsets].top;

	if(originalFrameZoomHeight<0) {
		originalFrameZoomHeight = frameZoom.size.height;
	}
	if(originalTopInset<0) {
		originalTopInset = topInset;
	}
	
	switch(fromInterfaceOrientation){
			// ランドスケープになった
		case UIDeviceOrientationPortrait:
			frameScroll.origin.y = 0;
			frameScroll.size.height = D_SCROLLBASE_HEIGHT_SMALL;
			break;
			// ポートレートになった
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			frameScroll.origin.y = topInset;
			frameScroll.size.height = D_SCROLLBASE_HEIGHT_NORMAL;
			break;
		default:
			break;
	}
	frameZoom.size.height = frame.size.height-frameScroll.size.height-frameScroll.origin.y;
	frameZoom.size.width = frame.size.width;
	frameZoom.origin.y = frameScroll.origin.y+frameScroll.size.height;

	_scrollBaseview.frame = frameScroll;
	_photoZoomBaseview.frame = frameZoom;

	CGRect rct = frameScroll;
	rct.origin.y = 0;
	rct.origin.x = 0;
	_scrollContentView.frame = rct;

	[self lineupPhotoAround];

	[UIView animateWithDuration:0.1f
						  delay:0.0f
						options:UIViewAnimationOptionCurveEaseIn
					 animations:^{
						_scrollBaseview.alpha = 1;
						_photoZoomBaseview.alpha = 1;
					 } completion:^(BOOL finished) {
					 }];

}

- (void)orientationJob
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
}

int timerJobCount = 0;

- (void)timerJob
{
	NSLog(@"### timerJOB");
	[self refreshTask];
	[self updateChartData];

	
	timerJobCount++;
	[ShareData setObject:[NSNumber numberWithInt:timerJobCount] forKey:@"timerJobCount"];

	[self displayDataValues];
}

- (void)displayDataValues
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSNumber* timerJobNumber = [ShareData objectForKey:@"timerJobCount"];
		NSNumber* healthkitNofityNumber = [ShareData objectForKey:@"healthkitNofityCount"];
		NSNumber* getBloodGlucoseNumber = [ShareData objectForKey:@"getBloodGlucoseCount"];
		NSNumber* notifyToWatchNumber = [ShareData objectForKey:@"notifyToWatchCount"];
		NSNumber* backgroundNumber = [ShareData objectForKey:@"backgroundCount"];
		
		NSString* infoStr = [NSString stringWithFormat:@"timer%d getCGM%d toWatch%d bg%d HKNotify%d",
							 [timerJobNumber intValue],
							 [getBloodGlucoseNumber intValue],
							 [notifyToWatchNumber intValue],
							 [backgroundNumber intValue],
							 [healthkitNofityNumber intValue]
		];
		[_labelInfomation setText:infoStr];

		NSDate* cgmDate = [ShareData objectForKey:@"currentDate"];
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"MM/dd HH:mm";
		NSString* dateString = [dateFormatter stringFromDate:cgmDate];

		NSNumber* cgmNumber = [ShareData objectForKey:@"currentCGM"];
		if([cgmNumber intValue]>0){
			infoStr = [NSString stringWithFormat:@"%d",[cgmNumber intValue]];
			_labelBigDate.hidden=NO;
			_labelBigValue.hidden=NO;
			_labelBigUnit.hidden=NO;
		}
		else {
			infoStr = @"---";
			dateString = @"--/-- --:--";
			_labelBigDate.hidden=YES;
			_labelBigValue.hidden=YES;
			_labelBigUnit.hidden=YES;
		}
		[_labelBigValue setText:infoStr];
		[_labelBigDate setText:dateString];
	});
}

- (void)viewDidDisappear:(BOOL)animated
{
	// SafeAreaの調整（グラフが全部表示されるように）
	UIWindow* keyWin = [[UIApplication sharedApplication] keyWindow];
	int bottomInset =  [keyWin safeAreaInsets].bottom;
	bottomInset *= 1;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (BOOL)prefersHomeIndicatorAutoHidden	// ホームボタン無しiPad対応
{
	return YES;
}


- (void)updateChartData
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self setDataCount:_sliderX.value range:30.0];
	});
}


- (void)setDataCount:(int)count range:(double)range
{
	NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
	NSTimeInterval hourSeconds = 3600.0;
	
	NSMutableArray *values = [[NSMutableArray alloc] init];

	// グラフに表示する値を設定する
	// 　x : 時刻timeIntervalSince1970
	// 　y : プロットする数値（血糖値）
#if 1
	int counts = self.glucoseValue.count;
	if(counts<=0){
		return;
	}
	NSDictionary *entry = self.glucoseValue[counts/2];
	NSDate *dt = [entry objectForKey:@"DateTime"];
	NSTimeInterval t = [dt timeIntervalSince1970];
	NSNumber *num;
	double ymax = 0;

#if 0
	// 全データをプロット
	for (int i = 0; i < counts; i++)
	{
		entry = self.glucoseValue[i];
		dt = [entry objectForKey:@"DateTime"];
		num = [entry objectForKey:@"glucoseValue"];
		double glu = [num doubleValue];
		ymax = (ymax<glu?glu:ymax);
		t = [dt timeIntervalSince1970];
		[values addObject:[[ChartDataEntry alloc] initWithX:t y:glu]];
	}
#else
	// 移動平均
	int aveCount = _sliderX.value;
	for(int i=0; i<counts; i+=aveCount){
		int startIdx = i-aveCount/2;
		if(startIdx<0) startIdx = 0;
		int endIdx   = startIdx+aveCount;
		if(counts<endIdx) endIdx = counts-1;

		int sumCount = 0;
		double ysum = 0;
		entry = self.glucoseValue[endIdx-1];
		dt = [entry objectForKey:@"DateTime"];
		t = [dt timeIntervalSince1970];
		for(int index=startIdx; index<endIdx; index++){
			entry = self.glucoseValue[i];
			num = [entry objectForKey:@"glucoseValue"];
			double glu = [num doubleValue];
			ysum += glu;
			ymax = (ymax<glu?glu:ymax);
			sumCount++;
		}
		double movingave = ysum / sumCount;
		[values addObject:[[ChartDataEntry alloc] initWithX:t y:movingave]];
	}
#endif
	
	ChartXAxis *xAxis = _chartView.xAxis;
	xAxis.granularity = 3600.0*4;	// 4時間

	ChartYAxis *leftAxis = _chartView.leftAxis;
	leftAxis.axisMinimum = 50.0;
	leftAxis.axisMaximum = ymax*1.5;
//	leftAxis.axisMaximum = 500.0;
	leftAxis.yOffset = -30.0-20;
#else
	NSTimeInterval from = now - (count / 2.0) * hourSeconds;
	NSTimeInterval to = now + (count / 2.0) * hourSeconds;
	for (NSTimeInterval x = from; x < to; x += hourSeconds)
	{
		double y = arc4random_uniform(range) + 50;
		[values addObject:[[ChartDataEntry alloc] initWithX:x y:y]];
	}
#endif
	
	LineChartDataSet *set1 = nil;
	if (_chartView.data.dataSetCount > 0)
	{
		set1 = (LineChartDataSet *)_chartView.data.dataSets[0];
		[set1 replaceEntries: values];
		[_chartView.data notifyDataChanged];
		[_chartView notifyDataSetChanged];
	}
	else
	{
		// エントリー → データセット → データ → ChartViewにセット
		
		set1 = [[LineChartDataSet alloc] initWithEntries:values label:@"DataSet 1"];
		set1.axisDependency = AxisDependencyLeft;
//		set1.valueTextColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
		set1.lineWidth = 2;
		set1.drawCirclesEnabled = NO;
		set1.drawCircleHoleEnabled = NO;
		set1.drawValuesEnabled = NO;
		set1.drawFilledEnabled=YES;
		set1.mode = LineChartModeHorizontalBezier;
//		set1.mode = LineChartModeCubicBezier;
		set1.fillAlpha = 0.3;
		set1.fillColor = [UIColor colorWithRed:51/255.0 green:181/255.0 blue:229/255.0 alpha:1.0];
		set1.highlightColor = [UIColor colorWithRed:224/255.0 green:117/255.0 blue:117/255.0 alpha:1.0];
		
		
		NSMutableArray *dataSets = [[NSMutableArray alloc] init];
		[dataSets addObject:set1];
		
		LineChartData *data = [[LineChartData alloc] initWithDataSets:dataSets];
		[data setValueTextColor:UIColor.whiteColor];
		[data setValueFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12.0]];
		
		_chartView.data = data;
		
		[_chartView.data notifyDataChanged];
		[_chartView notifyDataSetChanged];

	}
}


- (void)optionTapped:(NSString *)key
{
}


#pragma mark - Actions

- (void)photoTapped:(UIGestureRecognizer *)sender {
	if (sender.state == UIGestureRecognizerStateEnded){
		_photoZoomBackgroundView.alpha = 0;
		_photoZoomContentView.alpha = 0;
		_photoZoomBaseview.hidden=NO;
		_photoCloseButton.alpha=0;
		_photoCloseButton.hidden=NO;
		_labelPhotoDate.alpha = 0;

		_scrollBaseview.zoomScale = 1;

		UITapGestureRecognizer* recognizer = (UITapGestureRecognizer*)sender;
		UIImageView* tappedImageView = (UIImageView*)recognizer.view;
		_photoZoomContentView.image = tappedImageView.image;
		int photoIndex = tappedImageView.tag;

		PhotoInfo* photoInfo = [self.photoInfoArray objectAtIndex:photoIndex];
		NSDate* photoCreatedDate = photoInfo.createdDate;
		NSLog(@"photoCreatedDate=%@", photoCreatedDate);
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"MM/dd HH:mm";
		NSString *dateString = [dateFormatter stringFromDate:photoCreatedDate];
		_labelPhotoDate.text = dateString;

		// アニメーション
		[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^ {
			_photoZoomBackgroundView.alpha = 1;
			_photoZoomContentView.alpha = 1;
			_photoCloseButton.alpha = 1;
			_labelPhotoDate.alpha = 1;
		} completion:^(BOOL finished) {
		}];
	}
}

- (IBAction)photoCloseButtonClicked:(id)sender
{
	_photoCloseButton.alpha=0;
	// アニメーション
	[UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^ {
		_photoZoomBackgroundView.alpha = 0;
		_photoZoomContentView.alpha = 0;
		_labelPhotoDate.alpha = 0;
	} completion:^(BOOL finished) {
		_photoZoomContentView.image = nil;
		_photoZoomBaseview.hidden = YES;
	}];
}

- (IBAction)logToggleButtonClicked:(id)sender
{
	_textviewLog.hidden = (_textviewLog.hidden?NO:YES);
	_labelInfomation.hidden = _textviewLog.hidden;
}

- (IBAction)slidersValueChanged:(id)sender
{
	_sliderTextX.text = [@((int)_sliderX.value) stringValue];
	
	[self updateChartData];
}

#pragma mark - ChartViewDelegate

NSDate* currentSelectedDate = nil;

- (void)chartValueSelected:(ChartViewBase * __nonnull)chartView entry:(ChartDataEntry * __nonnull)entry highlight:(ChartHighlight * __nonnull)highlight
{
//	NSLog(@"entry:%@", entry);
//	NSLog(@"highlight:%@", highlight);
//	NSLog(@"x=%f,y=%f", highlight.xPx,highlight.yPx);	// タッチ座標
	
	NSTimeInterval t = highlight.x;
	NSDate *dt = [NSDate dateWithTimeIntervalSince1970:t];
	currentSelectedDate = dt;
	double glu = highlight.y;

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateFormat = @"MM/dd HH:mm";
	NSString *dateString = [dateFormatter stringFromDate:dt];
	_labelEntryDate.text = dateString;
	_labelGluValue.text = [NSString stringWithFormat:@"%.0fmg/dL", glu];
	
//	NSLog(@"glu:%f, dt=%@", glu, dt);

	[self lineupPhotoAround];

	// タップで円形のアニメーション
	[circleLayer removeFromSuperlayer];
	CAKeyframeAnimation *animation = [CAKeyframeAnimation new];
	[animation valueForKeyPath:@"opacity"];
	animation.duration = 1;
	animation.keyTimes = @[@0.0,@0.5,@1.0];
	animation.values = @[@1.0,@0.0,@1.0];
	animation.repeatCount = CGFLOAT_MAX;
	
	circleLayer = [CAShapeLayer new];
	UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(highlight.xPx, highlight.yPx) radius:20 startAngle:0 endAngle:M_PI*2 clockwise:YES];
	circleLayer.path = circlePath.CGPath;
	circleLayer.strokeColor = (__bridge CGColorRef _Nullable)([UIColor redColor]);
	circleLayer.fillColor = (__bridge CGColorRef _Nullable)([UIColor clearColor]);
	circleLayer.lineWidth = 2.0;
	[circleLayer addAnimation:animation forKey:nil];
	[chartView.layer addSublayer:circleLayer];
}

- (void)chartValueNothingSelected:(ChartViewBase * __nonnull)chartView
{
	NSLog(@"chartValueNothingSelected");
	_labelEntryDate.text = @"--/-- --:--";
	_labelGluValue.text = @"mg/dL";
}


// MARK: - Blood Glucose
int healthkitNofityCount = 0;
/*
- (void)registerBloodGlucoseObserver
{
	HKHealthStore* healthStore = [HKHealthStore new];
	HKObjectType *tempType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];
	NSSortDescriptor *endDate = [NSSortDescriptor sortDescriptorWithKey: HKSampleSortIdentifierEndDate ascending: NO];

	HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose]
														   predicate: nil
															   limit: 0
													 sortDescriptors: @[endDate]
													  resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error)
	{
		NSLog(@"%@", results);
	}];

	HKObserverQuery* observerQuery = [[HKObserverQuery alloc] initWithSampleType:tempType
																	   predicate:nil
															 updateHandler:^(HKObserverQuery *query, HKObserverQueryCompletionHandler completionHandler, NSError *error) {
		
		if (error){
			NSLog(@"Error observing changes to HKSampleType with identifier %@: %@", query.sampleType.identifier, error.localizedDescription);
		}
		else {
			// [healthStore executeQuery:sampleQuery];
			healthkitNofityCount++;
			[ShareData setObject:[NSNumber numberWithInt:healthkitNofityCount] forKey:@"healthkitNofityCount"];
			[self getBloodGlucose];
		}
		completionHandler();
	}];

	[healthStore enableBackgroundDeliveryForType:[HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose] frequency:HKUpdateFrequencyImmediate withCompletion:^(BOOL success, NSError *error) {
		if (success)
		{
		//	[self setupObserver];
		}
	}];
}
*/

- (void)healthKitNotifyJob
{
	healthkitNofityCount++;
	[ShareData setObject:[NSNumber numberWithInt:healthkitNofityCount] forKey:@"healthkitNofityCount"];
	[self getBloodGlucose];
	[self updateChartData];
	[self displayDataValues];
	
	[self checkGlucoseValueRange];
}

int getBloodGlucoseCount = 0;
double latestCGMValue = 100;

- (void)checkGlucoseValueRange
{
	dispatch_async(dispatch_get_main_queue(), ^{
		if(latestCGMValue<CGM_MIN_VAL) {
			appDelegate = [UIApplication sharedApplication].delegate;
			[appDelegate requestNotifyMessage:@"血糖値アラーム" detailMessage:[NSString stringWithFormat:@"低血糖です %.0f", latestCGMValue]];
		}
		if(CGM_MAX_VAL<latestCGMValue) {
			appDelegate = [UIApplication sharedApplication].delegate;
			[appDelegate requestNotifyMessage:@"血糖値アラーム" detailMessage:[NSString stringWithFormat:@"高血糖です %.0f", latestCGMValue]];
		}
   });
}

- (void)getBloodGlucose {
	
	[self.glucoseValue removeAllObjects];
	
#if !TARGET_OS_SIMULATOR
	NSInteger limit = 0;
	NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-24*60*60*D_CHECK_DAYS];
	NSPredicate* predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:[NSDate date] options:HKQueryOptionStrictStartDate];;
	NSString *endKey =  HKSampleSortIdentifierEndDate;
	NSSortDescriptor *endDate = [NSSortDescriptor sortDescriptorWithKey: endKey ascending: YES];
	HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType: [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose]
														   predicate: predicate
															   limit: limit
													 sortDescriptors: @[endDate]
													  resultsHandler:^(HKSampleQuery *query, NSArray* results, NSError *error)
							{
								dispatch_async(dispatch_get_main_queue(), ^{
								//	NSLog(@"BloodGlucose=%@",results);

									if([results count]>0){
										//NSMutableArray *arrBGL=[NSMutableArray new];
										// シミュレータ用のサンプルデータ書き出し用
									//	NSLog(@"==========");
									//	NSLog(@"==========");
										NSString *tStr = @"";
										NSString *gStr = @"";
										
										currentCGM = 0;
										for (HKQuantitySample *quantitySample in results) {
											HKQuantity *quantity = [quantitySample quantity];
											double bloodGlucose_mg_per_dL = [quantity doubleValueForUnit:[[HKUnit gramUnit] unitDividedByUnit:[HKUnit literUnit]]];
											bloodGlucose_mg_per_dL *= 100;	// mg/dLに合わせる
											NSNumber *gluValue = [NSNumber numberWithDouble:bloodGlucose_mg_per_dL];
											NSDate *endDate = [quantitySample endDate];
											NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
											  endDate, @"DateTime",
											  gluValue,@"glucoseValue",
											nil];
											[self.glucoseValue addObject:dic];
											
											NSTimeInterval tt = [endDate timeIntervalSince1970];
											double gluglu = bloodGlucose_mg_per_dL;
											latestCGMValue = gluglu;
											tStr = [NSString stringWithFormat:@"%@,@%.0f", tStr,tt];
											gStr = [NSString stringWithFormat:@"%@,@%.0f", gStr,gluglu];
											//NSLog(@"%@",[NSString stringWithFormat:@"%.fmg/dL(%@)",bloodGlucose_mg_per_dL, endDate]);
											currentCGM = bloodGlucose_mg_per_dL;	// 最新値
											currentDate = endDate;
										}
										[self sendCGMtoWatch:currentCGM datetime:currentDate];
									// シミュレータ用のサンプルデータ書き出し用　→　SampleData.hへコピー＆ペーストして使用する
									//	NSLog(@"%@",tStr);
									//	NSLog(@"%@",gStr);
									//	NSLog(@"==========");
									//	NSLog(@"==========");
									}
								});
							}];

	[self.healthStore executeQuery:query];
#else
// デバッグ用（シミュレータ用）
	// SampleData.h内のデータをヘルスキットのデータの代わりに使ってシミュレート
	currentCGM = 0;
	for(int i=0; i<timeDataSample.count; i++){
		NSNumber* numt = timeDataSample[i];
		NSTimeInterval t = numt.doubleValue;
		NSNumber* numg = gluDataSample[i];
		double glu = numg.doubleValue;
		NSNumber *gluValue = [NSNumber numberWithDouble:glu];
		NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:t];
		NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
		  endDate, @"DateTime",
		  gluValue,@"glucoseValue",
		nil];
		[self.glucoseValue addObject:dic];

		currentCGM = [gluValue doubleValue];
		currentTime = endDate;
	}
	[self sendCGMtoWatch:currentCGM datetime:currentTime];
#endif

	getBloodGlucoseCount++;
	[ShareData setObject:[NSNumber numberWithInt:getBloodGlucoseCount] forKey:@"getBloodGlucoseCount"];
}


// MARK: - Photo

- (void)lineupPhotoAround
{
	if(currentSelectedDate){
		int minWidthBefore = D_MINUTES_WIDTH_BEFORE;
		int minWidthAfter  = D_MINUTES_WIDTH_AFTER;
		[self getPhotoAround:currentSelectedDate minutesWidthBefore:minWidthBefore minutesWidthAfter:minWidthAfter];
	}
}

// 指定日時前後数分の写真を集める
- (void)getPhotoAround:(NSDate*)centerDate minutesWidthBefore:(int)minutesWidthBefore minutesWidthAfter:(int)minutesWidthAfter
{
	[self clearPhotoInfos];

	// 作成日でソート
	PHFetchOptions *fetchOptions = [PHFetchOptions new];
	fetchOptions.sortDescriptors = @[
		[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]	// 写真の撮影順に並べる
	];
	// 集める写真の撮影日の範囲を設定
	NSDate *startDate, *endDate;
	startDate = [centerDate initWithTimeInterval:-minutesWidthBefore*60 sinceDate:centerDate];
	endDate   = [centerDate initWithTimeInterval:+minutesWidthAfter*60 sinceDate:centerDate];
	fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate > %@ AND creationDate < %@", startDate, endDate];

	// 写真を収集
	PHFetchResult *assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];

	if(assets.count>0) {
		self.scrollBaseview.hidden=NO;
		// 写真クラスを生成して配列へ
		for(int i=0; i<assets.count; i++){
			PHAsset* asset = assets[i];
			PhotoInfo* pInfo = [[PhotoInfo alloc] initWithAsset:asset number:i];
			[self addPhotoInfo:pInfo];
		}
	}
	else {
		self.scrollBaseview.hidden=YES;
	}
}

- (void)clearPhotoInfos
{
	for(UIView *view in [self.scrollContentView subviews]){
		[view removeFromSuperview];
	}
	[self.photoInfoArray removeAllObjects];
	self.scrollBaseview.hidden=YES;
}

- (void)addPhotoInfo:(PhotoInfo*)photoInfo
{
	//NSLog(@"addPhotoInfo");
	[self.photoInfoArray addObject:photoInfo];

	UIScrollView* sView = (UIScrollView*)self.scrollBaseview;
	UIView* contentView = self.scrollContentView;

	CGSize baseSize = contentView.frame.size;
	double sz = (baseSize.width<baseSize.height?baseSize.width:baseSize.height);	// 短い方
	sz -= D_THUMBNAIL_MARGIN*2;
	// UIImageView生成
	CGRect rect = CGRectMake(D_THUMBNAIL_MARGIN+photoInfo.index*(sz+D_THUMBNAIL_MARGIN*2), D_THUMBNAIL_MARGIN, sz, sz);
	UIImageView* imgView = [UIImageView new];
	photoInfo.baseimageView = imgView;
	imgView.tag = photoInfo.index;
	imgView.contentMode = UIViewContentModeScaleAspectFill;
	imgView.hidden=NO;
	imgView.frame = rect;
	[contentView addSubview:imgView];

	// イメージのタップハンドリング
	UITapGestureRecognizer *singleFingerDTap = [[UITapGestureRecognizer alloc]
												initWithTarget:self action:@selector(photoTapped:)];
	[imgView addGestureRecognizer:singleFingerDTap];
	imgView.userInteractionEnabled=YES;

	double wid = (photoInfo.index+1)*(sz+D_THUMBNAIL_MARGIN*2);
//	double wid = ((photoInfo.index+1)*(sz+D_THUMBNAIL_MARGIN*2)<contentView.frame.size.width?contentView.frame.size.width:(photoInfo.index+1)*(sz+D_THUMBNAIL_MARGIN*2));
	CGSize size = CGSizeMake(wid, sz+D_THUMBNAIL_MARGIN*2);
	CGRect frame = contentView.frame;
	frame.size = size;
	contentView.frame = frame;

	[sView setContentSize:contentView.frame.size];
	[sView flashScrollIndicators];
}

// MARK: - Apple Watch

- (void)initializeWatchJob
{
	shareList = [[NSMutableArray alloc] initWithCapacity:1];
	[ShareData saveSharedList:shareList];
	
	[ShareData setObject:[NSNumber numberWithDouble:0.0] forKey:@"currentCGM"];
	[ShareData setObject:[NSDate now] forKey:@"currentDate"];

	// 情報が更新された時のアプリ内通知を登録
	[appDelegate registerLifeLogAddNotificationTo:self selector:@selector(myTurn)];
}

- (void)refreshTask {
	NSLog(@"refreshTask VC");
	[self getBloodGlucose];
}

- (IBAction)shootButtonPushed:(id)sender {

	[self sendDataToWatch];
}

- (void)sendCGMtoWatch:(double)valueCGM datetime:(NSDate*)datetime
{
	// 最新のCGM値をShare領域に格納する
	[ShareData setObject:[NSNumber numberWithDouble:valueCGM] forKey:@"currentCGM"];
	[ShareData setObject:currentDate forKey:@"currentDate"];
	[self sendDataToWatch];
}

- (void)sendDataToWatch {

	// 現在時刻を追加
	[shareList addObject:[NSDate new]];
	// 共有コンテナに保存
	[ShareData saveSharedList:shareList];
	// Watchへ通知
	[self notifyToWatch];
}

// Watchに通知
int notifyToWatchCount = 0;

- (void)notifyToWatch {
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)GLOBAL_NOTIFY_NAME, (__bridge const void *)(self), NULL, YES);
	
	NSLog(@"### notifyToWatch:CGM%.0f date:%@", currentCGM, currentDate);
	NSMutableDictionary* dict = [NSMutableDictionary new];
	[dict setValue:[NSNumber numberWithDouble:currentCGM] forKey:@"currentCGM"];
	[dict setValue:currentDate forKey:@"currentDate"];

	[[WCSession defaultSession] sendMessage:dict
							   replyHandler:^(NSDictionary *replyHandler) {
									NSLog(@"SendMessage SUCCESS");
							   }
							   errorHandler:^(NSError *error) {
									NSLog(@"SendMessage ERROR. Try to transferUserInfo");
									[[WCSession defaultSession] transferUserInfo:dict];
							   }
	 ];

	notifyToWatchCount++;
	[ShareData setObject:[NSNumber numberWithInt:notifyToWatchCount] forKey:@"notifyToWatchCount"];
}

// Watchから通知が到着
- (void)notifyFromWatch {
	// ShareDataの中身をチェックする
}


// MARK: - Logging

- (void)logging:(NSString*)logmessage
{
	NSString* msg = self.textviewLog.text;
	msg = [NSString stringWithFormat:@"%@\n%@", logmessage,msg];
	[self.textviewLog setText:msg];
}

- (void)loggingWithClear:(NSString*)logmessage
{
	[self.textviewLog setText:logmessage];
}

@end


