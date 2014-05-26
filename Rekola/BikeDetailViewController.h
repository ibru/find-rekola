//
//  BikeDetailViewController.h
//  Rekola
//
//  Created by Jiri Urbasek on 26/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMLAbstractGeometry.h"


@class BikeDetailViewController;
@protocol BikeDetailViewControllerDelegate <NSObject>
- (void)detailController:(BikeDetailViewController *)controller didAddGeometryToFavorites:(KMLAbstractGeometry *)geometry;
- (void)detailController:(BikeDetailViewController *)controller didRemoveGeometryFromFavorites:(KMLAbstractGeometry *)geometry;
@end

@interface BikeDetailViewController : UIViewController

@property (nonatomic, strong) KMLAbstractGeometry *geometry;
@property (nonatomic, assign) BOOL isGeometryInFavorites;

@property (nonatomic, weak) id<BikeDetailViewControllerDelegate> delegate;

@end
