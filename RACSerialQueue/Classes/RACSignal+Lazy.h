//
//  RACSignal+Lazy.h
//  OmniWebview
//
//  Created by Hai Feng Kao on 2016/06/08.
//
//

#import <Foundation/Foundation.h>

#import "RACSignal.h"
@interface RACSignal(Lazy)

// return a replay signal that will subscribe lazily and dispose the source signal when all subscriptions are disposed
- (RACSignal *)replayLazilyAutoDisposed;
@end

