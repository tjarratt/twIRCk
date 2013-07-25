//
//  GLGAppDelegate.m
//  TwIRCk
//
//  Created by Tim Jarratt on 7/23/13.
//  Copyright (c) 2013 General Linear Group. All rights reserved.
//

#import "GLGAppDelegate.h"

@implementation GLGAppDelegate

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
    [superView addSubview:field];

    return field;
}

- (void)applicationDidFinishLaunching:(NSNotification *) aNotification {
    NSView *contentView = [[self window] contentView];
    responseLookup = [[GLGResponseCodes alloc] init];

    hostname = [self createTextFieldWithIdentifier:@"hostname" superView:contentView];
    id hostnameLabel = [self createLabelWithIdentifier:@"hostname" superView:contentView];
    [[hostname cell] setPlaceholderString:@"chat.freenode.net"];

    port = [self createTextFieldWithIdentifier:@"port" superView:contentView];
    id portLabel = [self createLabelWithIdentifier:@"port" superView:contentView];
    [[port cell] setPlaceholderString:@"6697"];

    username = [self createTextFieldWithIdentifier:@"username" superView:contentView];
    id usernameLabel = [self createLabelWithIdentifier:@"username" superView:contentView];
    [[username cell] setPlaceholderString:@"(optional)"];

    password = [self createSecureTextFieldWithIdentifier:@"password" superView:contentView];
    id passwordLabel = [self createLabelWithIdentifier:@"password" superView:contentView];
    [[password cell] setPlaceholderString:@"foobar"];

    channels = [self createTextFieldWithIdentifier:@"channels" superView:contentView];
    id channelsLabel = [self createLabelWithIdentifier:@"channels" superView:contentView];
    [[channels cell] setPlaceholderString:@"eg: 'techendo, nodejs, twerk, #freenode' (optional)"];

    NSButton *connect = [[NSButton alloc] init];
    [connect setIdentifier:@"connect"];
    [connect setTitle:@"Connect"];
    [connect setTarget:self];
    [connect setAction:@selector(connectToService)];
    [connect setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
    [connect setTranslatesAutoresizingMaskIntoConstraints:NO];
    [contentView addSubview:connect];

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

    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[hostnameLabel]-[hostname(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[portLabel]-[port(>=50)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[usernameLabel]-[username(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[passwordLabel]-[password(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[channelsLabel]-[channels(>=200)]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=80)-[connect]-|" options:NSLayoutFormatAlignAllCenterY metrics:nil views:views]];

    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[hostname]-[port]-(>=30,<=80)-[username]-[password]-[channels]-[connect]-(>=20)-|" options:NSLayoutFormatAlignAllLeading metrics:nil views:views]];

    for (NSView *view in @[hostname, port, username, password, channels]) {
        [view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    }

    NSSize minSize = NSMakeSize(400, 80);
    NSSize maxSize = NSMakeSize(500, 300);
    [self.window setMinSize:minSize];
    [self.window setMaxSize:maxSize];
}

- (void) connectToService {
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

    NSURL *remoteURL = [NSURL URLWithString:remoteHost];
    if (!remoteURL) {
        // oops: display some validation
        NSLog(@"Not a valid hostname!");
        return;
    }

    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[remoteURL host], remotePort, &readStream, &writeStream);

    inputStream = (__bridge_transfer NSInputStream *) readStream;
    reader = [[GLGReadDelegate alloc] init];
    [inputStream setDelegate:reader];

    outputStream = (__bridge_transfer NSOutputStream *) writeStream;
    writer = [[GLGWriteDelegate alloc] init];
    [outputStream setDelegate:writer];

    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    if (useSSL) {
        [inputStream setProperty:NSStreamSocketSecurityLevelTLSv1 forKey:NSStreamSocketSecurityLevelKey];
    }

    [inputStream open];
    [outputStream open];

    // set some initial things like "oh hey, send the pass, nick and username to the server on a queue
}

@end
