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
@property (nonatomic, assign) NSMutableArray *playList;
@property (nonatomic, assign) float currentState;
@property (nonatomic, assign) float previousState;
@end

@implementation MainViewController{
    float seconds;
    int annotationNum;
    bool updatedRecently;
    int numberOfTimesUpdated;
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
        
    } else{
        
        NSLog(@"%@",fetchedObjects);
        self.songDic=[fetchedObjects objectAtIndex:0];
        NSLog(@"retrieved:%@",self.songDic.mapOfTempos);
    }
    
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame: CGRectZero];
    [self.view addSubview: volumeView];
    
    annotationNum = 0;
    self.currentState=0;
    self.previousState=0;
    numberOfTimesUpdated=0;
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
    numberOfTimesUpdated++;
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
            annotationNum++;
            point.title = [NSString stringWithFormat: @"%d",annotationNum];
            point.subtitle = [NSString stringWithFormat: @"speed:%f",speed];
            [[AppCommunication sharedManager].myAnnotations addObject:point];
            self.bpmLabel.text = [NSString stringWithFormat:@"%f",(speed*MY_COVERSION)];
            CGFloat roundingValue = 50.0; //round to nearest 50
            CGFloat state= floor(speed / roundingValue)*50;
            if(numberOfTimesUpdated%2==0){
                self.previousState=state+50.000000;
                NSLog(@"prevState:%f",self.previousState);
            } else{
                self.currentState=state+50.000000;
                NSLog(@"currentSTate:%f",self.currentState);
            }
            if(self.previousState==self.currentState)
            {
                //do nothing
                NSLog(@"do nothing");
            } else{
                //change playlist
                if(state>150.000000){
                    [self playPlaylistForState:@"150.000000"];
                }else{
                    NSString *stateString = [NSString stringWithFormat:@"%f",state];
                    [self playPlaylistForState:stateString];
                }
                NSLog(@"change playlist");
            }
        }
        self.prevLocation = newLocation;
        
        
        NSString *latitude, *longitude;
        
        latitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
        longitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
        //    NSLog(@"%@",latitude);
        //    NSLog(@"%@",longitude);
        


    }
}

-(void)playPlaylistForState: (NSString*)state{
    
    self.playList = [self.songDic.mapOfTempos objectForKey:state];
    
    //Choose the first indexed song
    NSInteger randomInt = arc4random()%[self.playList count];
    NSString *songID = [self.playList objectAtIndex:randomInt];
    //Use the MPMediaItemPropertyPersistentID to play the song
    MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:songID forProperty:MPMediaItemPropertyPersistentID];
    MPMediaQuery *mySongQuery = [[MPMediaQuery alloc] init];
    [mySongQuery addFilterPredicate: predicate];
    [self.musicPlayer setQueueWithQuery:mySongQuery];
    [self.musicPlayer play];
    MPMediaItem *songObject =[self.musicPlayer nowPlayingItem];
    self.songTitleLabel.text = [songObject valueForProperty:MPMediaItemPropertyTitle];
    self.artistNameLabel.text = [songObject valueForProperty:MPMediaItemPropertyArtist];
}

#pragma mark - Buttons

- (IBAction)beginPressed:(id)sender {
    
    if(self.beginButton.selected)
    {
        [self.musicPlayer pause];
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
        [self playPlaylistForState:@"50.000000"];
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

- (IBAction)sliderValueChanged  : (UISlider *)sender
{
    self.musicPlayer.volume=sender.value;
}


- (IBAction)resumePressed:(id)sender
{
    [self.musicPlayer play];
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
    [self.musicPlayer pause];
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
- (IBAction)nextPressed:(id)sender {
    __block NSString *stateString=@"";
    if(numberOfTimesUpdated%2==0){
        stateString=[NSString stringWithFormat:@"%f",self.previousState];
    }else{
        stateString=[NSString stringWithFormat:@"%f",self.currentState];
    }
    if([stateString isEqualToString:@"0.000000"])
    {
     stateString=@"50.000000";
    }
    [self playPlaylistForState:stateString];
    NSLog(@"pressed:%@",stateString);
    if(!self.beginButton.selected){
        [self.musicPlayer pause];
    }
}


@end
