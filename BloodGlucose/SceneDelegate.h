//
//  SceneDelegate.h
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/23.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "ShareData.h"

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
{
	AppDelegate* appDelegate;
	NSMutableArray *shareList;	// iPhoneとWatchで共有するデータ
}

@property (strong, nonatomic) UIWindow * window;

@end

