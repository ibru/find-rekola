//
//  ViewController.m
//  Rekola
//
//  Created by Jiri Urbasek on 25/05/14.
//  Copyright (c) 2014 Jiri Urbasek. All rights reserved.
//

#import "NearbyBikesViewController.h"
#import "KML.h"
#import "KML+MapKit.h"
#import "MKMap+KML.h"
#import "SVProgressHUD.h"
#import "NearbyBikeCell.h"


static NSString *const kKMLSourceURL        = @"http://moje.rekola.cz/api/bikes/kml";

static NSString *const kCellIdentifier      = @"Nearby Bike Cell";


@interface KMLAbstractGeometry (DistanceCompare)
- (CLLocation *)location;
@end

#pragma mark -

@interface NearbyBikesViewController () <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) KMLRoot *kml;
@property (nonatomic) NSArray *sortedGeometries;
@property (nonatomic) NSArray *filteredGeometries;

@end

#pragma mark -

@implementation NearbyBikesViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sortedGeometries = @[];
    self.filteredGeometries = @[];
    
    self.title = NSLocalizedString(@"Nearby bikes", @"");
    
    [self indicateLoadingFinished];
    [self reloadAllData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark MKMapViewDelegate

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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([view.annotation isKindOfClass:[MKPointAnnotation class]]) {
        MKPointAnnotation *pointAnnotation = (MKPointAnnotation *)view.annotation;
        //[self pushDetailViewControllerWithGeometry:pointAnnotation.geometry];
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sortedGeometries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KMLAbstractGeometry *geometry = self.sortedGeometries[indexPath.row];
    NearbyBikeCell *cell = (NearbyBikeCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    KMLPlacemark *placemark = geometry.placemark;
    
    cell.nameLabel.text = placemark.name;
    
    NSString *description = [placemark.descriptionValue stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    cell.descriptionLabel.text = description;
    
    // compute distance from user's position
    CLLocationDistance meters = [self.mapView.userLocation.location distanceFromLocation:[geometry location]];
    
    NSString *distance = [NSString stringWithFormat:@"%d m", (int)ceil(meters)];
    if (meters > 1000)
        distance = [NSString stringWithFormat:@"%.2f km", meters/1000];
    
    cell.distanceLabel.text = distance;
    
    return cell;
}


#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    KMLAbstractGeometry *geometry = self.sortedGeometries[indexPath.row];
    
    // move to the selected annotation
    MKShape *shape = [geometry mapkitShape];
    
    [self.mapView setCenterCoordinate:shape.coordinate animated:YES];
    if ([shape isKindOfClass:[MKPointAnnotation class]]) {
        [self.mapView selectAnnotation:shape animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    KMLAbstractGeometry *geometry = self.sortedGeometries[indexPath.row];
    
    //[self pushDetailViewControllerWithGeometry:geometry];
}

#pragma mark Public

#pragma mark Private

- (void)reloadAllData
{
    NSURL *url = [NSURL URLWithString:kKMLSourceURL];
    if (url) {
        [self loadKMLAtURL:url withSuccess:^{
            [self reloadMapView];
            [self.tableView reloadData];
        } failure:^(NSError *error) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                message:NSLocalizedString(@"Failed to read the KML file", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
        }];
    }
}


- (void)loadKMLAtURL:(NSURL *)url withSuccess:(void(^)())success failure:(void(^)(NSError *error))failure
{
    [self indicateLoadingStarted];
    
    // remove all annotations and overlays
    NSMutableArray *annotations = @[].mutableCopy;
    [self.mapView.annotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         if (![obj isKindOfClass:[MKUserLocation class]]) {
             [annotations addObject:obj];
         }
     }];
    [self.mapView removeAnnotations:annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    // load new KML
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // observe KML format error
        [[NSNotificationCenter defaultCenter] addObserverForName:kKMLInvalidKMLFormatNotification
                                                          object:nil
                                                           queue:nil
                                                      usingBlock:^(NSNotification *note){
                                                          NSString *description = [[note userInfo] valueForKey:kKMLDescriptionKey];
                                                          NSLog(@"%@", description);
                                                      }
         ];
        
        self.kml = [KMLParser parseKMLAtURL:url];
        
        // remove KML format error observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kKMLInvalidKMLFormatNotification object:nil];
        
        if (self.kml) {
            // save curent url for next load
            NSString *urlString = [url absoluteString];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:urlString forKey:@"url"];
            [defaults synchronize];
            
            self.sortedGeometries = [self.kml.geometries sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                
                if (![obj1 isKindOfClass:[KMLAbstractGeometry class]] || ![obj1 isKindOfClass:[KMLAbstractGeometry class]])
                    return NSOrderedSame;
                
                CLLocationDistance meters1 = [self.mapView.userLocation.location distanceFromLocation:[(KMLAbstractGeometry *)obj1 location]];
                CLLocationDistance meters2 = [self.mapView.userLocation.location distanceFromLocation:[(KMLAbstractGeometry *)obj2 location]];
                
                if (meters1 > meters2)
                    return NSOrderedDescending;
                else if (meters1 < meters2)
                    return NSOrderedAscending;
                return NSOrderedSame;
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self indicateLoadingFinished];
                
                if (success)
                    success();
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self indicateLoadingFinished];
                
                NSError *error = [NSError errorWithDomain:@"KML"
                                                     code:1
                                                 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Could not parse KML because of unknown error", @"")}];
                if (failure)
                    failure(error);
            });
        }
    });
}

- (void)reloadMapView
{
    NSMutableArray *annotations = @[].mutableCopy;
    NSMutableArray *overlays = @[].mutableCopy;
    __block MKMapRect zoomRect = MKMapRectNull;
    
    [self.sortedGeometries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
         KMLAbstractGeometry *geometry = (KMLAbstractGeometry *)obj;
         MKShape *mkShape = [geometry mapkitShape];
         if (mkShape) {
             if ([mkShape conformsToProtocol:@protocol(MKOverlay)]) {
                 [overlays addObject:mkShape];
             }
             else if ([mkShape isKindOfClass:[MKPointAnnotation class]]) {
                 [annotations addObject:mkShape];
             }
             
             // zoom to first 5 places only
             if (idx < 5) {
                 CLLocation *location = [geometry location];
                 MKMapPoint annotationPoint = MKMapPointForCoordinate(location.coordinate);
                 MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
                 
                 if (MKMapRectIsNull(zoomRect)) {
                     zoomRect = pointRect;
                 } else {
                     zoomRect = MKMapRectUnion(zoomRect, pointRect);
                 }
             }
         }
     }];
    
    [self.mapView addAnnotations:annotations];
    [self.mapView addOverlays:overlays];
    
    // set zoom in next run loop.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // include users location into map visible area
        MKMapPoint annotationPoint = MKMapPointForCoordinate(self.mapView.userLocation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
        
        [self.mapView setVisibleMapRect:zoomRect animated:YES];
    });
}

- (void)indicateLoadingStarted
{
    static UIActivityIndicatorView *indicator = nil;
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicator];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)indicateLoadingFinished
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(refreshButtonTouched:)];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -- actions

- (void)refreshButtonTouched:(id)sender
{
    [self reloadAllData];
}

@end

#pragma mark -

@implementation KMLAbstractGeometry (DistanceCompare)

- (CLLocation *)location
{
    MKShape *shape = [self mapkitShape];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:shape.coordinate.latitude
                                                      longitude:shape.coordinate.longitude];
    return location;
}

@end



