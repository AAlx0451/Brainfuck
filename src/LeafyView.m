#import "LeafyView.h"
#import "ImageUtils.h"

@implementation LeafyView {
    UIColor *_baseColor;
}

- (id)initWithFrame:(CGRect)frame backgroundColor:(UIColor*)color {
    if (self = [super initWithFrame:frame]) {
        _baseColor = color;
        // Use a pattern image for a textured background
        self.backgroundColor = [UIColor colorWithPatternImage:createNoisyImage(color, 0.5)];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Draw an inset dashed border with a highlight
    CGContextSetLineDash(context, 0, (CGFloat[]){5, 4}, 2);
    CGContextSetLineWidth(context, 2);

    // Darker dash
    [[UIColor colorWithWhite:0 alpha:0.5] setStroke];
    CGContextStrokeRect(context, CGRectInset(rect, 6, 6));

    // Lighter highlight dash
    [[UIColor colorWithWhite:1 alpha:0.15] setStroke];
    CGContextStrokeRect(context, CGRectInset(rect, 7, 7));
}
@end
