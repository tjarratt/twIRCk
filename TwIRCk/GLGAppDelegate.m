//
//  GLGAppDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGAppDelegate.h"

@implementation GLGAppDelegate

#pragma mark - Application Lifecycle
- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
    self.windowController = [[NSWindowController alloc] initWithWindow:[self window]];
    NSArray *savedServers = [GLGManagedObjectContext currentServers];

    if ([savedServers count] > 0) {
        [self.window close];

        NSSize size = NSMakeSize(800, 600);
        CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
        CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

        NSPoint origin = NSMakePoint((screenwidth - size.width) / 2, (screenheight - size.height) / 2);
        NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

        NSString *autosaveName = @"twirck-chatview";
        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
        [window setFrameAutosaveName:autosaveName];
        [window setFrameUsingName:autosaveName];
        [window setTitle:@"twIRCk"];
        [[self windowController] setWindow:window];

        self.chatView = [[GLGChatView alloc] initWithWindow:window];
        [window setContentView:self.chatView];

        [savedServers enumerateObjectsUsingBlock:^(NSManagedObject *obj, NSUInteger index, BOOL *stop) {
            [self.chatView connectToServer:(IRCServer *)obj];
        }];
    }
    else {
        NSWindow *window = [self window];
        [window setTitle:@"Connect to a new server"];
        NSSize minSize = NSMakeSize(400, 80);
        [window setMinSize:minSize];
        [window setContentView:[[GLGNewServerView alloc] init]];
        [window setFrameAutosaveName:@"twirck-new-server"];
        [window setFrameUsingName:@"twirck-new-server"];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

#pragma mark - CoreData support
- (NSManagedObjectContext *) managedObjectContext {
    return [GLGManagedObjectContext managedObjectContext];
}

- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *) window {
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender {
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];

        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        } else {
            return NSTerminateNow;
        }
    }
    
    return NSTerminateNow;
}

#pragma mark - IBActions
- (IBAction) saveAction:(id) sender {
    NSError *error = nil;

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (IBAction) showPreferences:(id) sender {
    if ([[self.windowController.window contentView] isKindOfClass:[GLGPreferencesView class]]) {
        [[[self windowController] window] makeKeyAndOrderFront:NSApp];
        return;
    }

    NSSize size = NSMakeSize(600, 400);
    CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
    CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

    NSPoint origin = NSMakePoint((screenwidth - size.width) / 2, (screenheight - size.height) / 2);
    NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;
    NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

    __strong NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
    NSString *autosaveName = @"twirck-preferences";
    [window setFrameAutosaveName:autosaveName];
    [window setFrameUsingName:autosaveName];
    [window setDelegate:self];
    [window setTitle:NSLocalizedString(@"Preferences", @"Window.Title.Preferences")];
    GLGPreferencesView *view = [[GLGPreferencesView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
    [view setFetchedServersController:[[GLGPreferencesController alloc] init]];

    [window setContentView:view];
    [window makeKeyAndOrderFront:NSApp];

    [[self windowController] setWindow:window];
}

- (IBAction) openNewServerWindow:(id) sender {
    NSWindow *currentWindow = [[self windowController] window];
    NSView *theContentView = [currentWindow contentView];
    if ([theContentView isKindOfClass:[GLGNewServerView class]]) {
        [currentWindow makeKeyAndOrderFront:NSApp];
        return;
    }

    NSSize size = NSMakeSize(400, 80);
    CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
    CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;
    NSPoint origin = NSMakePoint((screenwidth - size.width) / 2, (screenheight - size.height) / 2);

    NSRect windowRect = NSMakeRect(origin.x, origin.y, size.width, size.height);
    NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;

    __strong NSWindow *newWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:style backing:NSBackingStoreBuffered defer:NO];
    [newWindow setTitle:@"Connect to a new server"];
    [newWindow setMinSize:windowRect.size];
    [newWindow setFrameAutosaveName:@"twirck-new-server"];
    [newWindow setFrameUsingName:@"twirck-new-server"];
    [newWindow makeKeyAndOrderFront:NSApp];

    [newWindow setContentView:[[GLGNewServerView alloc] init]];
    [[self windowController] setWindow:newWindow];
}

- (IBAction) quit:(id) sender {
    [NSApp terminate:self];
}

- (IBAction) closeActiveWindow:(id)sender {
    NSWindow *keyWindow = [NSApp keyWindow];

    if (_chatView && _chatView.window == keyWindow) {
        [_chatView closeActiveTabOrWindow];
    }
    else {
        [keyWindow close];
    }
}

- (IBAction) copy:(id) sender {
    [_chatView copy:sender];
}

#pragma mark - NSWindowDelegate
- (void) windowWillClose:(NSNotification *) notification {
    NSView *contentView = [[notification object] contentView];
    if ([contentView isKindOfClass:[GLGPreferencesView class]]) {
        [self.windowController setWindow:self.window];
    }
}

@end
