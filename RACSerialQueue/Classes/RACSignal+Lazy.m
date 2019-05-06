
#import "RACSignal+Lazy.h"
#import "RACMulticastConnection.h"
#import "RACReplaySubject.h"
#import "RACSignal+Operations.h"

@implementation RACSignal(Lazy)

- (RACSignal *)replayLazilyAutoDisposed {
    RACMulticastConnection *connection = [self multicast:[[RACReplaySubject subject] setNameWithFormat:@"Subject[%@] -replayLazilyAutoDisposed", self.name]];
    return [[connection autoconnect] setNameWithFormat:@"[%@] -replayLazilyAutoDisposed", self.name];
}

@end
