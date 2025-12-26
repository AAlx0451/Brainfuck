#import "MemoryCell.h"
#import "ImageUtils.h"

@implementation MemoryCell {
    UILabel *_indexLabel;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];

        // Textured background view
        UIView *background = [[UIView alloc] initWithFrame:self.bounds];
        background.backgroundColor = [UIColor colorWithPatternImage:createNoisyImage([UIColor colorWithRed:0.96 green:0.95 blue:0.91 alpha:1], 0.05)];
        [self.contentView addSubview:background];

        // Vertical separators (shadow and highlight for 3D effect)
        UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(frame.size.width - 1, 0, 1, frame.size.height)];
        shadowView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        [background addSubview:shadowView];

        UIView *highlightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, frame.size.height)];
        highlightView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
        [background addSubview:highlightView];

        // Memory index label (top)
        _indexLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 2, frame.size.width, 10)];
        _indexLabel.font = [UIFont systemFontOfSize:8];
        _indexLabel.textColor = [UIColor grayColor];
        _indexLabel.textAlignment = NSTextAlignmentCenter;
        _indexLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_indexLabel];

        // Integer value label (middle)
        _valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 11, frame.size.width, 25)];
        _valueLabel.font = [UIFont fontWithName:@"Courier-Bold" size:22];
        _valueLabel.textAlignment = NSTextAlignmentCenter;
        _valueLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_valueLabel];

        // Character representation label (bottom)
        _charLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 36, frame.size.width, 20)];
        _charLabel.font = [UIFont boldSystemFontOfSize:16];
        _charLabel.textAlignment = NSTextAlignmentCenter;
        _charLabel.textColor = [UIColor redColor];
        _charLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_charLabel];
    }
    return self;
}

- (void)configureWithIndex:(int)index value:(uint8_t)value {
    _indexLabel.text = [NSString stringWithFormat:@"%d", index];
    _valueLabel.text = [NSString stringWithFormat:@"%d", value];
    // Show character only for printable ASCII values
    _charLabel.text = (value > 32 && value < 127) ? [NSString stringWithFormat:@"%c", value] : @"";
}
@end
