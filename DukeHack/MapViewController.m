//
//  MapViewController.m
//  DukeHack
//
//  Created by sloot on 11/15/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import "MapViewController.h"
#import "AppCommunication.h"



@interface MapViewController ()
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation MapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor =  [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
    
    //[AppCommunication sharedManager].buyerMapViewController = self;
    [_mapView setDelegate:self];
    _mapView.showsUserLocation = YES;
    [self createMap];
}
-(void)createMap
{
    for(int i = 0; i<[AppCommunication sharedManager].myAnnotations.count;i++)
    {
        [self.mapView addAnnotation:[AppCommunication sharedManager].myAnnotations[i]];
    }

    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in _mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    [_mapView setVisibleMapRect:zoomRect animated:YES];
}

- (CLLocationCoordinate2D)coordinateWithLocation:(NSDictionary*)location
{
    double latitude = [[location objectForKey:@"lat"] doubleValue];
    double longitude = [[location objectForKey:@"lng"] doubleValue];
    
    return CLLocationCoordinate2DMake(latitude, longitude);
}
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    polylineView.strokeColor = [UIColor colorWithRed:204/255. green:45/255. blue:70/255. alpha:1.0];
    polylineView.lineWidth = 10.0;
    
    return polylineView;
}
@end
