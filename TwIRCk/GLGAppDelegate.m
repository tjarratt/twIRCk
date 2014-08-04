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
    responseLookup = [[GLGResponseCodes alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowClosing:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];

    self.windowController = [[NSWindowController alloc] initWithWindow:[self window]];
    [[self window] setTitle:@"twIRCk"];

    // initialize any servers we might have, try to connect to them
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *description = [NSEntityDescription entityForName:@"IRCServer" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:description];

    NSError *error;
    currentServers = [[NSMutableArray alloc] init];
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];

    if ([fetchedObjects count] > 0) {
        serverWindowIsVisible = NO;
        [self.window close];

        // defaults for chat window size
        NSSize size = NSMakeSize(800, 600);
        CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
        CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

        NSPoint origin = NSMakePoint((screenwidth - size.width) / 2, (screenheight - size.height) / 2);
        NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
        self.chatView = [[GLGChatView alloc] initWithWindow:window];

        [fetchedObjects enumerateObjectsUsingBlock:^(NSManagedObject *obj, NSUInteger index, BOOL *stop) {
            IRCServer *server = (IRCServer *)obj;
            [currentServers addObject:server];

            [self.chatView connectToServer:server];
            [[window contentView] addSubview:self.chatView];
            [window setTitle:@"twIRCk"];
        }];
    }
    else {
        serverWindowIsVisible = YES;
        NSSize minSize = NSMakeSize(400, 80);
        [[self window] setMinSize:minSize];

        NSView *contentView = [[self window] contentView];
        GLGNewServer *newServerView = [[GLGNewServer alloc] initWithSuperView:contentView];
        [contentView addSubview:newServerView];
    }
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

        // Customize this code block to include application-specific recovery steps.
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
        }
    }
    
    return NSTerminateNow;
}

#pragma mark - Notifications
- (void) windowClosing:(NSNotification *) aNotification {
    serverWindowIsVisible = NO;
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
        return;
    }

    NSSize size = NSMakeSize(600, 200);
    CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
    CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

    NSPoint origin = NSMakePoint((screenwidth - size.width) / 2, (screenheight - size.height) / 2);
    NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask;
    NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

    __strong NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
    [window setDelegate:self];
    [window setTitle:NSLocalizedString(@"Preferences", @"Window.Title.Preferences")];
    GLGPreferencesView *view = [[GLGPreferencesView alloc] initWithFrame:NSMakeRect(0, 0, size.width, size.height)];
    [view.tableview setDelegate:self];
    [view.tableview setDataSource:self];

    [window setContentView:view];
    [window makeKeyAndOrderFront:NSApp];

    [[self windowController] setWindow:window];
}

- (IBAction) openNewServerWindow:(id) sender {
    if (serverWindowIsVisible) {
        return;
    }

    NSSize size = NSMakeSize(400, 80);
    CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
    CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;
    NSPoint origin = NSMakePoint((screenwidth - size.width) / 2, (screenheight - size.height) / 2);

    NSRect windowRect = NSMakeRect(origin.x, origin.y, size.width, size.height);
    NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;

    __strong NSWindow *newWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:style backing:NSBackingStoreBuffered defer:NO];
    [newWindow setMinSize:windowRect.size];
    [newWindow makeKeyAndOrderFront:NSApp];

    NSView *contentView = [newWindow contentView];
    GLGNewServer *newServerView = [[GLGNewServer alloc] initWithSuperView:contentView];
    [contentView addSubview:newServerView];

    [[self windowController] setWindow:newWindow];
    serverWindowIsVisible = YES;
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

#pragma mark - NSTableViewDelegate
- (NSInteger) numberOfRowsInTableView:(NSTableView *) tableview {
    return [currentServers count];
}

- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id result;
    NSString *identifier = [tableColumn identifier];
    IRCServer *server = [currentServers objectAtIndex:row];

    if ([identifier isEqualToString:@"hostname"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"serverNameRowView" owner:self];
        if (textField == nil) {
            textField = [[NSTextField alloc] init];
            textField.identifier = @"serverNameRowView";
            [textField setBordered:NO];
        }

        [textField setStringValue: [server hostname]];
        result = textField;
    }
    else if ([identifier isEqualToString:@"port"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"port" owner:self];
        if (textField == nil) {
            textField = [[NSTextField alloc] init];
            textField.identifier = @"port";
            [textField setBordered:NO];
        }

        [textField setStringValue: [server.port stringValue]];
        result = textField;
    } else if ([identifier isEqualToString:@"ssl"]) {
        NSButton *checkbox = [tableView makeViewWithIdentifier:@"useSSLCheckBox" owner:self];
        if (checkbox == nil ) {
            checkbox = [[NSButton alloc] init];
            [checkbox setButtonType:NSSwitchButton];
            [checkbox setIdentifier:@"useSSLCheckBox"];
            [checkbox setTitle:@""];
        }

        if (server.useSSL) {
            [checkbox setState:NSOnState];
        } else {
            [checkbox setState:NSOffState];
        }

        result = checkbox;
    }
    else if ([identifier isEqualToString:@"username"]) {
        NSTextField *textField = [tableView makeViewWithIdentifier:@"serverUsername" owner:self];

        if (textField == nil) {
            textField = [[NSTextField alloc] init];
            textField.identifier = @"serverUsername";
            [textField setBordered:NO];
        }

        [textField setStringValue:[server username]];
        result = textField;
    } else if ([identifier isEqualToString:@"password"]) {
        NSSecureTextField *textField = [tableView makeViewWithIdentifier:@"password" owner:self];

        if (textField == nil) {
            textField = [[NSSecureTextField alloc] init];
            [textField setIdentifier:@"password"];
            [textField setBordered:NO];
        }

        [textField setStringValue:[server password]];
        result = textField;
    }

    return result;
}

- (NSIndexSet *)tableView:(NSTableView *)tableView
selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes {
    return 0;
}

@end
