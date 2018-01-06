//
//  TouchExtension.h
//  MonkeyChatDylib
//
//  Created by hly on 2018/1/2.
//  Copyright © 2018年 hly. All rights reserved.
//

#import "TouchExtension.h"
#import <objc/runtime.h>

@implementation UITouch (Monkey)

- (id)initInView:(UIView *)view phase:(UITouchPhase)phase point:(CGPoint)point
{
	self = [super init];
	if (self != nil)
	{
		CGRect frameInWindow;
		if ([view isKindOfClass:[UIWindow class]]) {
			frameInWindow = view.frame;
		}
		else {
			frameInWindow =
				[view.window convertRect:view.frame fromView:view.superview];
		}
		 
        [self setValue:@(1) forKey:@"tapCount"];
//        CGPoint point = CGPointMake(frameInWindow.origin.x + 0.5 * frameInWindow.size.width, frameInWindow.origin.y + 0.75 * frameInWindow.size.height);
        [self setValue:[NSValue valueWithCGPoint:point] forKey:@"locationInWindow"];
        [self setValue:[NSValue valueWithCGPoint:point] forKey:@"previousLocationInWindow"];
//        [self setValue:[NSValue valueWithCGPoint:point] forKey:@"previousLocationInView"];
        [self setValue:view.window forKey:@"window"];
        [self setValue:view forKey:@"view"];
        [self setValue:@(phase) forKey:@"phase"];
        [self setValue:@([NSDate timeIntervalSinceReferenceDate]) forKey:@"timestamp"];
	}
	return self;
}

- (void)updatePhase:(UITouchPhase)phase
{
    [self setValue:@(phase) forKey:@"phase"];
    [self setValue:@([NSDate timeIntervalSinceReferenceDate]) forKey:@"timestamp"];
}

@end

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface GSEventProxy : NSObject
{
@public
	unsigned int flags;
	unsigned int type;
	unsigned int ignored1;
	float x1;
	float y1;
	float x2;
	float y2;
	unsigned int ignored2[10];
	unsigned int ignored3[7];
	float sizeX;
	float sizeY;
	float x3;
	float y3;
	unsigned int ignored4[3];
}
@end
@implementation GSEventProxy
@end

//
// PublicEvent
//
// A dummy class used to gain access to UIEvent's private member variables.
// If UIEvent changes at all, this will break.
//
@interface PublicEvent : NSObject
{
@public
    GSEventProxy           *_event;
    NSTimeInterval          _timestamp;
    NSMutableSet           *_touches;
    CFMutableDictionaryRef  _keyedTouches;
}
@end

@implementation PublicEvent
@end

@interface UIEvent (Creation)

- (id)_initWithEvent:(GSEventProxy *)fp8 touches:(id)fp12;

@end

@implementation UIEvent (Monkey)

- (id)initWithTouch:(UITouch *)touch timestamp:(NSTimeInterval)timestamp
{
	CGPoint location = [touch locationInView:touch.window];
	GSEventProxy *gsEventProxy = [[GSEventProxy alloc] init];
	gsEventProxy->x1 = location.x;
	gsEventProxy->y1 = location.y;
	gsEventProxy->x2 = location.x;
	gsEventProxy->y2 = location.y;
	gsEventProxy->x3 = location.x;
	gsEventProxy->y3 = location.y;
	gsEventProxy->sizeX = 1.0;
	gsEventProxy->sizeY = 1.0;
	gsEventProxy->flags = ([touch phase] == UITouchPhaseEnded) ? 0x1010180 : 0x3010180;
	gsEventProxy->type = 3001;	
	
	//
	// On SDK versions 3.0 and greater, we need to reallocate as a
	// UITouchesEvent.
	//
	Class touchesEventClass = objc_getClass("UITouchesEvent");
	if (touchesEventClass && ![[self class] isEqual:touchesEventClass]) {
		self = [touchesEventClass alloc];
	}
	
	self = [self _initWithEvent:gsEventProxy touches:[NSSet setWithObject:touch]];
	if (self) {
        [self setValue:@(timestamp) forKey:@"timestamp"];
	}
	return self;
}

@end
