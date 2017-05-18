
//
//  RACSerialQueue.m
//  RACSerialQueue
//
//  Created by Hai Feng Kao on 2016/06/03.
//
//

#import "RACSerialQueue.h"
#import <Foundation/Foundation.h>
#import "RACEXTScope.h"
#import "RACSignal.h"
#import "RACReplaySubject.h"
#import "NSObject+RACDeallocating.h"
#import "RACSignal+Operations.h"
#import "RACSignal+Lazy.h"

@interface RACSerialQueue()
@property (strong) RACSubject* subject; // it will receive the signals and put them in queue
@property (strong) RACSignal* queue; // the serial queue
@property (assign) BOOL shouldUseMainThread;
@property (assign) BOOL shouldStop;
@property (strong) RACSubject* hasStopped;
@end

@implementation RACSerialQueue
- (instancetype)init
{
    if (self = [super init]) {
        
        RACSubject* hasStopped = [RACReplaySubject replaySubjectWithCapacity:1];
        RACSubject* subject = [RACSubject subject];
        RACSignal* queue = [[[subject concat] takeUntil:[RACObserve(self, shouldStop) ignore:@NO]] takeUntil:self.rac_willDeallocSignal];
        _hasStopped = hasStopped;
        _subject = subject;
        _queue = queue;

        [queue subscribeNext:^(id x) {
            // activate the queue
        } error:^(NSError *error) {
            NSCAssert(!error, @"should not receive any errors");
        } completed:^{
           // the queue has stopped
           [hasStopped sendNext:@(1)];
           [hasStopped sendCompleted];
        }];
    }

    return self;
}

- (void)stop
{
    self.shouldStop = YES;
} 

- (RACSignal*)hasStoppedSignal
{
    return [self.hasStopped takeUntil:self.rac_willDeallocSignal];
} 

/** 
  * If you want the signal to deliver on the main thread, call this method right after init
  * 
  */
- (void)useMainThread
{
    self.shouldUseMainThread = YES;
}

/** 
  * execute the signalBlock
  *
  * @return a subject. If the subject has been completed, the opertaion in signalBlock will be be executed
  */
- (RACSubject *)addSignal:(RACSignal*)signalToBeExecuted
{
    NSParameterAssert(!self.shouldStop); // there is no way to start a stopped queue again
    NSParameterAssert(signalToBeExecuted); // are you kidding me?

    if (self.shouldUseMainThread) {
        // TODO: i'm too lazy to implement this stuff. A simple assert will work as well
        NSAssert([NSOperationQueue.currentQueue isEqual:NSOperationQueue.mainQueue] || [NSThread isMainThread], @"if you call execute on main thread, the signal will be delivered on main thread as well");
    }

    RACSubject* result = [RACReplaySubject subject]; // signalBlock might be executed before the result is subscribed

    __block BOOL isCancelled = NO;
    @weakify(self);
    [result subscribeCompleted:^{
        @strongify(self);
        @synchronized(self) { // protect isCancelled
            isCancelled = YES;    
        }
    }];

    @weakify(result);
    RACSignal* signal = [RACSignal defer:^(){
        @strongify(result);
        @strongify(self);

        @synchronized(self) { // protect isCancelled
            if (isCancelled) {
                // nothing to do, just return
                return [RACSignal empty];
            } 

            if (!result) {
                // user doesn't want to control the queue's behavior nor getting the sendNext values
                return signalToBeExecuted;
            } else {
                // pipe the values to result
                RACSignal* replaySignal = [signalToBeExecuted replayLazilyAutoDisposed];
                RACSignal* signal = [replaySignal takeUntil:[[result ignoreValues] materialize]];
                [signal subscribeNext:^(id x) {
                    [result sendNext:x];
                } error:^(NSError *error) {
                    [result sendError:error];
                } completed:^{
                    [result sendCompleted];
                }];
                return [signal catchTo:[RACSignal empty]]; // don't let error stops the queue
            } 
        }
    }];

    // add the signal to the queue
    [self.subject sendNext:signal]; // complete the signal when result is completed (ignore sendNext)

    return result; 
}

@end
