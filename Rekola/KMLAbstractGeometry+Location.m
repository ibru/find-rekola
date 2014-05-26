//
//  KMLAbstractGeometry+Location.m
//  Rekola
//
//  Created by Jiri Urbasek on 26/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import "KMLAbstractGeometry+Location.h"
#import "KML+MapKit.h"

@implementation KMLAbstractGeometry (Location)

- (CLLocation *)location
{
    MKShape *shape = [self mapkitShape];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:shape.coordinate.latitude
                                                      longitude:shape.coordinate.longitude];
    return location;
}

@end
