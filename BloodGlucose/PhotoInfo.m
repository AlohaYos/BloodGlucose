//
//  PhotoInfo.m
//  BloodGlucose
//
//  Created by Yos Hashimoto on 2022/02/27.
//

#import "PhotoInfo.h"

@implementation PhotoInfo

- (id)initWithAsset:(PHAsset*)asset_ number:(int)indexNumber {
	
	self.index = indexNumber;
	self.asset = asset_;
	self.createdDate = asset_.creationDate;

	self.photoReady = NO;
	self.baseimageView = nil;
	[self getAssetImage];
	
	return self;
}

- (void)getAssetImage
{
	__weak  typeof(self) weakSelf = self;

	PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
	options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

	[[PHImageManager defaultManager] requestImageForAsset:_asset
					   targetSize:CGSizeMake(1000,1000)
					  contentMode:PHImageContentModeAspectFit
						  options:options
					resultHandler:^(UIImage *result, NSDictionary *info) {
						if (result) {
							dispatch_async(
								dispatch_get_main_queue(),
								^{
									weakSelf.image = result;
									[weakSelf.baseimageView setImage:result];
									[weakSelf.baseimageView setNeedsDisplay];
									weakSelf.photoReady = YES;
								}
							);
						}
					}];

}

- (void)setImageView:(UIImageView*)imgView
{
	self.baseimageView = imgView;
}

@end
