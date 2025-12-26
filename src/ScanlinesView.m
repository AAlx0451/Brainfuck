#import "ScanlinesView.h"

@implementation ScanlinesView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor colorWithWhite:0 alpha:0.15] setFill];

    // Draw a 1px line every 3 pixels
    for (int i = 0; i < rect.size.height; i += 3) {
        CGContextFillRect(context, CGRectMake(0, i, rect.size.width, 1));
    }
}
@end
