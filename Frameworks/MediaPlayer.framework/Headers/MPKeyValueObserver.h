//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Oct 15 2018 10:31:50).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <objc/NSObject.h>

@class NSString;

@interface MPKeyValueObserver : NSObject
{
    id _object;
    NSString *_keyPath;
    id _handler;
}


@property(readonly, copy, nonatomic) id handler; // @synthesize handler=_handler;
@property(readonly, copy, nonatomic) NSString *keyPath; // @synthesize keyPath=_keyPath;
@property(readonly, nonatomic) __weak id object; // @synthesize object=_object;
- (void)observeValueForKeyPath:(id)arg1 ofObject:(id)arg2 change:(id)arg3 context:(void *)arg4;
- (void)dealloc;
- (id)initWithObject:(id)arg1 keyPath:(id)arg2 options:(unsigned long long)arg3 handler:(id)arg4;

@end
