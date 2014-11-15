//
//  AppCommunication.h
//  DukeHack
//
//  Created by sloot on 11/15/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppCommunication : NSObject
+ (instancetype)sharedManager;
@property (nonatomic,strong) NSMutableArray* myAnnotations;
@end
