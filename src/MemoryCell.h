#import <UIKit/UIKit.h>

// A UICollectionViewCell representing a single byte in the Brainfuck memory tape.
@interface MemoryCell : UICollectionViewCell
@property (nonatomic, strong) UILabel *valueLabel; // Displays the integer value (0-255)
@property (nonatomic, strong) UILabel *charLabel;  // Displays the ASCII character representation

- (void)configureWithIndex:(int)index value:(uint8_t)value;
@end
