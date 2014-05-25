//
//  NearbyBikeCell.m
//  Rekola
//
//  Created by Jiri Urbasek on 25/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import "NearbyBikeCell.h"

@implementation NearbyBikeCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
