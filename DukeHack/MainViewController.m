//
//  MainViewController.m
//  DukeHack
//
//  Created by Phillip Ou on 11/14/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//
#define MY_COVERSION 78.7401574806

#import "MainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "SongDictionary.h"
#import "LoadingViewController.h"
#import <MapKit/MapKit.h>
#import "AppCommunication.h"

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
@property (strong, nonatomic) MPMusicPlayerController *musicPlayer;
@property (strong, nonatomic) SongDictionary *songDic;



@property (nonatomic,strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* prevLocation;
@property (nonatomic,assign) float prevSeconds;
@property (nonatomic,assign) float timeLapse;

@end

@implementation MainViewController{
    float seconds;
    int annotationNum;
    bool updatedRecently;
}


-(void)getSongs{
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"SongDictionary" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *ivc = [storyboard instantiateViewControllerWithIdentifier:@"LoadingViewController"];
    [(LoadingViewController*)self presentViewController:ivc animated:NO completion:nil];
    if([fetchedObjects count]<1){
        [self presentViewController: ivc animated:NO completion:nil];
    }
    else{
        NSLog(@"%@",fetchedObjects);
        self.songDic=[fetchedObjects objectAtIndex:0];
        NSLog(@"retrieved:%@",self.songDic.mapOfTempos);
    }
    
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    annotationNum = 0;
    self.milesLabel.text = @"0.0";
    [AppCommunication sharedManager].myAnnotations = [NSMutableArray array];
    [self getSongs];
    //[self startStandardUpdates];
    self.musicPlayer = [MPMusicPlayerController applicationMusicPlayer];


    [self startStandardUpdates];

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

    self.locationManager.distanceFilter = .01; // meters
    

}


- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSLog(@"Failed to get location!:(");
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
        NSLog(@"updatedLocation");
    if(!updatedRecently)
    {
        updatedRecently = true;
        
        CLLocation *newLocation = [locations lastObject];
        
        CLLocationDistance distanceChange = 0.0;
        if(self.prevLocation!=nil)
        {
            distanceChange = [newLocation distanceFromLocation:self.prevLocation];
            self.milesLabel.text = [NSString stringWithFormat:@"%f",(self.milesLabel.text.doubleValue+distanceChange)];

        }
        
        
        
        if(self.timeLapse&&self.prevLocation!=nil)
        {
            
            double speed = distanceChange/self.timeLapse;
            NSLog(@"sec:%f",self.timeLapse);
            NSLog(@"speed:%f",speed);
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = newLocation.coordinate;
            [AppCommunication sharedManager].startPoint = point.coordinate;
            annotationNum++;
            point.title = [NSString stringWithFormat: @"%d",annotationNum];
            point.subtitle = [NSString stringWithFormat: @"speed:%f",speed];
            [[AppCommunication sharedManager].myAnnotations addObject:point];
            self.bpmLabel.text = [NSString stringWithFormat:@"%f",(speed*MY_COVERSION)];
        }
        self.prevLocation = newLocation;
        
        
        
        NSString *latitude, *longitude;
        
        latitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
        longitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
        //    NSLog(@"%@",latitude);
        //    NSLog(@"%@",longitude);
        


    }
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
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01f
                                                      target:self
                                                    selector:@selector(timerFired:)
                                                    userInfo:nil
                                                     repeats:YES];
        }
        
    }
        [self.locationManager startUpdatingLocation];
}
- (IBAction)resumePressed:(id)sender
{
    self.beginButton.hidden=NO;
    self.beginButton.selected=YES;
    self.resumeButton.hidden=YES;
    self.doneButton.hidden=YES;
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.01f
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
    if(seconds-self.prevSeconds>10.0)
    {
        self.timeLapse = seconds - self.prevSeconds;
        self.prevSeconds = seconds;
        updatedRecently = false;
    }
    seconds+=.01;
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
