#import <Foundation/Foundation.h>
#import "OTRKit.h"

@class GCDAsyncSocket;
@class Service;

@interface StreamController : NSObject <OTRKitDelegate>
{
	GCDAsyncSocket *listeningSocket;
	NSMutableDictionary *serviceDict;
    NSMutableDictionary *streamsDict;
}

+ (StreamController *)sharedInstance;

- (void)startListening;
- (void)stopListening;

- (UInt16)listeningPort;

@end
