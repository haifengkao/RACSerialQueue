//
//  RACSerialCommandTests.m
//  RACSerialCommandTests
//
//  Created by Hai Feng Kao on 06/03/2016.
//  Copyright (c) 2016 Hai Feng Kao. All rights reserved.
//

// https://github.com/kiwi-bdd/Kiwi

@import RACSerialQueue;
#import <Kiwi/Kiwi.h>

SPEC_BEGIN(InitialTests)

describe(@"RACSerialQueue", ^{

    it(@"should dispose the original signal after all subscriber has been disposed", ^{
         __block NSInteger count = 0;
         __block NSInteger dispCount = 0;
        RACSignal* signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            count++;
            return [RACDisposable disposableWithBlock:^{
                dispCount++;
            }];
       }];

        RACSignal* replaySignal = [signal replayLazilyAutoDisposed];
        RACDisposable* disp = [replaySignal subscribeNext:^(id x) {
         
        } error:^(NSError *error) {
        } completed:^{
        }];
        RACDisposable* disp2 = [replaySignal subscribeNext:^(id x) {
         
        } error:^(NSError *error) {
        } completed:^{
        }];

        [disp dispose];
        [[@(count) should] equal:@(1)];
        [[@(dispCount) should] equal:@(0)];
        
        [disp2 dispose];
        [[@(dispCount) should] equal:@(1)];
    });

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
       [subject sendCompleted]; // will not cancel the signal execution, because the signal is already executed at addSignal
       
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

    it(@"can cancel the active signal", ^{
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
           RACDisposable* disp = [[[RACSignal empty] delay:0.05] subscribeCompleted:^{
               // should not be executed
               [[@(NO) should] beYes];
           }];
           
           return disp;
       }];
       subject = [queue addSignal:goodSignal];
       [subject sendCompleted]; // cancel the signal execution
       
       [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(10.0)] beTrue];
    });
  
    it(@"can stop the whole queue", ^{
        __block NSInteger count = 0;
        __block NSNumber* done = @(0);
        RACSerialQueue* queue = [[RACSerialQueue alloc] init];
        RACSignal* goodSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            count++;
            [[[RACSignal empty] delay:0.1] subscribeCompleted:^{
                [subscriber sendCompleted];
                [[@(count) should] equal:@(1)]; // should be subscribed at most once
                done = @(1);
            }];
            RACDisposable* disp = [[[RACSignal empty] delay:0.05] subscribeCompleted:^{
                // should not be executed
                [[@(NO) should] beYes];
            }];
            
            return disp;
        }];
        [queue addSignal:goodSignal];

        [queue stop];
        
        [[expectFutureValue(done) shouldEventuallyBeforeTimingOutAfter(10.0)] beTrue];
    });
});

SPEC_END

