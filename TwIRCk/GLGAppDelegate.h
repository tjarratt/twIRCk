//
//  GLGAppDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLGResponseCodes.h"
#import "GLGReadDelegate.h"
#import "GLGWriteDelegate.h"
#import <CFNetwork/CFSocketStream.h> 

@interface GLGAppDelegate : NSObject <NSApplicationDelegate, GLGReaderDelegate> {
    NSTextField *hostname;
    NSTextField *port;
    NSTextField *username;
    NSSecureTextField *password;
    NSTextField *channels;

    NSInputStream *inputStream;
    NSOutputStream *outputStream;

    GLGReadDelegate *reader;
    GLGWriteDelegate *writer;
    GLGResponseCodes *responseLookup;
}

@property (assign) IBOutlet NSWindow *window;

- (void) receivedString:(NSString *) str;

@end
