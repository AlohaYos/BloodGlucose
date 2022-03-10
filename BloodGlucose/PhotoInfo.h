//
//  PhotoInfo.h
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface PhotoInfo : NSObject

@property (nonatomic, assign) int index;
@property (nonatomic, assign) bool photoReady;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) UIImageView* baseimageView;	// imageを貼り付けるView（設定されていない時はnil）
@property (nonatomic, strong) NSDate*  createdDate;
@property (nonatomic, strong) PHAsset* asset;	// 一時作業用

- (id)initWithAsset:(PHAsset*)asset_ number:(int)indexNumber;
- (void)getAssetImage;
- (void)setImageView:(UIImageView*)imgView;

@end

NS_ASSUME_NONNULL_END
