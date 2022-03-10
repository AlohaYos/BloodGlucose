//
//  ComplicationController.h
//  WatchCGM WatchKit Extension
//
//  Created by Yos Hashimoto on 2022/03/05.
//

#import <ClockKit/ClockKit.h>

@interface ComplicationController : NSObject <CLKComplicationDataSource>

- (CLKComplicationTemplate*)getComplicationTemplate:(CLKComplication*)complication date:(NSDate*)date;

@end
