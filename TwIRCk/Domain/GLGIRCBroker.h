//
//  GLGIRCBroker.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGManagedObjectContext.h"
#import "GLGBrokerDelegate.h" 
#import "GLGReadDelegate.h"
#import "GLGWriteDelegate.h"
#import "IRCServer.h"
#import "GLGInputParser.h"
#import "GLGIRCMessage.h"

@protocol GLGBrokerDelegate;

@interface GLGIRCBroker : NSObject <GLGStreamReaderDelegate, GLGInputParserDelegate> {
    BOOL hasReadHostname;
    NSUInteger reconnectAttempts;
}

@property (weak, readonly) id <GLGBrokerDelegate> delegate;

@property (retain, strong, readonly) NSTimer *reconnectTimer;

@property (retain, strong, readonly) NSString *hostname;
@property (retain, strong, readonly) NSString *currentNick;
@property (retain, strong, readonly) NSString *internalHostname;
@property (retain, strong, readonly) NSMutableArray *channelsToJoin;
@property (retain, strong, readonly) NSMutableDictionary *channelOccupants;

@property (retain, strong, readonly) GLGReadDelegate *reader;
@property (retain, strong, readonly) GLGWriteDelegate *writer;

@property (retain, strong, readonly) IRCServer *server;
@property (retain, strong, readonly) NSInputStream *inputStream;
@property (retain, strong, readonly) NSOutputStream *outputStream;
@property (retain, strong, readonly) GLGInputParser *inputParser;

- (id) initWithDelegate:(id <GLGBrokerDelegate>) aDelegate;
- (void) connectToServer:(IRCServer *) server;
- (void) connectToServer: (NSString *) theHostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL;
- (void) connectToServer: (NSString *) theHostname
                  onPort:(UInt32) port
            withUsername:(NSString *) username
            withPassword:(NSString *) password
                  useSSL:(BOOL) useSSL
            withChannels:(NSArray *) channels;

- (void) receivedString:(NSString *) string;
- (void) willPartChannel:(NSString *) channelName;
- (void ) didSubmitText:(NSString *) string inChannel:(NSString *) channel;
- (NSArray *) occupantsInChannel:(NSString *) channel;
@end
