//
//  ComplicationController.m
//  WatchCGM WatchKit Extension
//
//  Created by Yos Hashimoto on 2022/03/05.
//

#import "ComplicationController.h"
#import "ShareData.h"
#import "Common.h"

#define	D_COMPLICATION_UPDATE_INTERVAL	10
//#define CGM_MIN_VAL	70
//#define CGM_MAX_VAL	220
#define CGM_START_VAL	100

@implementation ComplicationController

#pragma mark - Complication Configuration

- (void)getComplicationDescriptorsWithHandler:(void (^)(NSArray<CLKComplicationDescriptor *> * _Nonnull))handler {
    NSArray<CLKComplicationDescriptor *> *descriptors = @[
        [[CLKComplicationDescriptor alloc] initWithIdentifier:@"complication"
                                                  displayName:@"BloodGlucose"
                                            supportedFamilies:CLKAllComplicationFamilies()]
        // Multiple complication support can be added here with more descriptors
    ];
    
    // Call the handler with the currently supported complication descriptors
    handler(descriptors);
}

- (void)handleSharedComplicationDescriptors:(NSArray<CLKComplicationDescriptor *> *)complicationDescriptors {
    // Do any necessary work to support these newly shared complication descriptors
}

#pragma mark - Timeline Configuration

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
    // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
    // Call the handler with your desired behavior when the device is locked
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
    // Call the handler with the current timeline entry

	NSDate* date = [NSDate now];
	CLKComplicationTemplate* template = [self getComplicationTemplate:complication date:date];
	CLKComplicationTimelineEntry* entry = [CLKComplicationTimelineEntry entryWithDate:date complicationTemplate:template];
	
	// コンプリケーション更新タイマー（強制的）
	NSLog(@"### Did update complication");
	int update_interval = D_COMPLICATION_UPDATE_INTERVAL;
	dispatch_time_t interval = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(update_interval * NSEC_PER_SEC));
	dispatch_after(interval, dispatch_get_main_queue(), ^{
		CLKComplicationServer* server = [CLKComplicationServer sharedInstance];
		for(CLKComplication *comp in server.activeComplications) {
			NSLog(@"### Prepare for next complication update");
			[server reloadTimelineForComplication:comp];
		}
	});
	
    handler(entry);
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
    // Call the handler with the timeline entries after the given date
    handler(nil);
}

#pragma mark - Sample Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
    // This method will be called once per supported complication, and the results will be cached

	CLKComplicationTemplate* comp = [self getComplicationTemplate:complication date:[NSDate now]];
	
    handler(comp);
}

#pragma mark - Build Complication Templates

int complicationUpdateCount = 0;

