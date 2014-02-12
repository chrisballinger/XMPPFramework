//
//  XMPPIQ+XEP_0047.h
//  XMPPFramework
//
//  Created by Chris Ballinger on 2/11/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//
//  In-Band Bytestreams http://xmpp.org/extensions/xep-0047.html

#import "XMPPIQ.h"

@interface XMPPIQ (XEP_0047)

+ (XMPPIQ *)inBandBytestreamRequestTo:(XMPPJID *)jid
                            elementID:(NSString *)eid
                            sessionID:(NSString *)sid;

- (instancetype)initInBandBytestreamRequestTo:(XMPPJID *)jid
                                    elementID:(NSString *)eid
                                    sessionID:(NSString *)sid
                                    blockSize:(NSUInteger)blockSize;

+ (XMPPIQ *)inBandBytestreamCloseTo:(XMPPJID *)jid
                          elementID:(NSString *)eid
                          sessionID:(NSString *)sid;

- (instancetype)initInBandBytestreamCloseTo:(XMPPJID *)jid
                                  elementID:(NSString *)eid
                                  sessionID:(NSString *)sid;

- (XMPPIQ *)generateInBandBytestreamSuccessResponse;
- (XMPPIQ *)generateInBandBytestreamFailureResponse;
- (XMPPIQ *)generateInBandBytestreamSmallerChunksResponse;
- (XMPPIQ *)generateInBandBytestreamRejectResponse;
- (XMPPIQ *)generateInBandBytestreamUnexpectedIBBResponse;

+ (XMPPIQ *)inBandBytesTo:(XMPPJID *)jid
                elementID:(NSString *)eid
                     data:(NSData*)data
                 sequence:(uint16_t)seq
                sessionID:(NSString *)sid;


- (instancetype)initInBandBytesTo:(XMPPJID *)jid
                        elementID:(NSString *)eid
                             data:(NSData*)data
                         sequence:(uint16_t)seq
                        sessionID:(NSString *)sid;

- (BOOL)isInBandBytestreamRequest;
- (BOOL)isInBandBytestreamSuccessResponse;
- (BOOL)isInBandBytestreamFailureResponse;
- (BOOL)isInBandBytestreamRejectResponse;
- (BOOL)isInBandBytestreamSmallerChunksResponse;
- (BOOL)isInBandBytestreamUnexpectedIBBResponse;

- (BOOL)hasInBandBytestreamData;

- (NSData*)inBandBytestreamData;
- (uint16_t)inBandBytestreamSequence;
- (NSString*)inBandBytestreamSessionID;
                
@end
