//
//  MainViewController.m
//  DukeHack
//
//  Created by Phillip Ou on 11/14/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//
#define MY_COVERSION 78.7401574806
#define MY_COVERSION_MILE 0.000621371
#define MY_CONVERSION_FEET 3.28084
#define FEET_TO_MILES 0.000189394

#import "MainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "SongDictionary.h"
#import "LoadingViewController.h"
#import <MapKit/MapKit.h>
#import "AppCommunication.h"
#import "PulsingHaloLayer.h"
#import <math.h>
//#include "PolynomialRegression.h"

@interface MainViewController ()
@property (strong, nonatomic) IBOutlet UILabel *milesMetricLabel;
@property (strong, nonatomic) IBOutlet UILabel *unitLabel;
@property (strong, nonatomic) IBOutlet UIView *upperView;
@property (strong, nonatomic) IBOutlet UIView *songView;
@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (strong, nonatomic) IBOutlet UILabel *bpmLabel;
@property (strong, nonatomic) IBOutlet UILabel *songTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *artistNameLabel;
@property (strong, nonatomic) IBOutlet UISlider *volumeSlider;
@property (strong, nonatomic) IBOutlet UILabel *milesLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UIButton *resumeButton;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (strong, nonatomic) IBOutlet UIButton *beginButton;
@property (strong, nonatomic) IBOutlet UIButton *prevButton;
@property (strong, nonatomic) IBOutlet UIButton *nextButton;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSTimer *animationTimer;
@property (strong, nonatomic) MPMusicPlayerController *musicPlayer;
@property (strong, nonatomic) SongDictionary *songDic;
@property (nonatomic,strong) CLLocationManager* locationManager;
@property (nonatomic, strong) CLLocation* prevLocation;
@property (nonatomic,assign) float prevSeconds;
@property (nonatomic,assign) float timeLapse;
@property (nonatomic, assign) NSMutableArray *playList;
@property (nonatomic, assign) float currentState;
@property (nonatomic, assign) float previousState;
@property (nonatomic, assign) float liveState;
@property (nonatomic, strong) NSMutableArray* totalAnnotations;
@property (nonatomic, strong) PulsingHaloLayer *halo;
@end

@implementation MainViewController{
    float seconds;
    int annotationNum;
    bool updatedRecently;
    int numberOfTimesUpdated;
    bool usingMiles;
    double coefA;
    double coefB;
    double coefC;
    
    double stepsPerMin;
    double milesPerHour;
}
struct myResult
{
    double a;
    double b;
    double c;
};
struct myResult quadReg(int n,double x[],double y[])
{
    int  i, j, k;
    float sumx, sumxsq, sumy, sumxy;
    float sumx3, sumx4, sumxsqy, a[20][20], u=0.0, b[20];
    
    sumx = 0;
    sumxsq = 0;
    sumy = 0;
    sumxy = 0;
    sumx3 = 0;
    sumx4 = 0;
    sumxsqy = 0;
    for(i=0;  i<n; i++)
    {
        sumx +=x[i];
        sumxsq += pow(x[i],2);
        sumx3 += pow(x[i],3);
        sumx4 += pow(x[i],4);
        sumy +=y[i];
        sumxy += x[i] * y[i];
        sumxsqy += pow(x[i],2) *y[i];
    }
    a[0][0] = n;
    a[0][1] = sumx;
    a[0][2] = sumxsq;
    a[0][3] =
    
    sumy;
    a[1][0] = sumx;
    a[1][1] = sumxsq;
    a[1][2] = sumx3;
    a[1][3] = sumxy;
    a[2][0] = sumxsq;
    a[2][1] = sumx3;
    a[2][2] = sumx4;
    a[2][3] = sumxsqy;
    
    for(k=0;  k<=2; k++)
    {
        for(i=0;i<=2;i++)
        {
            if(i!=k)
                u=a[i][k]/a[k][k];
            for(j = k; j<=3; j++)
                a[i][j]=a[i][j] - u * a[k][j];
        }
    }
    
