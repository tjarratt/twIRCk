#import "Cedar/SpecHelper.h"
#import "GLGResponseParser.h"
#import "GLGFakeResponseParserDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(GLGResponseParserSpec)

describe(@"parsing messages from the wire", ^{
    __block NSString *readValue;
    __block GLGResponseParser *parser;
    __block GLGFakeResponseParserDelegate *delegate;

    beforeEach(^{
        parser = [[GLGResponseParser alloc] init];
        delegate = [[GLGFakeResponseParserDelegate alloc] init];
        spy_on(delegate);
        [parser setDelegate:delegate];
    });

    it(@"should understand Nick Not Available messages", ^{
        readValue = @":pratchett.freenode.net 433 brucewayne batman :Nickname is already in use.";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedNickInUseWithDisplayMessage:))
        .with(@"The nick 'batman' is already in use. Attempting to use 'batman_'");
    });

    it(@"should parse channel occupant messages", ^{
        readValue = @":hobbledehoy.freenode.net 353 #cheezburger :bruce @alfred batman robin";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(channel:didUpdateOccupants:))
        .with(@"#cheezburger")
        .with(@[@"bruce", @"alfred", @"batman", @"robin"]);
    });

    it(@"should parse ping messages", ^{
        readValue = @"PING :foo.bar.com";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(shouldRespondToPingRequest));
    });

    it(@"should read channel occupants", ^{
        readValue = @":gotham.freenode.net 353 #superheroes :@superman batman justice_league_bot";
        [parser parseRawIRCString:readValue];
        delegate should have_received(@selector(channel:didUpdateOccupants:))
        .with(@"#superheroes")
        .with(@[@"superman", @"batman", @"justice_league_bot"]);
    });

    it(@"should pass MOTD messages to the tab for the entire server", ^{
        readValue = @":nowhere.freenode.net 372 yourNick :- HEY THIS IS THE MOTD";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedMOTDMessage:))
        .with(@"HEY THIS IS THE MOTD\n");
    });

    it(@"should parse nick change messages", ^{
        readValue = @":robin!~boywonder@justice.org NICK :nightwing";
        [parser parseRawIRCString:readValue];
        delegate should have_received(@selector(userWithNick:didChangeNickTo:withDisplayMessage:))
        .with(@"robin")
        .with(@"nightwing")
        .with(@"'robin' is now known as 'nightwing'");
    });

    it(@"should parse NOTICE messages as though they came 'from' the server", ^{
        readValue = @":rajaniemi.freenode.net NOTICE #twirck :*** Notice -- TS for #twirck changed from 1383287673 to 1380312869";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedNoticeMessage:inChannel:))
        .with(@"*** Notice -- TS for #twirck changed from 1383287673 to 1380312869\n")
        .with(@"rajaniemi.freenode.net");
    });

    it(@"should parse JOIN messages", ^{
        readValue = @":ChanServ!ChanServ@services JOIN #twirck";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(userWithNick:didJoinChannel:withFullName:withDisplayMessage:))
        .with(@"ChanServ")
        .with(@"#twirck")
        .with(@"ChanServ@services")
        .with(@"ChanServ (ChanServ@services) has joined.");
    });

    it(@"should parse PART messages", ^{
        readValue = @":et!~extraterrestrial@earth.gov PART #EARTH :fuck this shit";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(userWithNick:didPartChannel:withFullNick:andPartMessage:))
        .with(@"et")
        .with(@"#EARTH")
        .with(@"~extraterrestrial@earth.gov")
        .with(@"et (~extraterrestrial@earth.gov) has left (fuck this shit).");
    });

    it(@"should part PART messages without additional messages", ^{
        readValue = @":vader!~anakin@deathstar.gov PART #tattooine :";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(userWithNick:didPartChannel:withFullNick:andPartMessage:))
        .with(@"vader")
        .with(@"#tattooine")
        .with(@"~anakin@deathstar.gov")
        .with(@"vader (~anakin@deathstar.gov) has left.");
    });

    it(@"should parse QUIT messages", ^{
        readValue = @":lysergic-dream!~lysergic-@unaffiliated/lysergic-dream QUIT :Excess Flood";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(userDidQuit:withMessage:))
        .with(@"lysergic-dream")
        .with(@"lysergic-dream (~lysergic-@unaffiliated/lysergic-dream) has quit (Excess Flood).");
    });

    it(@"should parse messages to channels", ^{
        readValue = @":auscompgeek!aucg@firefox/community/auscompgeek PRIVMSG #freenode :it's also possible to edit the named networks";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedPrivateMessage:fromNick:inChannel:))
        .with(@"<auscompgeek> it's also possible to edit the named networks")
        .with(@"auscompgeek")
        .with(@"#freenode");
    });

    it(@"should parse messages directed to the user", ^{
        readValue = @":palpatine!theEmperor@deathstar.gov PRIVMSG vader :'together we can rule the universe' ? that's some whack shit";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedPrivateMessage:fromNick:inChannel:))
        .with(@"<palpatine> 'together we can rule the universe' ? that's some whack shit")
        .with(@"palpatine")
        .with(@"vader");
    });

    it(@"should parse all other messages as regular messages", ^{
        readValue = @":31173HAXX@127.0.0.1 DELETE #allyourbase :where 1=1;";
        [parser parseRawIRCString:readValue];

        delegate should have_received(@selector(receivedUncategorizedMessage:))
        .with(readValue);
    });
});

SPEC_END
