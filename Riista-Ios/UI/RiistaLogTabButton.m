#import "RiistaLogTabButton.h"
#import "RiistaUtils.h"
#import "UIColor+ApplicationColor.h"

@implementation RiistaLogTabButton

- (void)setupStyle
{
    CGFloat selectedHeight = 6.0f;

    CGSize buttonSize = self.frame.size;
    CGRect imageFrame = self.imageView.frame;

    imageFrame = CGRectMake(0, buttonSize.height - selectedHeight, buttonSize.width, selectedHeight);

    self.imageView.frame = imageFrame;

    UIImage *selectedBackground = [RiistaUtils imageWithColor:[UIColor applicationColor:RiistaApplicationColorButtonBackground] width:buttonSize.width height:selectedHeight];
    UIImage *unselectedBackground = [RiistaUtils imageWithColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f] width:buttonSize.width height:1];

    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    self.titleLabel.contentMode = UIViewContentModeLeft;
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0f, -(buttonSize.width + self.titleLabel.frame.size.width) / 2, 0.0f, 0.0f);

    self.imageView.contentMode = UIViewContentModeBottom;
    self.imageEdgeInsets = UIEdgeInsetsMake((buttonSize.height - selectedHeight), 0, 0, 0);

    // Set transparent unselected image with equal width to keep title alignment
    [self setImage:unselectedBackground forState:UIControlStateNormal];
    [self setImage:selectedBackground forState:UIControlStateSelected];
}

@end