- (CLKComplicationTemplate*)getComplicationTemplate:(CLKComplication*)complication date:(NSDate*)date
{
	// 配置の参考 https://programmerstart.com/article/9322542763/
	
	switch(complication.family){
		case CLKComplicationFamilyCircularSmall:
		{
			CLKSimpleTextProvider* provider = [CLKSimpleTextProvider alloc];
			[provider initWithText:@"Yoshiyuki" shortText:@"YOS"];
			CLKComplicationTemplateCircularSmallRingText* template;
			template = [[CLKComplicationTemplateCircularSmallStackText alloc] initWithLine1TextProvider:provider line2TextProvider:provider];
			template.tintColor = [UIColor redColor];
			return template;
		}
			break;
		case CLKComplicationFamilyExtraLarge:
		{
			CLKSimpleTextProvider* provider = [CLKSimpleTextProvider alloc];
			[provider initWithText:@"Yos"];
			CLKComplicationTemplateExtraLargeSimpleText* template;
			template = [[CLKComplicationTemplateExtraLargeSimpleText alloc] initWithTextProvider:provider];
			return template;
		}
			break;
		case CLKComplicationFamilyModularSmall:
		{
			CLKSimpleTextProvider* provider = [CLKSimpleTextProvider alloc];
			[provider initWithText:@"Yos"];
			CLKComplicationTemplateModularSmallSimpleText* template;
			template = [[CLKComplicationTemplateModularSmallSimpleText alloc] initWithTextProvider:provider];
			return template;
		}
			break;
		case CLKComplicationFamilyModularLarge:
		{
			CLKSimpleTextProvider* header = [CLKSimpleTextProvider alloc];
			CLKSimpleTextProvider* body1  = [CLKSimpleTextProvider alloc];
			CLKSimpleTextProvider* body2  = [CLKSimpleTextProvider alloc];
			[header initWithText:@"head"];
			[body1  initWithText:@"body1"];
			[body2  initWithText:@"body2"];
			CLKComplicationTemplateModularLargeStandardBody* template;
			template = [[CLKComplicationTemplateModularLargeStandardBody alloc] initWithHeaderTextProvider:header body1TextProvider:body1 body2TextProvider:body2];
			return template;
		}
			break;
		case CLKComplicationFamilyUtilitarianSmall:
		{
			return nil;
			CLKImageProvider* provider = [CLKImageProvider new];
			CLKComplicationTemplateUtilitarianSmallSquare* template;
			template = [[CLKComplicationTemplateUtilitarianSmallSquare alloc] initWithImageProvider:provider];;
			return template;
		}
			break;
		case CLKComplicationFamilyUtilitarianSmallFlat:
		{
			return nil;
			CLKSimpleTextProvider* text = [CLKSimpleTextProvider alloc];
			[text initWithText:@"Yos"];
			CLKImageProvider* image = [CLKImageProvider new];
			CLKComplicationTemplateUtilitarianSmallFlat* template;
			template = [[CLKComplicationTemplateUtilitarianSmallFlat alloc] initWithTextProvider:text imageProvider:image];;
			return template;
		}
			break;
		case CLKComplicationFamilyUtilitarianLarge:
		{
			return nil;
			CLKSimpleTextProvider* text = [CLKSimpleTextProvider alloc];
			[text initWithText:@"Yos"];
			CLKImageProvider* image = [CLKImageProvider new];
			CLKComplicationTemplateUtilitarianLargeFlat* template;
			template = [[CLKComplicationTemplateUtilitarianLargeFlat alloc] initWithTextProvider:text imageProvider:image];
			return template;
		}
			break;
		case CLKComplicationFamilyGraphicCorner:
		{
		   complicationUpdateCount++;
		   [ShareData setObject:[NSNumber numberWithInt:complicationUpdateCount] forKey:@"complicationUpdateCount"];

			double cgmMinVal = CGM_MIN_VAL;
			double cgmMaxVal = CGM_MAX_VAL;
			double cgmCurrentVal = CGM_START_VAL;
			cgmCurrentVal = [self currentValueCGM];
			double cv = (cgmCurrentVal-cgmMinVal)/(cgmMaxVal-cgmMinVal);

			NSArray* colorArray = @[[UIColor cyanColor],[UIColor yellowColor],[UIColor redColor] ];
			NSMutableArray* colorLocationArray = [NSMutableArray new];
			[colorLocationArray addObject:[NSNumber numberWithDouble:0.0]];
			[colorLocationArray addObject:[NSNumber numberWithDouble:0.3]];
			[colorLocationArray addObject:[NSNumber numberWithDouble:1.0]];
			CLKSimpleTextProvider* leadingText = [CLKSimpleTextProvider new];
			CLKSimpleTextProvider* tailingText = [CLKSimpleTextProvider new];
			CLKSimpleTextProvider* outerText = [CLKSimpleTextProvider new];

			CLKSimpleGaugeProvider* gaugeProvider;
			if(cgmCurrentVal>0){
				gaugeProvider = [CLKSimpleGaugeProvider gaugeProviderWithStyle:CLKGaugeProviderStyleFill gaugeColors:colorArray gaugeColorLocations:colorLocationArray fillFraction:cv];
#if 1
			   NSString *trendStr = [ShareData objectForKey:@"cgmTrendString"];

				[leadingText initWithText:[self currentDateString]];
				[tailingText initWithText:[self currentTimeString]];
			   [outerText initWithText:[NSString stringWithFormat:@"%.0f%@", cgmCurrentVal, trendStr]];
			   //[outerText initWithText:[NSString stringWithFormat:@"BG%.0f", cgmCurrentVal]];
#else
				[leadingText initWithText:[NSString stringWithFormat:@"%.0f", cgmMinVal]];
				[tailingText initWithText:[NSString stringWithFormat:@"%.0f", cgmMaxVal]];
				[outerText initWithText:[NSString stringWithFormat:@"BG%.0f", cgmCurrentVal]];
#endif
			}
			else {
				gaugeProvider = [CLKSimpleGaugeProvider gaugeProviderWithStyle:CLKGaugeProviderStyleFill gaugeColors:colorArray gaugeColorLocations:colorLocationArray fillFraction:0];

				[leadingText initWithText:@"---"];
				[tailingText initWithText:@"---"];
				[outerText initWithText:@"---"];
			}

			CLKComplicationTemplateGraphicCornerGaugeText* template;
			template = [CLKComplicationTemplateGraphicCornerGaugeText templateWithGaugeProvider:gaugeProvider leadingTextProvider:leadingText trailingTextProvider:tailingText outerTextProvider:outerText];
			return template;
		}
			break;
		case CLKComplicationFamilyGraphicCircular:
		{
			return nil;
			CLKComplicationTemplateGraphicCircularStackText* template;
			template = [CLKComplicationTemplateGraphicCircularStackText new];
			return template;
		}
			break;
		case CLKComplicationFamilyGraphicBezel:
		{
			return nil;
			CLKComplicationTemplateGraphicBezelCircularText* template;
			template = [CLKComplicationTemplateGraphicBezelCircularText new];
			return template;
		}
			break;
		case CLKComplicationFamilyGraphicRectangular:
		{
			return nil;
			CLKComplicationTemplateGraphicRectangularStandardBody* template;
			template = [CLKComplicationTemplateGraphicRectangularStandardBody new];
			return template;
		}
			break;
		default:
			return nil;
	}
	
	return nil;
}

- (void)requestedUpdateDidBegin
{
	NSLog(@"### requestedUpdateDidBegin");
}

- (void)requestedUpdateBudgetExhausted
{
	NSLog(@"### requestedUpdateBudgetExhausted");
}


- (double)currentValueCGM
{
	NSNumber *cgmValue = [ShareData objectForKey:@"currentCGM"];
	double currentCGM = [cgmValue doubleValue];
	NSLog(@"currentCGM=%.0f", currentCGM);
	return currentCGM;
}

- (NSString*)currentDateString
{
	NSString *dateString = @"";

	NSDate *cgmDate = [ShareData objectForKey:@"currentDate"];
	NSLog(@"currentDate=%@", cgmDate);
	if(cgmDate) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"HH";
//		dateFormatter.dateFormat = @"MMdd";
		dateString = [dateFormatter stringFromDate:cgmDate];
	}

	return dateString;
}

- (NSString*)currentTimeString
{
	NSString *dateString = @"";

	NSDate *cgmDate = [ShareData objectForKey:@"currentDate"];
	NSLog(@"currentDate=%@", cgmDate);
	if(cgmDate) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"mm";
//		dateFormatter.dateFormat = @"HHmm";
		dateString = [dateFormatter stringFromDate:cgmDate];
	}

	return dateString;
}

@end




