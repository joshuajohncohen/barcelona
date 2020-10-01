//
//     Generated by class-dump 3.5 (64 bit).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2013 by Steve Nygard.
//

#import <LinkPresentation/LPComponentView.h>

#import "CAAnimationDelegate.h"

@class LPCaptionBarAccessoryView, LPCaptionBarPresentationProperties, LPCaptionBarStyle, LPComponentView, LPInlineMediaPlaybackInformation, LPPlayButtonView, LPVerticalTextStackView, NSString;


@interface LPCaptionBarView : LPComponentView <CAAnimationDelegate>
{
    LPCaptionBarStyle *_style;
    LPCaptionBarPresentationProperties *_presentationProperties;
    LPComponentView *_leftIconView;
    LPComponentView *_rightIconView;
    LPPlayButtonView *_playButton;
    LPCaptionBarAccessoryView *_leftAccessoryView;
    LPCaptionBarAccessoryView *_rightAccessoryView;
    LPComponentView *_aboveTopCaptionView;
    LPComponentView *_topCaptionView;
    LPComponentView *_bottomCaptionView;
    LPComponentView *_belowBottomCaptionView;
    LPVerticalTextStackView *_textStackView;
    LPInlineMediaPlaybackInformation *_inlinePlaybackInformation;
    BOOL _hasEverBuilt;
    BOOL _useProgressSpinner;
    id _textSafeAreaInset;
}


@property(nonatomic) struct NSEdgeInsets textSafeAreaInset; // @synthesize textSafeAreaInset=_textSafeAreaInset;
@property(nonatomic) BOOL useProgressSpinner; // @synthesize useProgressSpinner=_useProgressSpinner;
- (void)_buildViewsForCaptionBarIfNeeded;
- (struct CGSize)_layoutCaptionBarForSize:(struct CGSize)arg1 applyingLayout:(BOOL)arg2;
- (struct CGSize)sizeThatFits:(struct CGSize)arg1;
- (void)layoutComponentView;
- (void)animationDidStop:(id)arg1 finished:(BOOL)arg2;
- (void)animateInWithBaseAnimation:(id)arg1 currentTime:(double)arg2;
- (void)animateOut;
- (void)setPlaybackInformation:(id)arg1;
- (id)initWithStyle:(id)arg1 presentationProperties:(id)arg2;
- (id)init;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long hash;
@property(readonly) Class superclass;

@end

