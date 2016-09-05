
#import "RACSignal+Lazy.h"
#import "RACMulticastConnection.h"
#import "RACReplaySubject.h"
#import "RACSignal+Operations.h"

@implementation RACSignal(Lazy)

- (RACSignal *)replayLazilyAutoDisposed {
    RACMulticastConnection *connection = [self multicast:[RACReplaySubject subject]];
    return [[RACSignal
        defer:^{
            return [connection autoconnect];
        }]
    setNameWithFormat:@"[%@] -replayLazilyAutoDisposed", self.name];
}
@end
