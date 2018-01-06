//
//  TouchExtension.h
//  MonkeyChatDylib
//
//  Created by hly on 2018/1/2.
//  Copyright © 2018年 hly. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITouch (Monkey)

- (id)initInView:(UIView *)view
           phase:(UITouchPhase)phase
           point:(CGPoint)point;

- (void)updatePhase:(UITouchPhase)phase;

@end

@interface UIEvent (Monkey)

- (id)initWithTouch:(UITouch *)touch
          timestamp:(NSTimeInterval)timestamp;

@end
