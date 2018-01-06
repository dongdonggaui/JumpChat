//
//  TouchManager.m
//  MonkeyChatDylib
//
//  Created by hly on 2018/1/2.
//  Copyright © 2018年 hly. All rights reserved.
//

#import "TouchManager.h"
#import "TouchExtension.h"

@interface PositionInfo: NSObject

@property (nonatomic, assign) CGFloat pieceX;
@property (nonatomic, assign) CGFloat pieceY;
@property (nonatomic, assign) CGFloat boardX;
@property (nonatomic, assign) CGFloat boardY;

- (PositionInfo *)zero;

@end

@implementation PositionInfo

- (PositionInfo *)zero
{
    self.pieceX = 0;
    self.pieceY = 0;
    self.boardX = 0;
    self.boardY = 0;
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"piece : {%@, %@}, board : {%@, %@}", @(self.pieceX), @(self.pieceY), @(self.boardX), @(self.boardY)];
}

@end

@implementation TouchManager

+ (instancetype)sharedInstance
{
    static id sharedInstance__ = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance__ = [self new];
    });
    return sharedInstance__;
}

- (void)jumpButtonTapped:(UIButton *)sender
{
    [self handle];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)handle
{
    UIImage *sourceImage = [self snapUIImage];
    PositionInfo *position = [self findPieceAndBoard:sourceImage];
    NSLog(@"%@", position);
    CGFloat x = position.pieceX - position.boardX;
    CGFloat y = position.pieceY - position.boardY;
    CGFloat distance = sqrt(x * x + y * y);
    CGFloat coefficient = self.coefficientTextField.text.doubleValue;
    NSTimeInterval interval = coefficient * distance / 1000;
    NSLog(@"interval : %@", @(interval));
    
    UIWindow *window = [UIApplication sharedApplication].delegate.window;

    CGPoint point = [self generatePointInWindow:window];
    UITouch *touch = [[UITouch alloc] initInView:self.glView phase:UITouchPhaseBegan point:point];
    UIEvent *event = [[UIEvent alloc] initWithTouch:touch timestamp:self.timestamp];
    [window sendEvent:event];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [touch updatePhase:UITouchPhaseEnded];
        [window sendEvent:event];
    });
}

- (CGPoint)generatePointInWindow:(UIWindow *)window
{
    CGRect frameInWindow = [window convertRect:self.glView.frame fromView:self.glView.superview];
    int xSrc = frameInWindow.size.width * 0.25;
    int xDest = frameInWindow.size.width * 0.75;
    int ySrc = frameInWindow.size.height * 0.25;
    int yDest = frameInWindow.size.height * 0.75;
    int x = arc4random() % (xDest - xSrc) + xSrc;
    int y = arc4random() % (yDest - ySrc) + ySrc;
    CGPoint point = CGPointMake(x, y);
    
    return point;
}

- (UIImage *)snapUIImage
{
    UIView *view = self.glView;
    CGSize viewSize = view.bounds.size;
    UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
    [view drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
    UIImage *previewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return previewImage;
}

- (PositionInfo *)findPieceAndBoard:(UIImage *)image
{
    PositionInfo *position = [[PositionInfo alloc] init];
    CGImageRef inputCGImage = [image CGImage];
    int w = (int)CGImageGetWidth(inputCGImage);
    int h = (int)CGImageGetHeight(inputCGImage);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * w;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 * pixels;
    pixels = (UInt32 *) calloc(h * w, sizeof(UInt32));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, w, h,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), inputCGImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    NSLog(@"image size : {%@, %@}", @(w), @(h));
    
    int piece_x = 0;
    int piece_y = 0;
    int piece_x_sum = 0;
    int piece_x_c = 0;
    int piece_y_max = 0;
    int board_x = 0;
    int board_y = 0;
    int scan_x_border = (int)(w / 8);  // 扫描棋子时的左右边界
    int scan_start_y = 0;  // 扫描的起始y坐标
    
    int under_game_score_y = 300;
    int piece_base_height_1_2 = 20;
    int piece_body_width = 70;
    
    // 以下图像分析算法翻译自 https://github.com/wangshub/wechat_jump_game
    
#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
    
    UInt32 last_pixel = 0;
    
    // 以50px步长，尝试探测scan_start_y
    for (int i = under_game_score_y; i < h; i = i + 50) {
        last_pixel = pixels[i * w];
        for (int j = 1; j < w; j++) {
            UInt32 pixel = pixels[i * w + j];
            
            // 不是纯色的线，则记录scan_start_y的值，准备跳出循环
            if (R(pixel) != R(last_pixel) || G(pixel) != G(last_pixel) || B(pixel) != B(last_pixel)) {
                scan_start_y = i - 50;
                break;
            }
        }
            
        if (scan_start_y) {
            break;
        }
    }
        
    NSLog(@"scan_start_y: %@", @(scan_start_y));
    
    // 从scan_start_y开始往下扫描，棋子应位于屏幕上半部分，这里暂定不超过2/3
    for (int i = scan_start_y; i < (int)(h * 2 / 3); i++) {
        // 横坐标方面也减少了一部分扫描开销
        for (int j = scan_x_border; j < w - scan_x_border; j++) {
            UInt32 pixel = pixels[i * w + j];
            // 根据棋子的最低行的颜色判断，找最后一行那些点的平均值，这个颜色这样应该 OK，暂时不提出来
            if (R(pixel) > 50 && R(pixel) < 60 && G(pixel) > 53 && G(pixel) < 63 && B(pixel) > 95 && B(pixel) < 110) {
                piece_x_sum += j;
                piece_x_c += 1;
                piece_y_max = MAX(i, piece_y_max);
            }
        }
    }
    
    if (piece_x_sum < 1 || piece_x_c < 1) {
        free(pixels);
        return [position zero];
    }
    
    piece_x = piece_x_sum / piece_x_c;
    piece_y = piece_y_max - piece_base_height_1_2;  // 上移棋子底盘高度的一半
    
    for (int i = (int)(h / 3); i < (int)(h * 2 / 3); i++) {
        last_pixel = pixels[i * w];
        if (board_x > 0 || board_y > 0) {
            break;
        }
        int board_x_sum = 0;
        int board_x_c = 0;
        
        for (int j = 0; j < w; j++) {
            UInt32 pixel = pixels[i * w + j];
            // 修掉脑袋比下一个小格子还高的情况的 bug
            if (abs(j - piece_x) < piece_body_width) {
                continue;
            }
            
            int rx = R(pixel) - R(last_pixel);
            int gx = G(pixel) - G(last_pixel);
            int bx = B(pixel) - B(last_pixel);
            
            // 修掉圆顶的时候一条线导致的小 bug，这个颜色判断应该 OK，暂时不提出来
            if (abs(rx) + abs(gx) + abs(bx) > 10) {
                board_x_sum += j;
                board_x_c += 1;
            }
        }
        
        if (board_x_sum > 0) {
            board_x = board_x_sum / board_x_c;
        }
    }
    
                                                            
    // 按实际的角度来算，找到接近下一个 board 中心的坐标 这里的角度应该是30°,值应该是tan 30°, math.sqrt(3) / 3
    board_y = piece_y - abs(board_x - piece_x) * sqrt(3) / 3;
    
    if (board_x < 1 || board_y < 1) {
        free(pixels);
        return [position zero];
    }
    
    position.pieceX = piece_x;
    position.pieceY = piece_y;
    position.boardX = board_x;
    position.boardY = board_y;
                                                                
    free(pixels);
#undef R
#undef G
#undef B
    
    return position;
}

@end
