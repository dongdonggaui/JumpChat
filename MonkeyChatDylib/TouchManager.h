//
//  TouchManager.h
//  MonkeyChatDylib
//
//  Created by hly on 2018/1/2.
//  Copyright © 2018年 hly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TouchManager : NSObject <UITextFieldDelegate>

@property (nonatomic, strong) UIEvent *event;

@property (nonatomic, weak) UIView *glView;
@property (nonatomic, weak) UITextField *coefficientTextField;

@property (nonatomic, assign) NSTimeInterval timestamp;

+ (instancetype)sharedInstance;

- (void)jumpButtonTapped:(UIButton *)sender;

@end
