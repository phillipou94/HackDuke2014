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
@property (nonatomic,assign) double timeLapse;
@property (nonatomic, assign) NSMutableArray *playList;
@property (nonatomic, assign) float currentState;
@property (nonatomic, assign) float previousState;
@property (nonatomic, assign) float liveState;
@property (nonatomic, strong) NSMutableArray* totalAnnotations;

@property (nonatomic, strong) PulsingHaloLayer *halo;

@property (nonatomic, strong) NSMutableArray* fixedX;
@property (nonatomic, strong) NSMutableArray* fixedY;
@property (nonatomic, strong) NSMutableArray* timeStamp;

@end

@implementation MainViewController{
    double seconds;
    int annotationNum;
    bool updatedRecently;
    int numberOfTimesUpdated;
    bool usingMiles;
    double coefA;
    double coefB;
    double coefC;

    
    double stepsPerMin;
    double milesPerHour;

    double coefD;
    CLLocation* current;
    double time;

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
-(void)calcQuadRegWithElemets:(int) num withT:(NSMutableArray*)arrayT withXY:(NSMutableArray*)arrayXY do:(NSString*)str
{
    double myX[num];
    double myY[num];
    for(int i = 0; i <arrayT.count;i++)
    {
        myX[i] = ((NSNumber*)arrayT[i]).doubleValue;
        myY[i] = ((NSNumber*)arrayXY[i]).doubleValue;
    }
    struct myResult res = quadReg(num, myX, myY);

    if([str isEqual:@"x"])
    {
        coefA = res.a;
        coefB = res.b;
    }
    else
    {
        coefC = res.a;
        coefD = res.b;
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

    time = 0.0;
    self.totalAnnotations = [NSMutableArray array];
    self.fixedX = [NSMutableArray array];
    self.fixedY = [NSMutableArray array];
    self.timeStamp = [NSMutableArray array];
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
    //get current Location

    current = newLocation;
    
    [self.totalAnnotations addObject:newLocation];
    if(self.fixedX.count==0)
    {
        [self.fixedX addObject:@(0.0)];
        [self.fixedY addObject:@(0.0)];
        [self.timeStamp addObject:@(0.0)];
        //uses prevlocation as origin of grid
    }
    else
    {
        double disty = [newLocation distanceFromLocation:self.prevLocation];
        //distance from origin in meters
        double latdif = newLocation.coordinate.latitude-self.prevLocation.coordinate.latitude;
        //xcord from origin in coordinates
        double londif = newLocation.coordinate.longitude-self.prevLocation.coordinate.longitude;
        //ycord from origin in coordinates
        double z = sqrt((latdif*latdif+londif*londif));
        //distance from origin in coordinates
        
        [self.fixedX addObject:@(londif*disty/z)];
        //adds xcord from origin in meters
        [self.fixedY addObject:@(latdif*disty/z)];
        //adds ycord from origin in meters
        [self.timeStamp addObject:@(time)];
        //adds current timeStamp
//        NSLog(@"x:%f,y:%f,Z:%f,t:%f",londif*disty/z,latdif*disty/z,disty,seconds);
    }
    
    if(!updatedRecently)
    {
        updatedRecently = true;
        

        CLLocationDistance distanceChange = 0;
        if(self.prevLocation!=nil)
        {
            distanceChange = [newLocation distanceFromLocation:self.prevLocation];
            if(usingMiles)
            {
                self.milesLabel.text = [NSString stringWithFormat:@"%.2f",(self.milesLabel.text.doubleValue+distanceChange*MY_COVERSION_MILE)];
            }
            else
            {
                self.milesLabel.text = [NSString stringWithFormat:@"%d",(int)(self.milesLabel.text.intValue+distanceChange*MY_CONVERSION_FEET)];
                if(self.milesLabel.text.intValue>528)
                {
                    usingMiles=true;
                    self.milesMetricLabel.text = @"Miles:";
                    double temp = 0.0 + self.milesLabel.text.intValue;
                    self.milesLabel.text = [NSString stringWithFormat:@"%.2f",(temp*FEET_TO_MILES)];
                }
                
            }

            double traveledDist;
            double arcLength;
                if(self.fixedX.count>2)
                {
                    [self calcQuadRegWithElemets:self.fixedX.count withT:self.timeStamp withXY:self.fixedX do:@"x"];
                    [self calcQuadRegWithElemets:self.fixedX.count withT:self.timeStamp withXY:self.fixedY do:@"y"];
                    //Now coeff a,b,c,d should all be updated
                    NSLog(@"A:%f,B:%f,C:%f,D:%f",coefA,coefB,coefC,coefD);
                    arcLength = [self integralWithT:((NSNumber*)self.timeStamp[self.timeStamp.count-1]).doubleValue WithA:coefA WithB:coefB WithC:coefC WithD:coefD] - [self integralWithT:0.0 WithA:coefA WithB:coefB WithC:coefC WithD:coefD];
                    //gets arcLength in meters
                    
                    NSLog(@"%f",arcLength);
                    //traveledDist    = [self calcQuadRegWithElemets:self.fixedX.count withX:self.fixedX withY:self.fixedY];
                    NSLog(@"Quad Reg");
                }
                else if(self.fixedX.count==2)
                {
                    arcLength = [newLocation distanceFromLocation:self.prevLocation];
                    //only 2 points to use so linear
                }
                else
                {
                    NSLog(@"No Noticible movement");
                }
            
                double speed = arcLength/time;
                //speed in meters/sec
            
                MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
                point.coordinate = newLocation.coordinate;
                [AppCommunication sharedManager].startPoint = point.coordinate;
                annotationNum++;
                point.title = [NSString stringWithFormat: @"%d",annotationNum];
                point.subtitle = [NSString stringWithFormat: @"bpm:%f",(speed*MY_COVERSION)];
                [[AppCommunication sharedManager].myAnnotations addObject:point];
            
                self.bpmLabel.text = [NSString stringWithFormat:@"%.2f",(speed*MY_COVERSION)];
            
                CGFloat roundingValue = 50.0; //round to nearest 50
                self.liveState= ceilf(speed / roundingValue)*50;
                NSLog(@"nice:%f",(self.liveState)/60);
                self.animationTimer = [NSTimer scheduledTimerWithTimeInterval: (self.liveState+50.0)/60 target: self
                                                                     selector: @selector(pulseAnimation) userInfo: nil repeats: YES];
                NSLog(@"STATE:%f",self.liveState);
                if(numberOfTimesUpdated%2==0){
                    self.previousState=self.liveState;
                    NSLog(@"prevState:%f",self.previousState);
                } else{
                    self.currentState=self.liveState;
                    NSLog(@"currentSTate:%f",self.currentState);
                }
                if(self.previousState==self.currentState ||self.liveState==0)
                {
                    //do nothing
                    NSLog(@"do nothing");
                } else{
                    //change playlist
                    if(self.liveState>150.000000){
                        [self playPlaylistForState:@"150.000000"];
                    } else{
                        NSString *stateString = [NSString stringWithFormat:@"%f",self.liveState];
                        NSLog(@"stateSTring:%@",stateString);
                        [self playPlaylistForState:stateString];
                    }
                    NSLog(@"change playlist");
                }
                self.totalAnnotations = [NSMutableArray array];
            }
            self.prevLocation = newLocation;
            
            
        
            
            self.fixedX = [NSMutableArray array];
            self.fixedY = [NSMutableArray array];
            self.timeStamp = [NSMutableArray array];
            time = 0.0;
            //resets everything
            
            
            
            
        

    }
    if(!self.prevLocation)
    {
        self.prevLocation = newLocation;
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
-(double)integralWithT:(double)t WithA:(double)a WithB:(double)b WithC:(double)c WithD:(double)d
{
    return ((.25)*((((a*b)+(c*d))/((a*a)+(c*c)))+2*t)*sqrt(4*t*t*(a*a+c*c)+4*a*b*t+b*b+4*c*d*t+d*d))+(1/(4*(pow(a*a+c*c, 1.5))))*(pow(b*c-a*d, 2.0))*log10((sqrt(a*a+c*c)*sqrt(4*t*t*(a*a+c*c)+4*a*b*t+b*b+4*c*d*t+d*d))+2*a*a*t+a*b+2*c*c*t+c*d);
    
    
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
    time+=.01;
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

