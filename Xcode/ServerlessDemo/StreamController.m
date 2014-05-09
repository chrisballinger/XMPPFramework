#import "StreamController.h"
#import "ServerlessDemoAppDelegate.h"
#import "GCDAsyncSocket.h"
#import "Service.h"
#import "P2PMessage.h"
#import "XMPP.h"
#import "NSXMLElement+XMPP.h"
#import "NSString+DDXML.h"
#import "DDLog.h"
#import "OTRKit.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@implementation StreamController

static StreamController *sharedInstance;

+ (void)initialize
{
	static BOOL initialized = NO;
	if(!initialized)
	{
		initialized = YES;
		sharedInstance = [[StreamController alloc] init];
	}
}

- (id)init
{
	// Only allow one instance of this class to ever be created
	if(sharedInstance)
	{
		return nil;
	}
	
	if((self = [super init]))
	{
		streamsDict = [[NSMutableDictionary alloc] initWithCapacity:4];
		serviceDict = [[NSMutableDictionary alloc] initWithCapacity:4];
        [[OTRKit sharedInstance] setupWithDataPath:nil];
        [OTRKit sharedInstance].delegate = self;
        [OTRKit sharedInstance].otrPolicy = OTRKitPolicyOpportunistic;
	}
	return self;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Public API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

+ (StreamController *)sharedInstance
{
	return sharedInstance;
}

- (void)startListening
{
	if (listeningSocket == nil)
	{
		listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	}
	
	NSError *error = nil;
	if (![listeningSocket acceptOnPort:0 error:&error])
	{
		DDLogError(@"Error setting up socket: %@", error);
	}
}

- (void)stopListening
{
	[listeningSocket disconnect];
}

- (UInt16)listeningPort
{
	return [listeningSocket localPort];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private API
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext
{
	ServerlessDemoAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	return appDelegate.managedObjectContext;
}

- (XMPPJID *)myJID
{
	ServerlessDemoAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	return appDelegate.myJID;
}

- (Service *)serviceWithAddress:(NSString *)addrStr
{
	if (addrStr == nil) return nil;
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Service"
	                                          inManagedObjectContext:[self managedObjectContext]];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"lastResolvedAddress == %@", addrStr];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchLimit:1];
	
	NSError *error = nil;
	NSArray *results = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
	
	if (results == nil)
	{
		DDLogError(@"Error searching for service with address \"%@\": %@, %@", addrStr, error, [error userInfo]);
		
		return nil;
	}
	else if ([results count] == 0)
	{
		DDLogWarn(@"Unable to find service with address \"%@\"", addrStr);
		
		return nil;
	}
	else
	{
		return [results objectAtIndex:0];
	}
}

- (id)nextXMPPStreamTag
{
	static NSInteger tag = 0;
	
	NSNumber *result = [NSNumber numberWithInteger:tag];
	tag++;
	
	return result;
}

- (Service *)serviceWithXMPPStream:(XMPPStream *)xmppStream
{
	NSManagedObjectID *managedObjectID = [serviceDict objectForKey:[xmppStream tag]];
	
	return (Service *)[[self managedObjectContext] objectWithID:managedObjectID];
}

