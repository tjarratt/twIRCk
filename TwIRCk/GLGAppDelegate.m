//
//  GLGAppDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGAppDelegate.h"

@implementation GLGAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

#pragma mark - Application Lifecycle
- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
    responseLookup = [[GLGResponseCodes alloc] init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowClosing:)
                                                 name:NSWindowWillCloseNotification
                                               object:nil];

    self.windowController = [[NSWindowController alloc] initWithWindow:[self window]];

    // initialize any servers we might have, try to connect to them
    NSManagedObjectContext *context = [self managedObjectContext];
    NSEntityDescription *description = [NSEntityDescription entityForName:@"IRCServer" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:description];

    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:request error:&error];

    if (YES) {
        // for testing, create a chatview with some text inside of it, and then we'll add a tab view to its top
        NSSize size = NSMakeSize(800, 600);
        CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
        CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

        NSPoint origin = NSMakePoint((size.width - screenwidth) / 2, (size.height - screenheight) / 2);

        NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

        NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
        GLGChatView *chatView = [[GLGChatView alloc] initWithWindow:window];
        [[window contentView] addSubview:chatView];
    }
    else if ([fetchedObjects count] > 0) {
        serverWindowIsVisible = NO;

        // defaults for chat window size
        NSSize size = NSMakeSize(800, 600);
        CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
        CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

        NSPoint origin = NSMakePoint((size.width - screenwidth) / 2, (size.height - screenheight) / 2);

        NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);

        [fetchedObjects enumerateObjectsUsingBlock:^(NSManagedObject *obj, NSUInteger index, BOOL *stop) {
            IRCServer *server = (IRCServer *)obj;

            NSWindow *window = [[NSWindow alloc] initWithContentRect:frame styleMask:style backing:NSBackingStoreBuffered defer:NO];
            GLGChatView *chatView = [[GLGChatView alloc] initWithWindow:window];

            [chatView connectToServer:server];
            [window.contentView addSubview:chatView];
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

#pragma mark - CoreData
- (NSURL *) applicationFilesDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"GLG.TwIRCk"];
}

- (NSManagedObjectModel *) managedObjectModel {
    if (_managedObjectModel) {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;

    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];

    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            NSString *failureFormat = NSLocalizedString(@"Expected a folder to store application data, found a file (%@).", @"failureFolderToStoreAppDataMessage");
            NSString *failureDescription = [NSString stringWithFormat:failureFormat, [applicationFilesDirectory path]];

            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"GLG_TWIRC_ERR" code:101 userInfo:dict];

            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }

    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"TwIRCk.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _persistentStoreCoordinator = coordinator;

    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *) managedObjectContext {
    if (_managedObjectContext) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *) window {
    return [[self managedObjectContext] undoManager];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) sender {
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }

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

- (IBAction) openNewServerWindow:(id) sender {
    if (serverWindowIsVisible) {
        return;
    }

    NSRect windowRect = NSMakeRect(0, 0, 800, 600);
    NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;

    __strong NSWindow *newWindow = [[NSWindow alloc] initWithContentRect:windowRect styleMask:style backing:NSBackingStoreBuffered defer:NO];
    NSView *contentView = [newWindow contentView];
    GLGNewServer *newServerView = [[GLGNewServer alloc] initWithSuperView:contentView];
    [contentView addSubview:newServerView];

    [newWindow makeKeyAndOrderFront:NSApp];

    [[self windowController] setWindow:newWindow];
    serverWindowIsVisible = YES;
}

- (IBAction) quit:(id) sender {
    [NSApp terminate:self];
}

@end
