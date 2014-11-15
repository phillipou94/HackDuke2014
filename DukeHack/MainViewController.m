//
//  MainViewController.m
//  DukeHack
//
//  Created by Phillip Ou on 11/14/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
@property (nonatomic,strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* prevLocation;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
        [self startStandardUpdates];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma GPS

- (void)startStandardUpdates
{
    
    // Create the location manager if this object does not
    // already have one.
    
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestAlwaysAuthorization];
    self.locationManager.delegate = self;
    
    
    
    
    
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Set a movement threshold for new events.
    self.locationManager.distanceFilter = .1; // meters
    
    [self.locationManager startUpdatingLocation];
}


- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSLog(@"Failed to get location!:(");
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
        NSLog(@"updatedLocation");
    CLLocation *newLocation = [locations lastObject];
    if(self.prevLocation!=nil)
    {
        CLLocationDistance distanceChange = [newLocation distanceFromLocation:self.prevLocation];
        NSLog(@"%f",distanceChange);
    }
    self.prevLocation = newLocation;


    
    NSString *latitude, *longitude;
    
    latitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    longitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
//    NSLog(@"%@",latitude);
//    NSLog(@"%@",longitude);
    
    
    
}
-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    
}
@end
