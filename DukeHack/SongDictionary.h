//
//  SongDictionary.h
//  DukeHack
//
//  Created by Phillip Ou on 11/15/14.
//  Copyright (c) 2014 Phillip Ou. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface SongDictionary : NSManagedObject
@property (nonatomic, strong) NSDictionary *mapOfTempos;
@end
