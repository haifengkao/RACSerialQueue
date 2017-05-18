//
//  RACSerialQueue.h
//  RACSerialQueue
//
//  Created by Hai Feng Kao on 2016/06/03.
//
//

#import <Foundation/Foundation.h>
@class RACSubject;
@class RACSignal;

// Make RACSignal to be subscribed in order
// Useful when you need to protect a single resource that cannot be shared
@interface RACSerialQueue : NSObject

- (instancetype)init NS_DESIGNATED_INITIALIZER;

// if you want to cancel the execution
// make the returned subject complete or error
// e.g. [returnValue sendCompleted]
- (RACSubject *)addSignal:(RACSignal*)signal;

// stop the whole queue
// Note that there is no start method
// if you want to start the queue again, you have to create another queue
- (void)stop;
- (void)useMainThread; 

// returns a signal which will sendNext when the queue has stopped
- (RACSignal*)hasStoppedSignal;

@end
