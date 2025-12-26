#import "ImageUtils.h"

UIImage* createNoisyImage(UIColor *color, float alphaMultiplier) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(64, 64), YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Fill background with the base color
    [color setFill];
    CGContextFillRect(context, CGRectMake(0, 0, 64, 64));

    // Add 600 white and 600 black pixels with random alpha for noise
    for (int i = 0; i < 600; i++) {
        [[UIColor colorWithWhite:1 alpha:(rand() % 10) / 100.0 * alphaMultiplier] setFill];
        CGContextFillRect(context, CGRectMake(rand() % 64, rand() % 64, 1, 1));

        [[UIColor colorWithWhite:0 alpha:(rand() % 15) / 100.0 * alphaMultiplier] setFill];
        CGContextFillRect(context, CGRectMake(rand() % 64, rand() % 64, 1, 1));
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