    for(i=0;i<3;i++)
    {
        b[i] = a[i][3]/a[i][i];
    }
    //Printf(“y= %10.4fx +10.4 fx +%10.4f”,b[2],b[i],b[0]);
    struct myResult temp;
    temp.a = b[2];
    temp.b = b[1];
    temp.c = b[0];
    return temp;
}
-(double)functionateWithCoeffA:(double)a WithCoeffB:(double)b WithX:(double)x
{
    double temp = 2*a*x+b;
    return (pow((pow(temp, 2.0)+1.0), .5)*(temp)+asinh(temp))/(4*a);
}
-(double)calcQuadRegWithElemets:(int) num withX:(NSMutableArray*)arrayStuff
{
    double myX[num];
    double myY[num];
    for(int i = 0; i <arrayStuff.count;i++)
    {
        myX[i] = ((CLLocation*)arrayStuff[i]).coordinate.latitude;
        myY[i] = ((CLLocation*)arrayStuff[i]).coordinate.longitude;
    }
    struct myResult res = quadReg(num, myX, myY);
    coefA = res.a;
    coefB = res.b;
    coefC = res.c;

    NSLog(@"%fx^2+%fx+%f",res.a,res.b,res.c);
    if(res.a>0.0)
    {
        double distance = [self functionateWithCoeffA:res.a WithCoeffB:res.b WithX:((CLLocation*)arrayStuff[arrayStuff.count-1]).coordinate.latitude]-[self functionateWithCoeffA:res.a WithCoeffB:res.b WithX:((CLLocation*)arrayStuff[0]).coordinate.latitude];
        NSLog(@"distance:%f",distance);
        return (distance*111320);
    }
    else
    {
        return [self.totalAnnotations[self.totalAnnotations.count-1] distanceFromLocation:self.totalAnnotations[0]];
    }

    
}
-(void)getSongs{
    NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"SongDictionary" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:nil];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *ivc = [storyboard instantiateViewControllerWithIdentifier:@"loadView"];
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
    self.totalAnnotations = [NSMutableArray array];
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame: CGRectZero];
    [self.view addSubview: volumeView];
    
    annotationNum = 0;
    self.liveState=50.0;
    self.currentState=50.0;
    self.previousState=50.0;
    numberOfTimesUpdated=0;
    self.milesLabel.text = @"0";
    [AppCommunication sharedManager].myAnnotations = [NSMutableArray array];
    [self getSongs];
    //[self startStandardUpdates];
    self.musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    [self startStandardUpdates];
    self.unitLabel.tag=0;
    self.bpmLabel.tag=0;
        

}
- (IBAction)labelTapped:(id)sender {
    NSLog(@"tapped");
    if(self.unitLabel.tag==0){
        self.unitLabel.text = @"Miles Per Hour";
        self.unitLabel.tag=1;
        self.bpmLabel.tag=1;
        self.bpmLabel.text = [NSString stringWithFormat:@"%.2f",(milesPerHour)];
    } else {
        self.unitLabel.text = @"Steps Per Minute";
        self.unitLabel.tag=0;
        self.bpmLabel.tag=0;
        self.bpmLabel.text = [NSString stringWithFormat:@"%.2f",(stepsPerMin*MY_COVERSION)];
    }
    
}



