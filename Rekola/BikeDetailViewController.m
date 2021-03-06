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
#import "MKMap+KML.h"
#import "KML.h"


static NSString *const kExtendedDataKeyIssues   = @"issues";
static NSString *const kExtendedDataKeyCity     = @"city";
static NSString *const kExtendedDataKeyAddress  = @"address";


@interface BikeDetailViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *issuesLabel;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;

@end

@implementation BikeDetailViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    KMLPlacemark *placemark = self.geometry.placemark;
    
    self.title = placemark.name;
    
    [self updateMapRegion];
    
    [self updateDistanceFromUsersLocation];
    
    NSString *description = [placemark.descriptionValue stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
    self.descriptionLabel.text = description;
    
    
    self.addressLabel.text = NSLocalizedString(@"Address is unknown", @"");
    self.issuesLabel.text = NSLocalizedString(@"No issues with the bike", @"");
    
    [placemark.extendedData.dataList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[KMLData class]])
            return;
        
        KMLData *data = (KMLData *)obj;
        
        if ([data.name isEqual:kExtendedDataKeyAddress] && [data.value length])
            self.addressLabel.text = data.value;
        
        else if ([data.name isEqual:kExtendedDataKeyIssues] && [data.value length])
                self.issuesLabel.text = data.value;
    }];
    
    
    [self updateFavoriteButtonState];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    [self updateDistanceFromUsersLocation];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    else if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPointAnnotation *pointAnnotation = (MKPointAnnotation *)annotation;
        return [pointAnnotation annotationViewForMapView:mapView];
    }
    
    return nil;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        return [(MKPolyline *)overlay overlayViewForMapView:mapView];
    }
    else if ([overlay isKindOfClass:[MKPolygon class]]) {
        return [(MKPolygon *)overlay overlayViewForMapView:mapView];
    }
    
    return nil;
}

#pragma mark Private

- (void)updateMapRegion
{
    MKShape *mkShape = [self.geometry mapkitShape];
    if (mkShape) {
        if ([mkShape conformsToProtocol:@protocol(MKOverlay)]) {
            [self.mapView addOverlay:(id<MKOverlay>)mkShape];
        }
        else if ([mkShape isKindOfClass:[MKPointAnnotation class]]) {
            [self.mapView addAnnotation:mkShape];
        }
    }
    MKMapRect zoomRect = MKMapRectNull;
    CLLocation *location = [self.geometry location];
    MKMapPoint annotationPoint = MKMapPointForCoordinate(location.coordinate);
    MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1000, 1000);
    
    zoomRect = pointRect;
    
    // include users location into map visible area
    annotationPoint = MKMapPointForCoordinate(self.mapView.userLocation.coordinate);
    pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 1000, 1000);
    zoomRect = MKMapRectUnion(zoomRect, pointRect);
    
    double extraZoom = 0.005;
    MKCoordinateRegion region = MKCoordinateRegionForMapRect(zoomRect);
    region.span.latitudeDelta += extraZoom;
    region.span.longitudeDelta += extraZoom;
    
    [self.mapView setRegion:region animated:YES];
}

- (void)updateDistanceFromUsersLocation
{
    CLLocationDistance meters = [self.mapView.userLocation.location distanceFromLocation:[self.geometry location]];
    
    NSString *distance = [NSString stringWithFormat:@"%d m", (int)ceil(meters)];
    if (meters > 1000)
        distance = [NSString stringWithFormat:@"%.1f km", meters/1000];
    
    self.distanceLabel.text = distance;
}

- (void)updateFavoriteButtonState
{
    if (!self.isGeometryInFavorites)
        [self.favoriteButton setTitle:NSLocalizedString(@"Add to favorites", @"") forState:UIControlStateNormal];
    else
        [self.favoriteButton setTitle:NSLocalizedString(@"Remove from favorites", @"") forState:UIControlStateNormal];
}

#pragma mark -- actions

- (IBAction)favoriteButtonTouched:(id)sender
{
    if (!self.isGeometryInFavorites) {
        if ([self.delegate respondsToSelector:@selector(detailController:didAddGeometryToFavorites:)])
            [self.delegate detailController:self didAddGeometryToFavorites:self.geometry];
        
        self.isGeometryInFavorites = YES;
    }
    else {
        if ([self.delegate respondsToSelector:@selector(detailController:didRemoveGeometryFromFavorites:)])
            [self.delegate detailController:self didRemoveGeometryFromFavorites:self.geometry];
        
        self.isGeometryInFavorites = NO;
    }
    [self updateFavoriteButtonState];
}


@end
