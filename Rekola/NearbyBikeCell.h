//
//  NearbyBikeCell.h
//  Rekola
//
//  Created by Jiri Urbasek on 25/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NearbyBikeCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@end
