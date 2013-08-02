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
        id hostnameLabel = [self createLabelWithIdentifier:@"hostname" superView:superview];
        [[hostname cell] setPlaceholderString:@"chat.freenode.net"];

        port = [self createTextFieldWithIdentifier:@"port" superView:superview];
        id portLabel = [self createLabelWithIdentifier:@"port" superView:superview];
        [[port cell] setPlaceholderString:@"6697"];

        username = [self createTextFieldWithIdentifier:@"username" superView:superview];
        id usernameLabel = [self createLabelWithIdentifier:@"username" superView:superview];
        [[username cell] setPlaceholderString:@"(optional)"];

        password = [self createSecureTextFieldWithIdentifier:@"password" superView:superview];
        id passwordLabel = [self createLabelWithIdentifier:@"password" superView:superview];
        [[password cell] setPlaceholderString:@"foobar"];

        channels = [self createTextFieldWithIdentifier:@"channels" superView:superview];
        id channelsLabel = [self createLabelWithIdentifier:@"channels" superView:superview];
        [[channels cell] setPlaceholderString:@"eg: 'techendo, nodejs, twerk, #freenode' (optional)"];

        NSButton *connect = [[NSButton alloc] init];
        [connect setIdentifier:@"connect"];
        [connect setTitle:@"Connect"];
        [connect setTarget:self];
        [connect setAction:@selector(connectToService)];
        [connect setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
        [connect setTranslatesAutoresizingMaskIntoConstraints:NO];
        [superview addSubview:connect];

        NSDictionary *views = NSDictionaryOfVariableBindings(hostname, hostnameLabel, port, portLabel,
                                                             username, usernameLabel, password, passwordLabel,
                                                             channels, channelsLabel, connect
                                                             );

        [[self window] makeFirstResponder:hostname];
        [hostname setNextKeyView:port];
        [port setNextKeyView:username];
        [username setNextKeyView:password];
        [password setNextKeyView:channels];
        [channels setNextKeyView:hostname];

        /*
         View layout
         */

        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[hostnameLabel]-[hostname(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[portLabel]-[port(>=50)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[usernameLabel]-[username(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[passwordLabel]-[password(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[channelsLabel]-[channels(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=80)-[connect]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];

        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[hostname]-[port]-(>=30,<=80)-[username]-[password]-[channels]-[connect]-(>=20)-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];
        
        for (NSView *view in @[hostname, port, username, password, channels]) {
            [view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
        }
    }
    
    return self;
}

- (NSTextField *) createLabelWithIdentifier:(NSString *) identifier superView:(NSView *) superView {
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
    [label setStringValue:[identifier capitalizedString]];
    [label setBackgroundColor:[NSColor clearColor]];
    [superView addSubview:label];

    return label;
}

- (NSTextField *) createTextFieldWithIdentifier:(NSString *) identifier superView:(NSView *) superView {
    NSTextField *field = [[NSTextField alloc] init];
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

        [[newWindow contentView] addSubview:chatView];
    }

    NSString *remoteHost = [hostname stringValue];
    UInt32 remotePort = [port intValue];
    BOOL useSSL = NO;

    if (remotePort == 0) {
        remotePort = 6697;
        useSSL = YES;
    }

    // what I think I'd like to do is actually prevent this action until all of the validations return TRUE
    if ([remoteHost isEqualToString:@""]) {
        remoteHost = @"chat.freenode.net";
    }

    [chatView connectToServer:remoteHost onPort:remotePort withUsername:[username stringValue] withPassword:[password stringValue] useSSL:useSSL];
}

- (void) shouldClose {
    [[self window] close];
}

@end
