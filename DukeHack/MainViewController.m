//
//  MainViewController.m
//  DukeHack
//
//  Created by Phillip Ou on 11/14/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import "MainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>

@interface MainViewController ()

@property (strong, nonatomic) IBOutlet UILabel *bpmLabel;
@property (strong, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic) IBOutlet UILabel *milesLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIButton *resumeButton;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UIButton *beginButton;

@property (strong, nonatomic) NSTimer *timer;



@property (nonatomic,strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* prevLocation;
@end

@implementation MainViewController{
    NSInteger seconds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    NSArray *arrayOfSongs = [query.items subarrayWithRange:NSMakeRange(0,30)];
    
    //multithread here
    for(MPMediaItem *song in arrayOfSongs)
    {
        NSLog(@"%@",[song valueForProperty:MPMediaItemPropertyTitle]);
        //[self getBeatsPerMinute:song];
    }
    //[self startStandardUpdates];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.doneButton.hidden=YES;
    self.resumeButton.hidden=YES;
}

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
    
    NSLog(@"%f",newLocation.speed);
}

#pragma mark - Buttons

- (IBAction)beginPressed:(id)sender {
    
    if(self.beginButton.selected)
    {
        self.beginButton.selected=NO;
        self.doneButton.hidden=NO;
        self.resumeButton.hidden=NO;
        self.beginButton.hidden=YES;
        
        if ([self.timer isValid]) {
            [self.timer invalidate];
        }
        self.timer = nil;
        
    } else
    {
        self.beginButton.selected=YES;
        seconds=0;
        if (!self.timer) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
        }
        
    }
}
- (IBAction)resumePressed:(id)sender
{
    self.beginButton.hidden=NO;
    self.beginButton.selected=YES;
    self.resumeButton.hidden=YES;
    self.doneButton.hidden=YES;
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
    }

    
}
- (IBAction)donePressed:(id)sender {
    self.doneButton.hidden=YES;
    self.resumeButton.hidden=YES;
    self.beginButton.hidden=NO;
    self.beginButton.selected=NO;
}

- (void)timerFired:(NSTimer *)timer {
    
    seconds+=1;
    NSInteger minutes = (seconds/60);
    NSInteger seconds_converted = (seconds -minutes *60);
    //NSString *secondsString = seconds;
    if(seconds_converted<10){
        self.timeLabel.text = [NSString stringWithFormat:@"%d:0%d",minutes,seconds_converted];
    }
    else{
        self.timeLabel.text = [NSString stringWithFormat:@"%d:%d",minutes,seconds_converted];
    }

    
}

@end
