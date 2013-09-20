//
//  GLGAppDelegate.h
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CFNetwork/CFSocketStream.h> 
#import "GLGManagedObjectContext.h"
#import "GLGResponseCodes.h"
#import "GLGNewServer.h"
#import "IRCServer.h"

@interface GLGAppDelegate : NSObject <NSApplicationDelegate> {
    GLGResponseCodes *responseLookup;
    BOOL serverWindowIsVisible;
    GLGChatView *chatView;
}

@property (assign) IBOutlet NSWindow *window;
@property (strong, nonatomic) NSWindowController * windowController;

- (IBAction)closeActiveWindow:(id)sender;

@end
