/*!
 RFKeyboard
 
 Copyright (c) 2012-2014, 2018, 2020 BB9z
 https://github.com/RFUI/RFKeyboard
 
 The MIT License (MIT)
 http://www.opensource.org/licenses/mit-license.php
 */

#import <UIKit/UIKit.h>

@interface RFKeyboard : NSObject

+ (nonnull instancetype)defaultManager;

/**
 Converts a keyboardRect via a UIKeyboard notification to the view´s coordinate system.
 
 @param keyboardRect Keyboard frame rect, usually from an UIKeyboard notification´s userinfo[UIKeyboardFrameEndUserInfoKey].
 
 @return The converted keyboard frame rectangle in view ´s coordinate system. Must not be nil.
 */
+ (CGRect)convertKeyboardFrame:(CGRect)keyboardRect toView:(nullable UIView *)view;

/**
 Check whether the keyboard is docked or not.
 
 @param keyboardRect Keyboard frame rect, usually from an UIKeyboard notification´s userinfo[UIKeyboardFrameEndUserInfoKey].
 
 @return `YES` if the keyboard is undocked, `NO` if the keyboard is dock at screen bottom.
 */
+ (BOOL)isUndocked:(CGRect)keyboardRect;

+ (CGFloat)keyboardLayoutHeightForNotification:(nonnull NSNotification *)note inView:(nullable UIView *)view;

/**
 If set YES, the keyboard will dismiss if user tap or pan if needed.
 
 Gesture recognizers will be add to the key window. When the keyboard is shown and user tap in the window, RFKeyboard will ask the window’s first responder to relinquish its status as first responder in its window.
 */
@property (class, nonatomic) BOOL autoDisimssKeyboardWhenTouch;

/// Experimental, only called when autoDisimssKeyboardWhenTouch is enabled.
@property (nullable) void (^keyboardShowCallback)(NSNotification *__nonnull note);
@property (nullable) void (^keyboardHideCallback)(NSNotification *__nonnull note);
@end
