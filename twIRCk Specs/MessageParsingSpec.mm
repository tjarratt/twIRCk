#import "GLGIRCParser.h"
#import "GLGIRCMessage.h"
#import "Cedar/SpecHelper.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MessageParsingSpec)

describe(@"User input parsing", ^{
    __block GLGIRCMessage *msg;

    describe(@"#parseUserInput", ^{
        describe(@"parsing command messages", ^{
            describe(@"joining channels", ^{
                it(@"should parse /join messages without an octothorpe", ^{
                    msg = [GLGIRCParser parseUserInput:@"/join cheese_lovers"];

                    [msg type] should equal(@"join");
                    [msg raw] should equal(@"JOIN #cheese_lovers");
                    [msg message] should equal(@"/join #cheese_lovers");
                    [msg payload] should equal(@"#cheese_lovers");
                });

                it(@"should parse /join messages with an octothorpe", ^{
                    msg = [GLGIRCParser parseUserInput:@"/join #cheese_haters"];

                    [msg type] should equal(@"join");
                    [msg raw] should equal(@"JOIN #cheese_haters");
                    [msg message] should equal(@"/join #cheese_haters");
                    [msg payload] should equal(@"#cheese_haters");
                });
            });

            describe(@"parsing /part messages", ^{
                it(@"should parse /part messages", ^{
                    msg = [GLGIRCParser parseUserInput:@"/part losers"];

                    [msg type] should equal(@"part");
                    [msg raw] should equal(@"PART #losers http://twIRCk.com (sometimes you just gotta twIRCk it!)");
                    [msg message] should equal(@"/part #losers http://twIRCk.com (sometimes you just gotta twIRCk it!)");
                    [msg payload] should equal(@"#losers");
                });

                it(@"should respect custom /part messages", ^{
                    msg = [GLGIRCParser parseUserInput:@"/part haskell Tis a silly place, let us not go there"];

                    [msg type] should equal(@"part");
                    [msg raw] should equal(@"PART #haskell Tis a silly place, let us not go there");
                    [msg message] should equal(@"/part #haskell Tis a silly place, let us not go there");
                    [msg payload] should equal(@"#haskell");
                });

                it(@"should use the current channel if none is specified", ^{
                    msg = [GLGIRCParser parseUserInput:@"/part"];

                    [msg type] should equal(@"part");
                    [msg raw] should equal(@"PART <__channel__> http://twIRCk.com (sometimes you just gotta twIRCk it!)");
                    [msg message] should equal(@"/part <__channel__> http://twIRCk.com (sometimes you just gotta twIRCk it!)");
                    [msg payload] should equal(@"<__channel__>");
                });
            });

            describe(@"parsing /msg private messages", ^{
                it(@"should parse private messages as /msg", ^{
                    msg = [GLGIRCParser parseUserInput:@"/msg god hey man I got some good ideas for the new NEW testament"];

                    [msg type] should equal(@"msg");
                    [msg raw] should equal(@"PRIVMSG god :hey man I got some good ideas for the new NEW testament");
                    [msg message] should equal(@"<<__nick__>> hey man I got some good ideas for the new NEW testament");
                    [msg payload] should equal(@"god");
                });

                it(@"should parse private messages with /whisper", ^{
                    msg = [GLGIRCParser parseUserInput:@"/whisper devil WTS soul. LF primordial saronite"];

                    [msg type] should equal(@"msg");
                    [msg raw] should equal(@"PRIVMSG devil :WTS soul. LF primordial saronite");
                    [msg message] should equal(@"<<__nick__>> WTS soul. LF primordial saronite");
                    [msg payload] should equal(@"devil");
                });
            });

            it(@"should parse /who messages", ^{
                msg = [GLGIRCParser parseUserInput:@"/who batman"];

                [msg type] should equal(@"who");
                [msg raw] should equal(@"WHO batman");
                [msg message] should equal(@"/who batman");
            });

            // TODO needs to be able to support binary in strings
            xit(@"should parse /me messages", ^{
                msg = [GLGIRCParser parseUserInput:@"/me twircks it!"];

                [msg type] should equal(@"me");
                [msg raw] should equal(@"PRIVMSG <__channel__> \u0001ACTION twirkcs it!\u0001");
                [msg message] should equal(@"<__nick__> twicks it!");
            });

            it(@"should parse /nick messages", ^{
                msg = [GLGIRCParser parseUserInput:@"/nick bruceWayne"];

                [msg type] should equal(@"nick");
                [msg raw] should equal(@"NICK bruceWayne");
                [msg message] should equal(@"/nick bruceWayne");
                [msg payload] should equal(@"bruceWayne");
            });

            it(@"should parse /pass messages", ^{
                msg = [GLGIRCParser parseUserInput:@"/pass ILoveMyDeadGaySon"];

                [msg type] should equal(@"pass");
                [msg raw] should equal(@"PASS ILoveMyDeadGaySon");
                [msg message] should equal(@"/pass ILoveMyDeadGaySon");
                [msg payload] should equal(@"ILoveMyDeadGaySon");
            });
            
            it(@"should parse /topic messages", ^{
                msg = [GLGIRCParser parseUserInput:@"/topic a new version of twIRCk.app is available! Please update now and report any bugs"];

                [msg type] should equal(@"topic");
                [msg raw] should equal(@"TOPIC <__channel__> a new version of twIRCk.app is available! Please update now and report any bugs");
                [msg message] should equal(@"/topic a new version of twIRCk.app is available! Please update now and report any bugs");
            });
            
            it(@"should treat other /cmd messages as having no target", ^{
                msg = [GLGIRCParser parseUserInput:@"/foo bar baz buz"];

                [msg type] should equal(@"foo");
                [msg raw] should equal(@"FOO bar baz buz");
                [msg message] should equal(@"/foo bar baz buz");
            });
        });

        it(@"should treat all other messages as a message in the current channel", ^{
            msg = [GLGIRCParser parseUserInput:@"Good morning Vietnam!"];

            [msg type] should equal(@"msg");
            [msg raw] should equal(@"PRIVMSG <__channel__> :Good morning Vietnam!");
            [msg message] should equal(@"<<__nick__>> Good morning Vietnam!");
        });
    });
});

