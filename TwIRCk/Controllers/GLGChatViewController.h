//
//  GLGChatViewController.h
//  TwIRCk
//
//  Created by Tim Jarratt on 12/10/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGBrokerDelegate.h"
#import "GLGOccupantDelegate.h"
#import "GLGIRCBroker.h"
#import "IRCServer.h"
#import "GLGChatView.h"
#import "Blindside.h"

#import "GLGWindowProvider.h"
#import "GLGChatViewProvider.h"
#import "GLGIRCBrokerProvider.h"

@interface GLGChatViewController : NSObject <GLGBrokerDelegate, GLGOccupantDelegate> 

@property (retain, readonly) NSMutableDictionary *chatlogs;
@property (retain, strong, readonly) GLGIRCBroker *currentBroker;
@property (retain, strong, readonly) NSMutableArray *brokers;
@property (retain, strong, readonly) GLGIRCBrokerProvider *brokerProvider;
@property (retain, readonly) GLGChatView *view;
@property (retain, readonly) NSString *currentChannel;

+ (BSInitializer *) bsInitializer;
- (instancetype) initWithWindow:(id <GLGWindowProvider>) windowProvider
                 brokerProvider:(GLGIRCBrokerProvider *)brokerProvider
               chatViewProvider:(GLGChatViewProvider *)chatViewProvider;
- (void) connectToServer:(IRCServer *) server;
@end