- (XMPPStream*)xmppStreamWithService:(Service*)service {
    return [streamsDict objectForKey:service.objectID];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark GCDAsyncSocket Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)socket:(GCDAsyncSocket *)listenSock didAcceptNewSocket:(GCDAsyncSocket *)acceptedSock
{
	NSString *addrStr = [acceptedSock connectedHost];
	
	Service *service = [self serviceWithAddress:addrStr];
	if (service)
	{
		DDLogInfo(@"Accepting connection from service: %@", service.serviceDescription);
		
		id tag = [self nextXMPPStreamTag];
		
		XMPPStream *xmppStream = [[XMPPStream alloc] initP2PFrom:[self myJID]];
		
		[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
		xmppStream.tag = tag;
		
		[xmppStream connectP2PWithSocket:acceptedSock error:nil];
		
		[streamsDict setObject:xmppStream forKey:[service objectID]];
		[serviceDict setObject:[service objectID] forKey:tag];
	}
	else
	{
		DDLogWarn(@"Ignoring connection from unknown service (%@)", addrStr);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate Methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender willSendP2PFeatures:(NSXMLElement *)streamFeatures
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveP2PFeatures:(NSXMLElement *)streamFeatures
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	Service *service = [self serviceWithXMPPStream:sender];
	if (service)
	{
		NSString *msgBody = [[[message elementForName:@"body"] stringValue] stringByTrimming];
        
        
		if ([msgBody length] > 0)
		{
            [[OTRKit sharedInstance] decodeMessage:msgBody sender:service.displayName accountName:service.serviceName protocol:@"xmpp"];
		}
	}
}



- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, error);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
    NSManagedObjectID *serviceID = [serviceDict objectForKey:sender.tag];
	[serviceDict removeObjectForKey:sender.tag];
	[streamsDict removeObjectForKey:serviceID];
}

#pragma mark OTRKitDelegete methods

- (void) otrKit:(OTRKit *)otrKit injectMessage:(NSString *)message recipient:(NSString *)recipient accountName:(NSString *)accountName protocol:(NSString *)protocol {
    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogVerbose(@"injectMessage: %@ recipient: %@ accountName: %@ protocol %@", message, recipient, accountName, protocol);
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"serviceName == %@", accountName];
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Service"];
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        NSArray *services = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        Service *service = [services firstObject];
        
        XMPPStream *xmppStream = [streamsDict objectForKey:service.objectID];
        
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:message];
        
        NSXMLElement *xmppMessage = [NSXMLElement elementWithName:@"message"];
        [xmppMessage addAttributeWithName:@"type" stringValue:@"chat"];
        [xmppMessage addChild:body];
        
        [xmppStream sendElement:xmppMessage];
    });
}

- (void) otrKit:(OTRKit *)otrKit decodedMessage:(NSString *)message tlvs:(NSArray *)tlvs sender:(NSString *)sender accountName:(NSString *)accountName protocol:(NSString *)protocol {
    dispatch_async(dispatch_get_main_queue(), ^{
        DDLogVerbose(@"decodedMessage: %@ sender: %@ accountName: %@ protocol: %@", message, sender, accountName, protocol);
        for (OTRTLV *tlv in tlvs) {
            NSLog(@"tlv found: %@", tlv);
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"serviceName == %@", accountName];
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Service"];
        fetchRequest.predicate = predicate;
        NSError *error = nil;
        NSArray *services = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
        Service *service = [services firstObject];
        
        P2PMessage *msg = [NSEntityDescription insertNewObjectForEntityForName:@"P2PMessage"
                                                        inManagedObjectContext:[self managedObjectContext]];
        
        msg.content     = message;
        msg.isOutbound  = NO;
        msg.hasBeenRead = NO;
        msg.timeStamp   = [NSDate date];
        
        msg.service     = service;
        
        [[self managedObjectContext] save:nil];
    });
}


- (void) otrKit:(OTRKit *)otrKit updateMessageState:(OTRKitMessageState)messageState username:(NSString *)username accountName:(NSString *)accountName protocol:(NSString *)protocol {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (BOOL) otrKit:(OTRKit *)otrKit isRecipientLoggedIn:(NSString *)recipient accountName:(NSString *)accountName protocol:(NSString *)protocol {
    return YES;
}

- (void) otrKit:(OTRKit *)otrKit willStartGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void) otrKit:(OTRKit *)otrKit didFinishGeneratingPrivateKeyForAccountName:(NSString *)accountName protocol:(NSString *)protocol error:(NSError *)error {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void) otrKit:(OTRKit *)otrKit showFingerprintConfirmationForAccountName:(NSString *)accountName protocol:(NSString *)protocol userName:(NSString *)userName theirHash:(NSString *)theirHash ourHash:(NSString *)ourHash {
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