describe(@"parsing messages from the wire", ^{
    __block NSString *readValue;
    __block GLGIRCMessage *msg;

    it(@"should parse hostnames from messages", ^{
        readValue = @":jarmusch.freenode.net 372 :- zzz";
        [[GLGIRCParser parseRawIRCString:readValue] fromHost] should equal(@"jarmusch.freenode.net");
    });

    it(@"should understand Nick Not Available messages", ^{
        readValue = @":pratchett.freenode.net 433 brucewayne batman :Nickname is already in use.";
        msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"NickInUse");
        [msg raw] should equal(readValue);
        [msg message] should equal(@"The nick 'batman' is already in use. Attempting to use 'batman_'");
        [msg payload] should equal(@"batman_");
    });

    it(@"should parse channel occupant messages", ^{
        readValue = @":hobbledehoy.freenode.net 353 #cheezburger :bruce @alfred batman robin";
        msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"ChannelOccupants");
        [msg payload] should equal(@{
                                     @"channel": @"#cheezburger",
                                     @"occupants": @[@"bruce", @"alfred", @"batman", @"robin"]
                                     });
    });

    it(@"should parse ping messages", ^{
        readValue = @"PING :foo.bar.com";
        GLGIRCMessage *msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"ping");
    });

    it(@"should read channel occupants", ^{
        readValue = @":gotham.freenode.net 353 #superheros :@superman batman justice_league_bot";
        GLGIRCMessage *msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"ChannelOccupants");

        NSDictionary * dict = [msg payload];
        [dict valueForKey:@"channel"] should equal(@"#superheros");
        [dict valueForKey:@"occupants"] should equal(@[@"superman", @"batman", @"justice_league_bot"]);
    });

    it(@"should pass MOTD messages to the tab for the entire server", ^{
        readValue = @":nowhere.freenode.net 372 yourNick :- HEY THIS IS THE MOTD";
        GLGIRCMessage *msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"MOTD");
        [msg message] should equal(@"HEY THIS IS THE MOTD\n");
    });

    it(@"should parse nick change messages", ^{
        readValue = @":robin!~boywonder@justice.org NICK :nightwing";
        GLGIRCMessage *msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"NickChange");

        NSDictionary *dict = (NSDictionary *) msg.payload;
        [dict valueForKey:@"newNick"] should equal(@"nightwing");
        [dict valueForKey:@"oldNick"] should equal(@"robin");
    });

    it(@"should parse NOTICE messages as though they came 'from' the server", ^{
        readValue = @":rajaniemi.freenode.net NOTICE #twirck :*** Notice -- TS for #twirck changed from 1383287673 to 1380312869";
        GLGIRCMessage *msg = [GLGIRCParser parseRawIRCString:readValue];

        [msg type] should equal(@"NOTICE");
        [msg fromHost] should equal(@"rajaniemi.freenode.net");
        [msg message] should equal(@"*** Notice -- TS for #twirck changed from 1383287673 to 1380312869");
    });

    it(@"should parse JOIN messages", ^{
        readValue = @":ChanServ!ChanServ@services. JOIN #twirck";
    });

    it(@"should parse PART messages", ^{
        readValue = @":et!~extraterrestrial@earth.gov ";
    });

    it(@"should parse QUIT messages", ^{
        fail(@"not implemented");
    });

    it(@"should parse PRIVMSG messages", ^{
        fail(@"not implemented");
    });

    describe(@"ignoring some message types", ^{
        it(@"should ignore 'end of MOTD' messages", ^{
            readValue = @":chat.freenode.net 376 :NO_MORE_MOTD";
            [GLGIRCParser parseRawIRCString:readValue] should_not be_truthy;
        });

        it(@"should ignore 'end of names' messages", ^{
            readValue = @":foo.freenode.net 366 #fuzzbat :WHATEVER";
            [GLGIRCParser parseRawIRCString:readValue] should_not be_truthy;
        });
    });
});

SPEC_END
