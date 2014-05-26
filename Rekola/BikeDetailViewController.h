//
//  BikeDetailViewController.h
//  Rekola
//
//  Created by Jiri Urbasek on 26/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMLAbstractGeometry.h"


@interface BikeDetailViewController : UIViewController

@property (nonatomic, strong) KMLAbstractGeometry *geometry;

@end
