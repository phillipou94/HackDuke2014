//
//  AppCommunication.m
//  DukeHack
//
//  Created by sloot on 11/15/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import "AppCommunication.h"

@implementation AppCommunication

+ (instancetype)sharedManager
{
    static AppCommunication *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
                  {
                      sharedMyManager = [[self alloc] init];
                  });
    return sharedMyManager;
}

@end
