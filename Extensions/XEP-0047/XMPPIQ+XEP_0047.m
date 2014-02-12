//
//  XMPPIQ+XEP_0047.h
//  XMPPFramework
//
//  Created by Chris Ballinger on 2/11/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//
//  In-Band Bytestreams http://xmpp.org/extensions/xep-0047.html


#import "XMPPIQ+XEP_0047.h"
#import "NSXMLElement+XMPP.h"
#import "NSData+XMPP.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static NSString* const XMLNS_IBB = @"http://jabber.org/protocol/ibb";
static NSString* const XMLNS_STANZA = @"urn:ietf:params:xml:ns:xmpp-stanzas";

static NSString* const IBB_ELEMENT_DATA = @"data";
static NSString* const IBB_ELEMENT_OPEN = @"open";
static NSString* const IBB_ELEMENT_ERROR = @"error";

static NSString* const IBB_ATTRIBUTE_SESSION_ID = @"sid";
static NSString* const IBB_ATTRIBUTE_SEQUENCE = @"seq";

static NSString* const IBB_ERROR_FAILURE = @"service-unavailable";
static NSString* const IBB_ERROR_SMALLER_CHUNKS = @"resource-constraint";
static NSString* const IBB_ERROR_REJECT = @"not-acceptable";
static NSString* const IBB_ERROR_UNEXPECTED = @"item-not-found";

static NSString* const IBB_ERROR_TYPE = @"item-not-found";


static const NSUInteger kRecommendedBlockSize = 4096;

@implementation XMPPIQ (XEP_0047)


/*
 <iq from='romeo@montague.net/orchard'
 id='jn3h8g65'
 to='juliet@capulet.com/balcony'
 type='set'>
 <open xmlns='http://jabber.org/protocol/ibb'
 block-size='4096'
 sid='i781hf64'
 stanza='iq'/>
 </iq>
 */
+ (XMPPIQ *)inBandBytestreamRequestTo:(XMPPJID *)jid
                            elementID:(NSString *)eid
                            sessionID:(NSString *)sid {
    return [[XMPPIQ alloc] initInBandBytestreamRequestTo:jid elementID:eid sessionID:sid blockSize:kRecommendedBlockSize];
}

- (instancetype)initInBandBytestreamRequestTo:(XMPPJID *)jid
                                    elementID:(NSString *)eid
                                    sessionID:(NSString *)sid
                                    blockSize:(NSUInteger)blockSize
{
	if (self = [self initWithType:@"set" to:jid elementID:eid])
	{
		[self setupInBandRequestWithSessionID:sid blockSize:blockSize];
	}
	
	return self;
}

- (void)setupInBandRequestWithSessionID:(NSString*)sid blockSize:(NSUInteger)blockSize
{
	NSXMLElement *inBandOpen = [NSXMLElement elementWithName:IBB_ELEMENT_OPEN xmlns:XMLNS_IBB];
    [inBandOpen addAttributeWithName:@"block-size" unsignedIntegerValue:blockSize];
    [inBandOpen addAttributeWithName:IBB_ATTRIBUTE_SESSION_ID stringValue:sid];
	[inBandOpen addAttributeWithName:@"stanza" stringValue:@"iq"];
    
	[self addChild:inBandOpen];
}

/*<iq from='romeo@montague.net/orchard'
 id='us71g45j'
 to='juliet@capulet.com/balcony'
 type='set'>
 <close xmlns='http://jabber.org/protocol/ibb' sid='i781hf64'/>
 </iq>
 */
+ (XMPPIQ *)inBandBytestreamCloseTo:(XMPPJID *)jid
                          elementID:(NSString *)eid
                          sessionID:(NSString *)sid {
    XMPPIQ *closeIQ = [[XMPPIQ alloc] initInBandBytestreamCloseTo:jid elementID:eid sessionID:sid];
    return closeIQ;
}

- (instancetype)initInBandBytestreamCloseTo:(XMPPJID *)jid
                                  elementID:(NSString *)eid
                                  sessionID:(NSString *)sid {
    if (self = [self initWithType:@"set" to:jid elementID:eid]) {
        NSXMLElement *closeElement = [NSXMLElement elementWithName:@"close" xmlns:XMLNS_IBB];
        [closeElement addAttributeWithName:IBB_ATTRIBUTE_SESSION_ID stringValue:sid];
        [self addChild:closeElement];
    }
    return self;
}

- (XMPPIQ *)generateInBandBytestreamSuccessResponse {
    return [XMPPIQ iqWithType:@"result" to:[self from] elementID:[self elementID]];
}

- (XMPPIQ *)ibbErrorResponseWithType:(NSString*)type
                            response:(NSString*)response
{
    XMPPIQ *errorIQ = [XMPPIQ iqWithType:@"error" to:[self from] elementID:[self elementID]];
    NSXMLElement *errorElement = [NSXMLElement elementWithName:IBB_ELEMENT_ERROR];
    [errorElement addAttributeWithName:@"type" stringValue:type];
    NSXMLElement *responseElement = [NSXMLElement elementWithName:response xmlns:XMLNS_STANZA];
    [errorElement addChild:responseElement];
    [errorIQ addChild:errorElement];
    return errorIQ;
}

- (XMPPIQ *)generateInBandBytestreamFailureResponse {
    return [self ibbErrorResponseWithType:@"cancel" response:IBB_ERROR_FAILURE];
}

- (XMPPIQ *)generateInBandBytestreamSmallerChunksResponse {
    return [self ibbErrorResponseWithType:@"modify" response:IBB_ERROR_SMALLER_CHUNKS];
}

