//
//  GLGNewServer.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/31/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGNewServer.h"

@implementation GLGNewServer

- (id) initWithSuperView:(NSView *) superview {
    if (self = [super init]) {
        hostname = [self createTextFieldWithIdentifier:@"hostname" superView:superview];
        [hostname setDefaultValue:@"chat.freenode.net"];
        id hostnameLabel = [self createLabelWithIdentifier:@"hostname" localizedTag:@"hostnameLabel" superView:superview];

        port = [self createTextFieldWithIdentifier:@"port" superView:superview];
        [port setDefaultValue:@"6697"];
        id portLabel = [self createLabelWithIdentifier:@"port" localizedTag:@"portLabel" superView:superview];

        ssl = [self createCheckboxWithIdentifier:@"ssl" superView:superview];
        [ssl setState:NSOnState];
        id sslLabel = [self createLabelWithIdentifier:@"ssl" localizedTag:@"sslLabel" superView:superview];
        [sslLabel setStringValue:NSLocalizedString(@"Use SSL", "uses-SSL-Label")];

        username = [self createTextFieldWithIdentifier:@"username" superView:superview];
        CGFloat scale = (CGFloat) arc4random() / 0x100000000;
        int randomValue = 10000 * scale;
        [username setDefaultValue:[NSString stringWithFormat:@"twirck-user-%d", randomValue]];

        id usernameLabel = [self createLabelWithIdentifier:@"username" localizedTag:@"usernameLabel" superView:superview];
        [[username cell] setPlaceholderString:NSLocalizedString(@"(optional)", @"optionalValue")];

        password = [self createSecureTextFieldWithIdentifier:@"password" superView:superview];
        [[password cell] setPlaceholderString:@"***"];
        id passwordLabel = [self createLabelWithIdentifier:@"password" localizedTag:@"passwordLabel" superView:superview];

        channels = [self createTextFieldWithIdentifier:@"channels" superView:superview];
        [channels setDefaultValue:@"techendo, twirck, freenode"];
        id channelsLabel = [self createLabelWithIdentifier:@"channels" localizedTag:@"channelsLabel" superView:superview];
        [[channels cell] setPlaceholderString:@"techendo, twirck, freenode (optional)"];

        NSButton *connect = [[NSButton alloc] init];
        [connect setIdentifier:@"connect"];
        [connect setTitle:NSLocalizedString(@"Connect", @"connectButtonLabel")];
        [connect setTarget:self];
        [connect setAction:@selector(connectToService)];
        [connect setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
        [connect setTranslatesAutoresizingMaskIntoConstraints:NO];
        [connect setBezelStyle:NSRoundedBezelStyle];
        [superview addSubview:connect];

        NSDictionary *views = NSDictionaryOfVariableBindings(hostname, hostnameLabel, port, portLabel, ssl, sslLabel,
                                                             username, usernameLabel, password, passwordLabel,
                                                             channels, channelsLabel, connect
                                                             );

        [[self window] makeFirstResponder:hostname];
        [hostname setNextKeyView:port];
        [port setNextKeyView:ssl];
        [ssl setNextKeyView:username];
        [username setNextKeyView:password];
        [password setNextKeyView:channels];
        [channels setNextKeyView:connect];
        [connect setNextKeyView:hostname];

        /*
         View layout, the AutoLayout Secret Sauce™
        */
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[hostnameLabel]-[hostname(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[portLabel]-[port(>=50)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[sslLabel]-[ssl(>=20)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[usernameLabel]-[username(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[passwordLabel]-[password(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[channelsLabel]-[channels(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=80)-[connect]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];

        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[hostname]-[port]-[ssl]-(>=30,<=50)-[username]-[password]-[channels]-[connect]-(>=20)-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
        
        for (NSView *view in @[hostname, port, ssl, username, password, channels]) {
            [view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
        }
    }
    
    return self;
}

#pragma mark - View Helpers
- (NSButton *) createCheckboxWithIdentifier:(NSString *) identifier superView:superview {
    NSButton *checkbox = [[NSButton alloc] init];
    [checkbox setButtonType:NSSwitchButton];
    [checkbox setIdentifier:identifier];
    [checkbox setTitle:@""];
    [checkbox setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    [checkbox setTranslatesAutoresizingMaskIntoConstraints:NO];
    [superview addSubview:checkbox];

    return checkbox;
}

- (NSTextField *) createLabelWithIdentifier:(NSString *) identifier localizedTag:(NSString *) localeTag superView:(NSView *) superView {
    NSTextField *label = [[NSTextField alloc] init];
    [label setIdentifier:[identifier stringByAppendingString:@"-label"]];
    [[label cell] setControlSize:NSSmallControlSize];
    [label setBordered:NO];
    [label setBezeled:NO];
    [label setSelectable:NO];
    [label setEditable:NO];
    [label setFont:[NSFont systemFontOfSize:11.0]];
    [label setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    [label setTranslatesAutoresizingMaskIntoConstraints:NO];
    [label setStringValue:NSLocalizedString([identifier capitalizedString], localeTag)];
    [label setBackgroundColor:[NSColor clearColor]];
    [superView addSubview:label];

    return label;
}

- (GLGDefaultValueTextField *) createTextFieldWithIdentifier:(NSString *) identifier superView:(NSView *) superView {
    GLGDefaultValueTextField *field = [[GLGDefaultValueTextField alloc] init];
    [field setIdentifier:identifier];
    [[field cell] setControlSize:NSSmallControlSize];
    [field setBordered:YES];
    [field setBezeled:YES];
    [field setSelectable:YES];
    [field setEditable:YES];
    [field setFont:[NSFont systemFontOfSize:11.0]];
    [field setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    [field setTranslatesAutoresizingMaskIntoConstraints:NO];
    [field setTarget:self];
    [field setAction:@selector(connectToService)];

    [superView addSubview:field];

    return field;
}

- (NSSecureTextField *) createSecureTextFieldWithIdentifier:(NSString *) identifier superView:(NSView *) superView {
    NSSecureTextField *field = [[NSSecureTextField alloc] init];
    [field setIdentifier:@"identifier"];
    [[field cell] setControlSize:NSSmallControlSize];
    [field setBordered:YES];
    [field setBezeled:YES];
    [field setEditable:YES];
    [field setFont:[NSFont systemFontOfSize:11.0]];
    [field setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    [field setTranslatesAutoresizingMaskIntoConstraints:NO];
    [field setTarget:self];
    [field setAction:@selector(connectToService)];

    [superView addSubview:field];

    return field;
}

#pragma mark - IBActions
- (void) connectToService {
    NSString *remoteHost = [hostname stringValue];
    UInt32 remotePort = [port intValue];
    useSSL = ([ssl state] == NSOnState || remotePort == 6697) ? YES : NO;

    SCNetworkConnectionFlags flags = 0;
    const char *hostName = [remoteHost cStringUsingEncoding:NSASCIIStringEncoding];
    SCNetworkReachabilityRef target = SCNetworkReachabilityCreateWithName(NULL, hostName);
    BOOL ok = SCNetworkReachabilityGetFlags(target, &flags);
    if (!ok || flags == 0) {
        NSString *failure = NSLocalizedString(@"Could not connect to server. Ensure your hostname is correct and that you are connected to the internet.", @"failureConnectToHostOnPort");

        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:failure forKey:NSLocalizedDescriptionKey];
        NSError *error = [NSError errorWithDomain:@"GLG_TWIRC_ERR" code:200 userInfo:dict];

        [[NSApplication sharedApplication] presentError:error];
        return NSLog(@"big trouble in little IRC client. Could not open write stream to %@ on port %d", remoteHost, remotePort);
    }

    [port setIntValue:remotePort];
    if (useSSL) { [ssl setState:NSOnState]; }
    else { [ssl setState:NSOffState]; }

    NSCharacterSet *delimiters = [NSCharacterSet characterSetWithCharactersInString:@", "];
    NSArray *chans = [[channels stringValue] componentsSeparatedByCharactersInSet:delimiters];
    NSMutableArray *mutableChannels = [[NSMutableArray alloc] init];

    [chans enumerateObjectsUsingBlock:^(NSString *chan, NSUInteger index, BOOL *stop) {
        NSString *theChan = [chan stringByTrimmingCharactersInSet:delimiters];
        if ([theChan length] == 0) { return; }
        
        [mutableChannels addObject:theChan];
    }];

    NSManagedObjectContext *context = [GLGManagedObjectContext managedObjectContext];

    __block IRCServer *server = [NSEntityDescription insertNewObjectForEntityForName:@"IRCServer" inManagedObjectContext:context];
    [server setHostname:remoteHost];
    [server setPort:[NSNumber numberWithInt:remotePort]];
    [server setUsername:[username stringValue]];
    [server setPassword:[password stringValue]];
    [server setUseSSL:useSSL];

    NSMutableSet *channelModels = [[NSMutableSet alloc] init];
    for (int i = 0; i < [mutableChannels count]; ++i) {
        IRCChannel *channel = [NSEntityDescription insertNewObjectForEntityForName:@"IRCChannel" inManagedObjectContext:context];
        [channel setName:[mutableChannels objectAtIndex:i]];
        [channel setServer:server];
        [channel setAutojoin:YES];
        [channelModels addObject:channel];
    }

    NSError *error;
    [context save:&error];

    if (error) {
        // need to show this as a validation error *somehow*
        NSLog(@"error saving servers and channels");
        NSLog(@"%@", [error localizedDescription]);
        return NSLog(@"%@", [error userInfo]);
    }

    GLGAppDelegate *delegate = [NSApp delegate];
    GLGChatView *chatView = [delegate chatView];
    if (!chatView) {
        NSSize size = NSMakeSize(800, 600);
        CGFloat screenwidth = [[NSScreen mainScreen] frame].size.width;
        CGFloat screenheight = [[NSScreen mainScreen] frame].size.height;

        NSPoint origin = NSMakePoint((size.width - screenwidth) / 2, (size.height - screenheight) / 2);

        NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        NSRect frame = NSMakeRect(origin.x, origin.y, size.width, size.height);
        NSWindow *newWindow = [[NSWindow alloc] initWithContentRect:frame
                                                          styleMask:style backing:NSBackingStoreBuffered defer:NO];
        [newWindow makeKeyAndOrderFront:NSApp];

        chatView = [[GLGChatView alloc] initWithWindow:newWindow];
        [chatView setConnectView:self];
        [delegate setChatView:chatView];

        [[newWindow contentView] addSubview:chatView];
    }

    [chatView connectToServer:server];
}

- (void) shouldClose {
    [[self window] close];
}

@end
