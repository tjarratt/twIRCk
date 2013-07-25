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

@interface GLGAppDelegate : NSObject <NSApplicationDelegate, NSStreamDelegate> {
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

@end
