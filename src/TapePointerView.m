#import "TapePointerView.h"

@implementation TapePointerView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect insetRect = CGRectInset(rect, 3, 3);
    UIBezierPath *outerPath = [UIBezierPath bezierPathWithRoundedRect:insetRect cornerRadius:6];

    // Base fill
    [[UIColor colorWithWhite:1 alpha:0.2] setFill];
    [outerPath fill];

    // Top gloss highlight
    CGRect glossRect = CGRectMake(insetRect.origin.x, insetRect.origin.y, insetRect.size.width, insetRect.size.height / 2.2);
    UIBezierPath *glossPath = [UIBezierPath bezierPathWithRoundedRect:glossRect byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(6, 6)];
    [[UIColor colorWithWhite:1 alpha:0.4] setFill];
    [glossPath fill];

    // Double border (thick light, thin dark)
    [[UIColor colorWithWhite:0.7 alpha:1] setStroke];
    outerPath.lineWidth = 4;
    [outerPath stroke];
    
    [[UIColor colorWithWhite:0.3 alpha:1] setStroke];
    outerPath.lineWidth = 1;
    [outerPath stroke];

    // Red center line indicator
    [[UIColor redColor] setStroke];
    CGContextMoveToPoint(context, rect.size.width / 2, rect.size.height - 8);
    CGContextAddLineToPoint(context, rect.size.width / 2, rect.size.height - 16);
    CGContextStrokePath(context);
}
@end