- (XMPPIQ *)generateInBandBytestreamRejectResponse {
    return [self ibbErrorResponseWithType:@"cancel" response:IBB_ERROR_REJECT];
}

- (XMPPIQ*)generateInBandBytestreamUnexpectedIBBResponse {
    return [self ibbErrorResponseWithType:@"cancel" response:IBB_ERROR_UNEXPECTED];
}


/*
 <iq from='romeo@montague.net/orchard'
 id='kr91n475'
 to='juliet@capulet.com/balcony'
 type='set'>
 <data xmlns='http://jabber.org/protocol/ibb' seq='0' sid='i781hf64'>
 qANQR1DBwU4DX7jmYZnncmUQB/9KuKBddzQH+tZ1ZywKK0yHKnq57kWq+RFtQdCJ
 WpdWpR0uQsuJe7+vh3NWn59/gTc5MDlX8dS9p0ovStmNcyLhxVgmqS8ZKhsblVeu
 IpQ0JgavABqibJolc3BKrVtVV1igKiX/N7Pi8RtY1K18toaMDhdEfhBRzO/XB0+P
 AQhYlRjNacGcslkhXqNjK5Va4tuOAPy2n1Q8UUrHbUd0g+xJ9Bm0G0LZXyvCWyKH
 kuNEHFQiLuCY6Iv0myq6iX6tjuHehZlFSh80b5BVV9tNLwNR5Eqz1klxMhoghJOA
 </data>
 </iq>
 */
+ (XMPPIQ *)inBandBytesTo:(XMPPJID *)jid
                elementID:(NSString *)eid
                     data:(NSData*)data
                 sequence:(uint16_t)seq
                sessionID:(NSString *)sid {
    return [[XMPPIQ alloc] initInBandBytesTo:jid elementID:eid data:data sequence:seq sessionID:sid];
}

- (instancetype) initInBandBytesTo:(XMPPJID *)jid elementID:(NSString *)eid data:(NSData *)data sequence:(uint16_t)seq sessionID:(NSString *)sid {
    if (self = [self initWithType:@"set" to:jid elementID:eid]) {
        NSXMLElement *dataElement = [NSXMLElement elementWithName:IBB_ELEMENT_DATA xmlns:XMLNS_IBB];
        [dataElement addAttributeWithName:IBB_ATTRIBUTE_SEQUENCE intValue:seq];
        [dataElement addAttributeWithName:IBB_ATTRIBUTE_SESSION_ID stringValue:sid];
        NSString *base64Data = [data xmpp_base64Encoded];
        [dataElement setStringValue:base64Data];
        [self addChild:dataElement];
    }
    return self;
}

- (BOOL) hasInBandBytestreamData {
    return ([self isSetIQ] && [self hasIBBElementWithName:IBB_ELEMENT_DATA]);
}

- (BOOL)isInBandBytestreamRequest {
    return ([self isSetIQ] && [self hasIBBElementWithName:IBB_ELEMENT_OPEN]);
}

- (BOOL)isInBandBytestreamSuccessResponse {
    return [self isResultIQ];
}

- (BOOL) isIBBErrorMessage {
    return ([self isErrorIQ] && [self elementForName:IBB_ELEMENT_ERROR]);
}

- (BOOL) hasIBBElementWithName:(NSString*)elementName {
    return ([self elementForName:elementName xmlns:XMLNS_IBB] ? YES : NO);
}

- (BOOL)hasInBandBytestreamError:(NSString*)error {
    if (![self isIBBErrorMessage]) {
        return NO;
    }
    NSXMLElement *errorElement = [self elementForName:IBB_ELEMENT_ERROR];
    NSArray *childElements = [errorElement elementsForXmlns:XMLNS_STANZA];
    NSXMLElement *stanzaElement = [childElements firstObject];
    return [[stanzaElement name] isEqualToString:error];
}

- (BOOL)isInBandBytestreamFailureResponse {
    return [self hasInBandBytestreamError:IBB_ERROR_FAILURE];
}

- (BOOL)isInBandBytestreamRejectResponse {
    return [self hasInBandBytestreamError:IBB_ERROR_REJECT];
}

- (BOOL)isInBandBytestreamSmallerChunksResponse {
    return [self hasInBandBytestreamError:IBB_ERROR_SMALLER_CHUNKS];
}

- (BOOL)isInBandBytestreamUnexpectedIBBResponse {
    return [self hasInBandBytestreamError:IBB_ERROR_UNEXPECTED];
}

- (NSData*)inBandBytestreamData {
    if (![self hasInBandBytestreamData]) {
        return nil;
    }
    NSXMLElement *dataElement = [self elementForName:IBB_ELEMENT_DATA xmlns:XMLNS_IBB];
    NSData *base64Data = [[dataElement stringValue] dataUsingEncoding:NSASCIIStringEncoding];
    NSData *data = [base64Data xmpp_base64Decoded];
    return data;
}

- (uint16_t)inBandBytestreamSequence {
    if (![self hasInBandBytestreamData]) {
        return 0;
    }
    NSXMLElement *dataElement = [self elementForName:IBB_ELEMENT_DATA xmlns:XMLNS_IBB];
    return [dataElement attributeUnsignedIntegerValueForName:IBB_ATTRIBUTE_SEQUENCE];
}

- (NSString*)inBandBytestreamSessionID {
    if (![self hasInBandBytestreamData]) {
        return nil;
    }
    NSXMLElement *dataElement = [self elementForName:IBB_ELEMENT_DATA xmlns:XMLNS_IBB];
    return [dataElement attributeStringValueForName:IBB_ATTRIBUTE_SESSION_ID];
}

@end
