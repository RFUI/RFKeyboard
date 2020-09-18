
#import "RFKeyboard.h"
#import <RFKit/RFRuntime.h>

@interface RFKeyboard () <
    UIGestureRecognizerDelegate
>
@property (nonatomic) UITapGestureRecognizer *tapInWindowGestureRecognizer;
@property (nonatomic) UIPanGestureRecognizer *panInWindowGestureRecognizer;
@property (nonatomic) id keyboardShowObserver;
@property (nonatomic) id keyboardHideObserver;
@property (nonatomic) BOOL enableAutoDisimssKeyboardWhenTouch;
@end

@implementation RFKeyboard

+ (instancetype)defaultManager {
    static RFKeyboard *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        sharedInstance = self.new;
    });
    return sharedInstance;
}

+ (CGRect)convertKeyboardFrame:(CGRect)keyboardRect toView:(UIView *)view {
    NSParameterAssert(view);
    CGRect keyboardFrameOnScreen = keyboardRect;
    
    // General, keyboardFrameInViewsWindow is equal to keyboardFrameOnScreen. But if you change window´s frame, they may be diffrence.
    CGRect keyboardFrameInViewsWindow = [view.window convertRect:keyboardFrameOnScreen fromWindow:nil];
    return [view convertRect:keyboardFrameInViewsWindow fromView:nil];
}

+ (BOOL)isUndocked:(CGRect)keyboardRect {
    // We use a trick here, instead of checking the distance between keyboard buttom and screen buttom.
    int zeroCount = 0;
    if (keyboardRect.origin.x) zeroCount++;
    if (keyboardRect.origin.y) zeroCount++;
    if (keyboardRect.size.width) zeroCount++;
    if (keyboardRect.size.height) zeroCount++;
    
    return (zeroCount != 2)? YES : NO;
}

+ (CGFloat)keyboardLayoutHeightForNotification:(NSNotification *)note inView:(UIView *)view {
    NSValue *frameValue = note.userInfo[UIKeyboardFrameEndUserInfoKey];
    if (!frameValue) {
        dout_warning(@"Cannot get keyboard frame info for %@", note)
        return -1;
    }
    CGRect frame = frameValue.CGRectValue;
    if (![RFKeyboard isUndocked:frame]) {
        return 0;
    }

    CGRect normalizedFrame = [self convertKeyboardFrame:frame toView:view];
    CGFloat sizeInView = CGRectGetMaxY(view.bounds) - CGRectGetMinY(normalizedFrame);
    return sizeInView < 0 ? 0 : sizeInView;
}

+ (void)viewAnimateWithNotification:(NSNotification *)note animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    NSDictionary *info = note.userInfo;
    NSTimeInterval duration = [(NSNumber *)info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [(NSNumber *)info[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0 options:curve animations:animations completion:completion];
}

#pragma mark - experimental below

+ (BOOL)autoDisimssKeyboardWhenTouch {
    return [(RFKeyboard *)self.defaultManager enableAutoDisimssKeyboardWhenTouch];
}

+ (void)setAutoDisimssKeyboardWhenTouch:(BOOL)autoDisimssKeyboardWhenTouch {
    [(RFKeyboard *)self.defaultManager setEnableAutoDisimssKeyboardWhenTouch:autoDisimssKeyboardWhenTouch];
}

- (void)setEnableAutoDisimssKeyboardWhenTouch:(BOOL)enabled {
    @synchronized(self) {
        if (enabled) {
            if (![self isObservingKeyboardNotification]) {
                if (!self.tapInWindowGestureRecognizer.view || !self.panInWindowGestureRecognizer.view) {
                    [self setupKeyWindowGestureRecognizers];
                }

                @weakify(self)
                self.keyboardShowObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                    @strongify(self)
                    CGRect frame = [(NSValue *)note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
                    if (![RFKeyboard isUndocked:frame]) {
                        return;
                    }

                    self.tapInWindowGestureRecognizer.enabled = YES;
                    self.panInWindowGestureRecognizer.enabled = YES;
                    [self tryAddGestureRecognizerToKeyWindow];

                    if (self.keyboardShowCallback) {
                        self.keyboardShowCallback(note);
                    }
                }];
                self.keyboardHideObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
                    @strongify(self)
                    self.tapInWindowGestureRecognizer.enabled = NO;
                    self.panInWindowGestureRecognizer.enabled = NO;

                    if (self.keyboardHideCallback) {
                        self.keyboardHideCallback(note);
                    }
                }];
            }
        }
        else {
            if ([self isObservingKeyboardNotification]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardShowObserver];
                [[NSNotificationCenter defaultCenter] removeObserver:self.keyboardHideObserver];
                self.keyboardShowObserver = nil;
                self.keyboardHideObserver = nil;
            }
        }

        _enableAutoDisimssKeyboardWhenTouch = enabled;
    }
}

- (BOOL)isObservingKeyboardNotification {
    return (self.keyboardHideObserver && self.keyboardShowObserver);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        return NO;
    }

    if ([touch.view isKindOfClass:[UINavigationBar class]]) {
        return NO;
    }

    return YES;
}

- (void)setupKeyWindowGestureRecognizers {
    if (self.tapInWindowGestureRecognizer.view && self.panInWindowGestureRecognizer.view) {
        return;
    }

    if (!self.tapInWindowGestureRecognizer) {
        UITapGestureRecognizer *gr = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(onTouchInKeyWindow:)];
        gr.enabled = NO;
        gr.cancelsTouchesInView = NO;
        gr.delegate = self;
        self.tapInWindowGestureRecognizer = gr;
    }

    if (!self.panInWindowGestureRecognizer) {
        UIPanGestureRecognizer *gr = [UIPanGestureRecognizer.alloc initWithTarget:self action:@selector(onTouchInKeyWindow:)];
        gr.maximumNumberOfTouches = 1;
        gr.enabled = NO;
        gr.cancelsTouchesInView = NO;
        gr.delegate = self;
        self.panInWindowGestureRecognizer = gr;
    }

    if (![self tryAddGestureRecognizerToKeyWindow]) {
        dispatch_after_seconds(1, ^{
            if (![self tryAddGestureRecognizerToKeyWindow]) {
                dout_warning(@"RFKeyboard: Cannot find root window to add gesture recognizer.")
            }
        });
    }
}

- (BOOL)tryAddGestureRecognizerToKeyWindow {
    UIWindow *target = UIApplication.sharedApplication.keyWindow;
    if (target) {
        [target addGestureRecognizer:self.tapInWindowGestureRecognizer];
        [target addGestureRecognizer:self.panInWindowGestureRecognizer];
        return YES;
    }
    return NO;
}

- (void)onTouchInKeyWindow:(UIGestureRecognizer *)sender {
    // Dismiss keyboard
    [UIApplication.sharedApplication sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

@end
