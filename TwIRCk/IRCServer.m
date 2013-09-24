//
//  IRCServer.m
//  TwIRCk
//
//  Created by Tim Jarratt on 9/15/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "IRCServer.h"

@implementation IRCServer

@dynamic hostname;
@dynamic password;
@dynamic port;
@dynamic username;
@dynamic useSSL;
@dynamic channels;

- (BOOL) hasChannel:(NSString *) channelName {
    __block BOOL hasChannel = NO;
    [[self channels] enumerateObjectsUsingBlock:^(IRCChannel *chan, BOOL *stop) {
        if ([[chan name] isEqualToString:channelName]) {
            hasChannel = YES;
//            *stop = YES;
        }
    }];

    return hasChannel;
}

- (void) addChannelNamed:(NSString *) channelName {
    if ([self hasChannel:channelName]) {
        return NSLog(@"already in channel %@ on %@, ignoring join request", channelName, self.hostname);
    }

    NSManagedObjectContext *context = [GLGManagedObjectContext managedObjectContext];

    IRCChannel *channel = [NSEntityDescription insertNewObjectForEntityForName:@"IRCChannel" inManagedObjectContext:context];
    [channel setName:channelName];
    [channel setServer:self];
    [channel setAutojoin:YES];

    NSError *error;
    [context save:&error];

    if (error) {
        NSLog(@"Couldn't save channel %@", channelName);
    }
}

@end
