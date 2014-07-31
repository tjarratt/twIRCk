#import "Cedar/SpecHelper.h"
#import "GLGResponseParser.h"
#import "GLGFakeResponseParserDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(GLGResponseParserSpec)

fdescribe(@"parsing messages from the wire", ^{
    __block NSString *readValue;
    __block GLGResponseParser *parser;
    __block GLGFakeResponseParserDelegate *delegate;

    beforeEach(^{
        parser = [[GLGResponseParser alloc] init];
        delegate = [[GLGFakeResponseParserDelegate alloc] init];
        [parser setDelegate:delegate];
    });

    it(@"should parse hostnames from messages", ^{
        readValue = @":jarmusch.freenode.net 372 :- zzz";
//        [[parser parseRawIRCString:readValue] fromHost] should equal(@"jarmusch.freenode.net");
    });

    it(@"should understand Nick Not Available messages", ^{
        readValue = @":pratchett.freenode.net 433 brucewayne batman :Nickname is already in use.";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedNickInUse));

//        [msg type] should equal(@"NickInUse");
//        [msg raw] should equal(readValue);
//        [msg message] should equal(@"The nick 'batman' is already in use. Attempting to use 'batman_'");
//        [msg payload] should equal(@"batman_");
    });

    it(@"should parse channel occupant messages", ^{
        readValue = @":hobbledehoy.freenode.net 353 #cheezburger :bruce @alfred batman robin";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(channel:didUpdateOccupants:)).with(@"#cheezburger").with(@[@"bruce", @"alfred", @"batman", @"robbin"]);
    });

    it(@"should parse ping messages", ^{
        readValue = @"PING :foo.bar.com";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(shouldRespondToPingRequest));
    });

    it(@"should read channel occupants", ^{
        readValue = @":gotham.freenode.net 353 #superheroes :@superman batman justice_league_bot";
        [parser parseRawIRCString:readValue];
        delegate should have_received(@selector(channel:didUpdateOccupants:)).with(@"#superheroes").with(@[@"superman", @"batman", @"justice_league_bot"]);
    });

    it(@"should pass MOTD messages to the tab for the entire server", ^{
        readValue = @":nowhere.freenode.net 372 yourNick :- HEY THIS IS THE MOTD";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedMOTDMessage:)).with(@"HEY THIS IS THE MOTD\n");
    });

    it(@"should parse nick change messages", ^{
        readValue = @":robin!~boywonder@justice.org NICK :nightwing";
        [parser parseRawIRCString:readValue];
        delegate should have_received(@selector(user:didChangeNickTo:)).with(@"robin").with(@"nightwing");
    });

    it(@"should parse NOTICE messages as though they came 'from' the server", ^{
        readValue = @":rajaniemi.freenode.net NOTICE #twirck :*** Notice -- TS for #twirck changed from 1383287673 to 1380312869";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedNoticeMessage:inChannel:)).with(@"*** Notice -- TS for #twirck changed from 1383287673 to 1380312869\n").with(@"rajaniemi.freenode.net");
    });

    it(@"should parse JOIN messages", ^{
        readValue = @":ChanServ!ChanServ@services. JOIN #twirck";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(user:didJoinChannel:withFullName:)).with(@"ChanServ").with(@"#twirck").with(@"ChanServ@services");
    });

    it(@"should parse PART messages", ^{
        readValue = @":et!~extraterrestrial@earth.gov #EARTH fuck this shit";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(user:didPartChannel:withFullNick:)).with(@"et").with(@"#someCoolChannel").with(@"extraterrestrial@earth.gov").with(@"#EARTH").with(@"fuck this shit");
    });

    it(@"should parse QUIT messages", ^{
        readValue = @":lysergic-dream!~lysergic-@unaffiliated/lysergic-dream QUIT :Excess Flood";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(userDidQuit:withMessage:)).with(@"lysergic-dream").with(@"Excess Flood");
    });

    it(@"should parse PRIVMSG messages", ^{
        readValue = @":auscompgeek!aucg@firefox/community/auscompgeek PRIVMSG #freenode :it's also possible to edit the named networks";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedPrivateMessage:fromNick:)).with(@"it's also possible to edit the named networks").with(@"auscompgeek");

        fail(@"not implemented");
    });
});

SPEC_END
