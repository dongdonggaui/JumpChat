//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  MonkeyChatDylib.m
//  MonkeyChatDylib
//
//  Created by hly on 2017/10/31.
//  Copyright (c) 2017年 hly. All rights reserved.
//

#import "MonkeyChatDylib.h"
#import <CaptainHook/CaptainHook.h>
#import <UIKit/UIKit.h>
#import <Cycript/Cycript.h>
#import <FLEX/FLEXManager.h>
#import "TouchManager.h"

static __attribute__((constructor)) void entry(){
    NSLog(@"\n               🎉!!！congratulations!!！🎉\n👍----------------insert dylib success----------------👍");
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [[FLEXManager sharedManager] showExplorer];
        CYListenServer(6666);
    }];
}

@interface NewMainFrameViewController

-(void)viewDidLoad;

@end

CHDeclareClass(NewMainFrameViewController)

CHOptimizedMethod(0, self, void, NewMainFrameViewController, viewDidLoad){
    CHSuper(0, NewMainFrameViewController, viewDidLoad);
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(CGRectGetWidth(window.bounds) - 96, CGRectGetHeight(window.bounds) - 96, 88, 44);
    button.backgroundColor = [UIColor orangeColor];
    [button setTitle:@"跳" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:[TouchManager sharedInstance] action:@selector(jumpButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:button];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:button.bounds];
    textField.tag = 107;
    textField.text = @"1.126";
    textField.placeholder = @"系数";
    textField.textAlignment = NSTextAlignmentCenter;
    textField.backgroundColor = [UIColor cyanColor];
    textField.center = CGPointMake(button.center.x, button.center.y - 52);
    textField.delegate = [TouchManager sharedInstance];
    [window addSubview:textField];
    [TouchManager sharedInstance].coefficientTextField = textField;
}

CHConstructor{
    CHLoadLateClass(NewMainFrameViewController);
    CHClassHook(0, NewMainFrameViewController, viewDidLoad);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

CHDeclareClass(UIWindow)

CHOptimizedMethod(1, self, void, UIWindow, sendEvent, UIEvent *, arg1)
{
    NSInteger touchCount = arg1.allTouches.count;
    if (touchCount != 1) {
        CHSuper(1, UIWindow, sendEvent, arg1);
    }
    else {
        BOOL canSend = YES;
        for(UITouch *touch in arg1.allTouches) {
            if ([touch.view isKindOfClass:[UIButton class]]) {
                [TouchManager sharedInstance].timestamp = arg1.timestamp;
            }
        }
        if (canSend) {
            CHSuper(1, UIWindow, sendEvent, arg1);
        }
    }
}

CHConstructor{
    CHLoadLateClass(UIWindow);
    CHClassHook(1, UIWindow, sendEvent);
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

@interface EAGLView

- (id)initWithFrame:(CGRect)arg1 contentScale:(CGFloat)arg2 retainedBacking:(BOOL)arg3;

@end

CHDeclareClass(EAGLView)

CHOptimizedMethod(3, self, id, EAGLView, initWithFrame, CGRect, arg1, contentScale, CGFloat, arg2, retainedBacking, BOOL, arg3)
{
    id view = CHSuper(3, EAGLView, initWithFrame, arg1, contentScale, arg2, retainedBacking, arg3);
    [TouchManager sharedInstance].glView = view;
    return view;
}

CHConstructor{
    CHLoadLateClass(EAGLView);
    CHClassHook(3, EAGLView, initWithFrame, contentScale, retainedBacking);
}

