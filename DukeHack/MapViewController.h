//
//  MapViewController.h
//  DukeHack
//
//  Created by sloot on 11/15/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
@interface MapViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, strong) NSString *calories;
@property (nonatomic, strong) NSString *distance;
@property (nonatomic, strong) NSString *time;

@end
