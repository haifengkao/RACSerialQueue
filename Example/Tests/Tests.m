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

      xit(@"can be cancelled immediately", ^{
         __block NSNumber* done = @(0);
         RACSerialQueue* queue = [[RACSerialQueue alloc] init];
         RACSignal* signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
             [[@(NO) should] beYes];
              return nil;
         }];
         RACSubject* subject = [queue addSignal:signal];
         [subject sendCompleted]; // cancel the signal execution
         [[[RACSignal empty] delay:0.1] subscribeCompleted:^{
             [subject subscribeCompleted:^{
                 done = @(1);
             }];
         }];
         
         [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(1.0)] beTrue];
      });

      it(@"can be cancelled after a while", ^{
          __block NSInteger count = 0;
          __block NSNumber* done = @(0);
         __block RACSubject* subject = nil;
         RACSerialQueue* queue = [[RACSerialQueue alloc] init];
         RACSignal* goodSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
             count++;
             [[[RACSignal empty] delay:10] subscribeCompleted:^{
                 [subscriber sendCompleted];
                 [[@(count) should] beLessThan:@(2)];
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
         
         [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(100000.0)] beTrue];
      });
});

SPEC_END

