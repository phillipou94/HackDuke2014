//
//  LoadingViewController.m
//  DukeHack
//
//  Created by Phillip Ou on 11/14/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import "LoadingViewController.h"
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface LoadingViewController ()
@property (nonatomic,strong) CLLocationManager* locationManager;
@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //get all songs in your itunes
    //[self getSongsFromPhone];
    [self startStandardUpdates];
    
}

-(void)getSongsFromPhone
{
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    NSArray *arrayOfSongs = [query.items subarrayWithRange:NSMakeRange(0,30)];
    
    //multithread here
    for(MPMediaItem *song in arrayOfSongs)
    {
        //[self getBeatsPerMinute:song];
    }
}

-(void) getBeatsPerMinute:(MPMediaItem*)song
{
    NSString *artistName = [song valueForProperty: MPMediaItemPropertyArtist];
    artistName = [artistName stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
    NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
    songName = [songName stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
    NSString *searchTerm = [NSString stringWithFormat:@"http://developer.echonest.com/api/v4/song/search?api_key=QVB3INMPBCFREX6N6&format=json&results=1&artist=%@&title=%@&bucket=audio_summary",artistName, songName];
    searchTerm =[searchTerm stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    //make get request to Echonest API
    NSURL *url = [NSURL URLWithString:searchTerm];
    NSData *data=[NSData dataWithContentsOfURL:url];
    NSError *error=nil;
    if(data)
    {
        id response=[NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error:&error];
        NSMutableDictionary *results = (NSMutableDictionary*) response;
        NSLog(@"search String:%@",searchTerm);
        NSLog(@"%@",results);
        NSDictionary *dic = results[@"response"];
        
        if(results[@"response"])
        {
            if([dic[@"songs"] count]>0)
            {
                NSDictionary *songDic = [dic[@"songs"] objectAtIndex:0];
                NSDictionary *audioSummary = songDic[@"audio_summary"];
                NSString *tempoString = audioSummary[@"tempo"];
                CGFloat tempoFloat = [tempoString floatValue];
                NSLog(@"tempo:%f",tempoFloat);
                
            }
        }
    }
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
    self.locationManager.distanceFilter = 1.0; // meters
    
    [self.locationManager startUpdatingLocation];
}


- (void) locationManager:(CLLocationManager *)manager
        didFailWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
    NSLog(@"Failed to get location!:(");
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *newLocation = [locations lastObject];
    
    
    NSString *latitude, *longitude;
    
    latitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    longitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
    
    
    
}

@end
