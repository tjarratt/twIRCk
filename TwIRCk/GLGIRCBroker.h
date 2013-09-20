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

@protocol GLGBrokerDelegate;

@interface GLGIRCBroker : NSObject <GLGStreamReaderDelegate> {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;

    IRCServer *server;
    
    GLGReadDelegate *reader;
    GLGWriteDelegate *writer;

    NSString *hostname;
    NSString *currentNick;

    NSString *internalHostname;

    NSArray *channelsToJoin;
    NSTimer *reconnectTimer;
    NSUInteger reconnectAttempts;
    BOOL hasReadHostname;

    id <GLGBrokerDelegate> delegate;
}

- (id) initWithDelegate:(id <GLGBrokerDelegate>) aDelegate;

- (NSString *) hostname;

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
- (void) didConnectToHost;
- (NSString *) didSubmitText:(NSString *) string inChannel:(NSString *) channel;
@end
