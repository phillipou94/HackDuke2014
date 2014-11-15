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
#import "SongDictionary.h"
#import "AppDelegate.h"

@interface LoadingViewController ()
@property (nonatomic, strong) NSMutableDictionary *mapOfTempos;

@end

@implementation LoadingViewController
{
    int counter;
    int numToFinish;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapOfTempos=[[NSMutableDictionary alloc]init];
    //get all songs in your itunes
    [self getSongsFromPhone];

    
}

-(void)getSongsFromPhone
{
    MPMediaQuery *query = [MPMediaQuery songsQuery];
    __block NSArray *arrayOfSongs = [[NSArray alloc]init];
    if([query.items count]<101)
    {
        arrayOfSongs = query.items;
    }
    arrayOfSongs = [query.items subarrayWithRange:NSMakeRange(20,50)];
    //NSMutableDictionary *mapOfTempos = [[NSMutableDictionary alloc]init];
    
    //multithread here
    numToFinish = arrayOfSongs.count;
    counter =0;
    dispatch_queue_t concurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(concurrentQueue, ^{
        for(MPMediaItem *song in arrayOfSongs)
        {
            
            //this will start the image loading in backgground
            
            [self getBeatsPerMinute:song];
            NSLog(@"done:%@",self.mapOfTempos);
            counter++;
            if(counter ==[arrayOfSongs count]){
                NSLog(@"Actually done");
                NSManagedObjectContext *context = ((AppDelegate*)[UIApplication sharedApplication].delegate).managedObjectContext;
                SongDictionary *songDic = [NSEntityDescription insertNewObjectForEntityForName:@"SongDictionary" inManagedObjectContext:context];
                songDic.mapOfTempos=self.mapOfTempos;
                NSError *error = nil;
                [context save:&error];
                NSLog(@"nice:%@",songDic.mapOfTempos);
                if(error){
                    NSLog(@"unable to save");
                }

            }
            
        }
    });
    
    
}

-(void) getBeatsPerMinute:(MPMediaItem*)song
{
    NSString *songID = [song valueForKey:MPMediaItemPropertyPersistentID];
    NSString *artistName = [song valueForProperty: MPMediaItemPropertyArtist];
    artistName = [artistName stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
    NSString *songName = [song valueForProperty:MPMediaItemPropertyTitle];
    songName = [songName stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
    //NSRange range = [songName rangeOfString:@"("];
    //songName = [songName substringToIndex:range.location];
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
                //NSLog(@"search String:%@",searchTerm);
                //NSLog(@"%@",results);
                NSDictionary *dic = results[@"response"];
                
                if(results[@"response"])
                {
                    if([dic[@"songs"] count]>0)
                    {
                        NSDictionary *songDic = [dic[@"songs"] objectAtIndex:0];
                        NSDictionary *audioSummary = songDic[@"audio_summary"];
                        NSString *tempoString = audioSummary[@"tempo"];
                        CGFloat tempo = [tempoString floatValue];
                        if(tempo>0){
                            CGFloat roundingValue = 50.0; //round to nearest 50
                            tempo = floor(tempo / roundingValue);
                            NSString *tempoString = [NSString stringWithFormat:@"%f",tempo*50 ];
                            NSMutableArray *array = self.mapOfTempos[tempoString];
                            if(!array){
                                NSMutableArray *array = [[NSMutableArray alloc]init];
                                [array addObject:songID];
                                self.mapOfTempos[tempoString] = array;
                                
                            }else{
                                [array addObject: songID];
                                self.mapOfTempos[tempoString] = array;
                            }
                            
                        }
                    }
                    else
                    {
                        NSLog(@"Can't Find:%@", songName);
                        NSLog(@"Artist Unfound:%@", artistName);
                    }
                }
        
           
            }
    
    
}

@end
