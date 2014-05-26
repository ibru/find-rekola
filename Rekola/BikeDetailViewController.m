//
//  BikeDetailViewController.m
//  Rekola
//
//  Created by Jiri Urbasek on 26/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import "BikeDetailViewController.h"
#import "KMLAbstractGeometry+MapKit.h"
#import "KMLAbstractGeometry+Location.h"


@interface BikeDetailViewController ()
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *issuesLabel;

@end

@implementation BikeDetailViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    KMLPlacemark *placemark = self.geometry.placemark;
    
    self.title = placemark.name;
    
    MKShape *mkShape = [self.geometry mapkitShape];
    if (mkShape) {
        if ([mkShape conformsToProtocol:@protocol(MKOverlay)]) {
            [self.mapView addOverlay:(id<MKOverlay>)mkShape];
        }
        else if ([mkShape isKindOfClass:[MKPointAnnotation class]]) {
            [self.mapView addAnnotation:mkShape];
        }
    }
    
    CLLocationDistance meters = [self.mapView.userLocation.location distanceFromLocation:[self.geometry location]];
    
    NSString *distance = [NSString stringWithFormat:@"%d m", (int)ceil(meters)];
    if (meters > 1000)
        distance = [NSString stringWithFormat:@"%.1f km", meters/1000];
    
    self.distanceLabel.text = distance;
    
    NSString *description = [placemark.descriptionValue stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
    self.descriptionLabel.text = description;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private

#pragma mark -- actions

- (IBAction)favoriteButtonTouched:(id)sender
{
    NSString *objectID = self.geometry.placemark.objectID;
    
    if (objectID != nil) {
        NSMutableArray *objectIDs = [[NSUserDefaults standardUserDefaults] arrayForKey:kUserDefaultsFavoritePlacesKey].mutableCopy;
        
        if (objectIDs == nil)
            objectIDs = [NSMutableArray array];
        
        [objectIDs addObject:objectID];
        
        [[NSUserDefaults standardUserDefaults] setObject:objectIDs forKey:kUserDefaultsFavoritePlacesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


@end