-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.doneButton.hidden=YES;
    self.resumeButton.hidden=YES;
    //self.nextButton.hidden=YES;
    //self.prevButton.hidden=YES;
    //self.songView.hidden=YES;
    
    
    
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
    CLLocation *newLocation = [locations lastObject];
    [self.totalAnnotations addObject:newLocation];
    NSLog(@"%f",[newLocation distanceFromLocation:self.prevLocation]);
    
    if(!updatedRecently)
    {
        updatedRecently = true;
        

        CLLocationDistance distanceChange = 0;
        if(self.prevLocation!=nil)
        {
            distanceChange = [newLocation distanceFromLocation:self.prevLocation];
            if(usingMiles)
            {
                self.milesLabel.text = [NSString stringWithFormat:@"%f",(self.milesLabel.text.doubleValue+distanceChange*MY_COVERSION_MILE)];
            }
            else
            {
                self.milesLabel.text = [NSString stringWithFormat:@"%d",(int)(self.milesLabel.text.intValue+distanceChange*MY_CONVERSION_FEET)];
                if(self.milesLabel.text.intValue>528)
                {
                    usingMiles=true;
                    self.milesMetricLabel.text = @"Miles:";
                    double temp = 0.0 + self.milesLabel.text.intValue;
                    self.milesLabel.text = [NSString stringWithFormat:@"%f",(temp*FEET_TO_MILES)];
                }
                
            }


        }
        
        
        
        if(self.timeLapse&&self.prevLocation!=nil)
        {
            double traveledDist;
            if(self.totalAnnotations.count>2)
            {
                         traveledDist    = [self calcQuadRegWithElemets:self.totalAnnotations.count withX:self.totalAnnotations];
                NSLog(@"Quad Reg");
            }
            else if(self.totalAnnotations.count==2)
            {
                traveledDist = [newLocation distanceFromLocation:self.prevLocation];
                NSLog(@"Only two loc");
            }
            else
            {
                NSLog(@"No Change");
            }

            double speed1 = distanceChange/self.timeLapse;
            milesPerHour = speed1 *2.23694;
            stepsPerMin = (traveledDist/self.timeLapse);
            NSLog(@"sec:%f",self.timeLapse);
            NSLog(@"speed:%f",stepsPerMin);
            NSLog(@"oldspeed:%f",speed1);
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = newLocation.coordinate;
            [AppCommunication sharedManager].startPoint = point.coordinate;
            annotationNum++;
            point.title = [NSString stringWithFormat: @"%d",annotationNum];
            point.subtitle = [NSString stringWithFormat: @"speed:%f",stepsPerMin];
            [[AppCommunication sharedManager].myAnnotations addObject:point];
            if(self.bpmLabel.tag==0){
                self.bpmLabel.text = [NSString stringWithFormat:@"%.2f",(stepsPerMin*MY_COVERSION)];
            } else{
                self.bpmLabel.text = [NSString stringWithFormat:@"%.2f",(milesPerHour)];
            }
            
            
            CGFloat roundingValue = 50.0; //round to nearest 50
            self.liveState= ceilf(stepsPerMin/ roundingValue)*50;
            
            NSLog(@"STATE:%f",self.liveState);
            if(numberOfTimesUpdated%2==0){
                self.previousState=self.liveState;
                NSLog(@"prevState:%f",self.previousState);
            } else{
                self.currentState=self.liveState;
                NSLog(@"currentSTate:%f",self.currentState);
            }
            if(self.previousState==self.currentState)
            {
                //do nothing
                NSLog(@"do nothing");
            } else{
                //change playlist
                if(self.liveState>150.000000){
                    [self playPlaylistForState:@"150.000000"];
                }else{
                    NSString *stateString = [NSString stringWithFormat:@"%f",self.liveState];
                    [self playPlaylistForState:stateString];
                }
                NSLog(@"change playlist");
            }
            self.totalAnnotations = [NSMutableArray array];
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
    NSInteger randomInt = arc4random_uniform([self.playList count]);
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
    
    //pause
    if(self.beginButton.selected)
    {
        [self.musicPlayer pause];
        [self.halo removeAllAnimations];
        self.beginButton.selected=NO;
        self.doneButton.hidden=NO;
        self.resumeButton.hidden=NO;
        self.prevButton.hidden=YES;
        self.nextButton.hidden=YES;
        self.beginButton.hidden=YES;
        
        
        if ([self.timer isValid]) {
            [self.timer invalidate];
        }
        self.timer = nil;
        
       
        
        
    } else
    {
        [self pulse];
       // [self buttonPulse:[self.beginButton center]];
        [self playPlaylistForState:@"50.000000"];
        self.beginButton.selected=YES;
        self.nextButton.hidden=NO;
        self.prevButton.hidden=NO;
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
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval: (self.liveState+50.0)/60 target: self selector: @selector(pulseAnimation) userInfo: nil repeats: YES];

    
}
- (IBAction)donePressed:(id)sender {
    self.doneButton.hidden=YES;
    self.resumeButton.hidden=YES;
    self.beginButton.hidden=NO;
    self.beginButton.selected=NO;
    [self.musicPlayer pause];
    self.animationTimer=nil;
    [self.halo removeAllAnimations];
}

- (void)timerFired:(NSTimer *)timer
{
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
    if(seconds_converted<10) {
        self.timeLabel.text = [NSString stringWithFormat:@"%d:0%d",minutes,seconds_converted];
    }
    else {
        self.timeLabel.text = [NSString stringWithFormat:@"%d:%d",minutes,seconds_converted];
    }


}
- (IBAction)previousPressed:(id)sender {
    
    
}
- (IBAction)nextPressed:(id)sender {
    __block NSString *stateString=@"";
    if(numberOfTimesUpdated%2==0)
    {
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

-(void)pulseAnimation
{
//    self.containerView.alpha = 0.5;
//    [UIView animateWithDuration:1.0 animations:^{
//        self.containerView.alpha = 1.0;
//
//    } completion:NULL];
    
}
-(void)pulse
{
    self.halo = [PulsingHaloLayer layer];
    self.halo.position = self.view.center;
    UIColor *color = [UIColor colorWithRed:245.0/255.0
                                     green:30.0/255.0
                                      blue:30.0/255.0
                                     alpha:1.0];
    
    self.halo.backgroundColor = color.CGColor;
    self.halo.radius = 240.0;
    self.halo.pulseInterval=60.0/self.liveState;
    self.halo.pulseOnce=NO;
    [self.view.layer addSublayer:self.halo];
    
}

-(void)buttonPulse:(CGPoint)point{
    PulsingHaloLayer *halo = [PulsingHaloLayer layer];
    halo.position = point;
    halo.radius = 50;
    halo.pulseOnce=YES;
    [self.bottomView.layer addSublayer:halo];
    UIColor *color = [UIColor colorWithRed:245.0/255.0
                                     green:30.0/255.0
                                      blue:30.0/255.0
                                     alpha:1.0];
    halo.backgroundColor = color.CGColor;
    
    
}
@end
