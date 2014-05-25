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


@interface NearbyBikesViewController () <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) KMLRoot *kml;
@property (nonatomic) NSArray *geometries;
@property (nonatomic) NSArray *filteredGeometries;

@end

#pragma mark -

@implementation NearbyBikesViewController

#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.geometries = @[];
    self.filteredGeometries = @[];
    
    
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
    return self.geometries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    KMLAbstractGeometry *geometry = self.geometries[indexPath.row];
    NearbyBikeCell *cell = (NearbyBikeCell *)[tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    KMLPlacemark *placemark = geometry.placemark;
    
    cell.nameLabel.text = placemark.name;
    cell.descriptionLabel.text = placemark.descriptionValue;
    
    // compute distance from user's position
    MKShape *shape = [geometry mapkitShape];
    CLLocation *pointLocation = [[CLLocation alloc] initWithLatitude:shape.coordinate.latitude
                                                           longitude:shape.coordinate.longitude];
    CLLocationDistance meters = [self.mapView.userLocation.location distanceFromLocation:pointLocation];
    
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
    
    KMLAbstractGeometry *geometry = self.geometries[indexPath.row];
    
    // move to the selected annotation
    MKShape *shape = [geometry mapkitShape];
    
    [self.mapView setCenterCoordinate:shape.coordinate animated:YES];
    if ([shape isKindOfClass:[MKPointAnnotation class]]) {
        [self.mapView selectAnnotation:shape animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    KMLAbstractGeometry *geometry = self.geometries[indexPath.row];
    
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
    [SVProgressHUD show];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
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
            
            self.geometries = self.kml.geometries;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                self.navigationItem.rightBarButtonItem.enabled = YES;
                
                if (success)
                    success();
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                self.navigationItem.rightBarButtonItem.enabled = YES;
                
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
    
    [self.geometries enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         KMLAbstractGeometry *geometry = (KMLAbstractGeometry *)obj;
         MKShape *mkShape = [geometry mapkitShape];
         if (mkShape) {
             if ([mkShape conformsToProtocol:@protocol(MKOverlay)]) {
                 [overlays addObject:mkShape];
             }
             else if ([mkShape isKindOfClass:[MKPointAnnotation class]]) {
                 [annotations addObject:mkShape];
             }
         }
     }];
    
    [self.mapView addAnnotations:annotations];
    [self.mapView addOverlays:overlays];
    
    // set zoom in next run loop.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //
        // Thanks for elegant code!
        // https://gist.github.com/915374
        //
        __block MKMapRect zoomRect = MKMapRectNull;
        [self.mapView.annotations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             id<MKAnnotation> annotation = (id<MKAnnotation>)obj;
             MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
             MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
             if (MKMapRectIsNull(zoomRect)) {
                 zoomRect = pointRect;
             } else {
                 zoomRect = MKMapRectUnion(zoomRect, pointRect);
             }
         }];
        [self.mapView setVisibleMapRect:zoomRect animated:YES];
    });
}


@end
