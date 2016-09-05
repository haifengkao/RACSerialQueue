//
//  RACSerialCommandTests.m
//  RACSerialCommandTests
//
//  Created by Hai Feng Kao on 06/03/2016.
//  Copyright (c) 2016 Hai Feng Kao. All rights reserved.
//

// https://github.com/kiwi-bdd/Kiwi

#import "RACSerialQueue.h"
#import "RACSignal.h"
#import "RACScheduler.h"
#import "RACSignal+Operations.h"
#import "RACDisposable.h"
#import "RACSubscriber.h"
#import "RACSubject.h"
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(InitialTests)

describe(@"RACSerialQueue", ^{
      it(@"should handle error event gracefully", ^{
          __block NSNumber* done = @(0);
         RACSerialQueue* queue = [[RACSerialQueue alloc] init];
         [queue addSignal:[RACSignal error:[NSError errorWithDomain:@"serialqueue" code:123 userInfo:@{NSLocalizedDescriptionKey:@"wrong"}]]];
         RACSignal* signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
             done = @(1);
             return nil;
         }];
         [queue addSignal:signal];
         [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(10.0)] beTrue];
      });

      it(@"cannot be cancelled immediately", ^{
         __block NSNumber* done = @(0);
         RACSerialQueue* queue = [[RACSerialQueue alloc] init];
         RACSignal* signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
             done = @(1);
             return nil;
         }];
         RACSubject* subject = [queue addSignal:signal];
         [subject sendCompleted]; // will not cancel the signal execution, because the signal is alreay executed at addSignal
         
         [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(10.0)] beTrue];
      });

      it(@"can be cancelled after a while", ^{
          __block NSInteger count = 0;
          __block NSNumber* done = @(0);
         __block RACSubject* subject = nil;
         RACSerialQueue* queue = [[RACSerialQueue alloc] init];
         RACSignal* goodSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
             count++;
             [[[RACSignal empty] delay:0.1] subscribeCompleted:^{
                 [subscriber sendCompleted];
                 [[@(count) should] equal:@(1)]; // should be subscribed at most once
                 done = @(1);
             }];
             
             return nil;
         }];
         RACSignal* badSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
             [[@(NO) should] beYes];
             return nil;
         }];
         [queue addSignal:goodSignal];
         subject = [queue addSignal:badSignal];
         [subject sendCompleted]; // cancel the signal execution
         
         [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(10.0)] beTrue];
      });
});

SPEC_END

