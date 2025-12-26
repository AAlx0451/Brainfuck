#import "CustomButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation CustomButton

+ (id)buttonWithTitle:(NSString*)title tag:(int)tag {
    CustomButton *button = [CustomButton buttonWithType:UIButtonTypeCustom];
    button.tag = tag;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:22];
    return button;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 2, 2) cornerRadius:8];

    UIColor *bgColor;
    int tag = (int)self.tag;
    BOOL isEngraved = NO;

    // Determine color and style based on button tag
    if (tag < 8 || tag > 90) { // Operator or special buttons (OK, Exit)
        bgColor = [UIColor colorWithRed:0.9 green:0.88 blue:0.82 alpha:1];
        isEngraved = YES;
    } else if (tag == 8) { // RUN/STOP button
        bgColor = [UIColor colorWithRed:0.25 green:0.35 blue:0.25 alpha:1];
    } else if (tag == 11) { // RST button
        bgColor = [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1];
    } else { // Other control buttons
        bgColor = [UIColor colorWithWhite:0.3 alpha:1];
    }

    // Dim button when highlighted
    if (self.highlighted) {
        bgColor = [bgColor colorWithAlphaComponent:0.7];
    }
    [bgColor setFill];
    [path fill];

    // Set text style based on button type
    if (isEngraved) {
        [self setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
        [self setTitleShadowColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateNormal];
        self.titleLabel.shadowOffset = CGSizeMake(0, 1);
    } else {
        [self setTitleColor:[UIColor colorWithWhite:0.95 alpha:1] forState:UIControlStateNormal];
        [self setTitleShadowColor:[UIColor colorWithWhite:0 alpha:0.5] forState:UIControlStateNormal];
        self.titleLabel.shadowOffset = CGSizeMake(0, -1);
    }

    // Draw a glossy gradient overlay
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat components[] = {1, 1, 1, 0.3, 0, 0, 0, 0.1};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, NULL, 2);
    CGContextSaveGState(context);
    [path addClip];
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, rect.size.height), 0);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);

    // Draw a subtle border
    [[UIColor colorWithWhite:0 alpha:0.2] setStroke];
    path.lineWidth = 1;
    [path stroke];
}

// Redraw when highlight state changes
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}
@end
