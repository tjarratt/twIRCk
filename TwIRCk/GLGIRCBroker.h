//
//  GLGIRCBroker.h
//  TwIRCk
//
//  Created by Tim Jarratt on 9/19/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLGBrokerDelegate.h" 
#import "GLGReadDelegate.h"
#import "GLGWriteDelegate.h"
#import "IRCServer.h"

@protocol GLGBrokerDelegate;

@interface GLGIRCBroker : NSObject <GLGStreamReaderDelegate> {
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
    
    GLGReadDelegate *reader;
    GLGWriteDelegate *writer;

    NSString *hostname;
    NSString *currentNick;
    NSString *currentChannel;

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
- (void) didConnectToHost:(NSString *) hostname;
- (NSString *) didSubmitText:(NSString *) string;
@end
