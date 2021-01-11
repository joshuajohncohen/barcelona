//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 15 2018 10:31:50).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <objc/NSObject.h>

@protocol OS_dispatch_source;

@interface MPWeakTimer : NSObject
{
    NSObject *_timerSource;
}

+ (id)timerWithInterval:(double)arg1 repeats:(_Bool)arg2 queue:(id)arg3 block:(id)arg4;
+ (id)timerWithInterval:(double)arg1 queue:(id)arg2 block:(id)arg3;
+ (id)timerWithInterval:(double)arg1 repeats:(_Bool)arg2 block:(id)arg3;
+ (id)timerWithInterval:(double)arg1 block:(id)arg2;

- (void)invalidate;
- (void)dealloc;
- (id)initWithInterval:(double)arg1 repeats:(_Bool)arg2 queue:(id)arg3 block:(id)arg4;
- (id)initWithInterval:(double)arg1 queue:(id)arg2 block:(id)arg3;

@end
