//
//  AGViewController.m
//  AGEmojiKeyboardSample
//
//  Created by Ayush on 23/03/14.
//  Copyright (c) 2014 Ayush. All rights reserved.
//

#import "AGViewController.h"
#import <AGEmojiKeyboard/AGEmojiKeyboardView.h>

@interface AGViewController () <AGEmojiKeyboardViewDelegate, AGEmojiKeyboardViewDataSource>

@property (nonatomic) IBOutlet UITextView *textView;

@end

@implementation AGViewController

- (void)viewDidLoad {
  [super viewDidLoad];
    AGEmojiKeyboardView *emojiKeyboardView = [[AGEmojiKeyboardView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 216)
                                                                       pageControlFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 20)
                                                                       buttonsBarFrame:CGRectMake(0, 216 - 47, CGRectGetWidth(self.view.bounds), 47)
                                                                             dataSource:self];
    emojiKeyboardView.pageIndicatorTintColor = [UIColor colorWithRed:165/255.0 green:168/255.0 blue:172/255.0 alpha:1.0];
    emojiKeyboardView.currentPageIndicatorTintColor = [UIColor colorWithRed:103/255.0 green:105/255.0 blue:108/255.0 alpha:1.0];
    emojiKeyboardView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  emojiKeyboardView.delegate = self;
  self.textView.inputView = emojiKeyboardView;
}

- (void)emojiKeyBoardView:(AGEmojiKeyboardView *)emojiKeyBoardView didUseEmoji:(NSString *)emoji {
  self.textView.text = [self.textView.text stringByAppendingString:emoji];
}

- (void)emojiKeyBoardViewDidPressBackSpace:(AGEmojiKeyboardView *)emojiKeyBoardView {

}

- (UIColor *)randomColor {
  return [UIColor colorWithRed:drand48()
                         green:drand48()
                          blue:drand48()
                         alpha:drand48()];
}

- (UIImage *)randomImage {
  CGSize size = CGSizeMake(30, 10);
  UIGraphicsBeginImageContextWithOptions(size , NO, 0);

  CGContextRef context = UIGraphicsGetCurrentContext();
  UIColor *fillColor = [self randomColor];
  CGContextSetFillColorWithColor(context, [fillColor CGColor]);
  CGRect rect = CGRectMake(0, 0, size.width, size.height);
  CGContextFillRect(context, rect);

  fillColor = [self randomColor];
  CGContextSetFillColorWithColor(context, [fillColor CGColor]);
  CGFloat xxx = 3;
  rect = CGRectMake(xxx, xxx, size.width - 2 * xxx, size.height - 2 * xxx);
  CGContextFillRect(context, rect);

  UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return img;
}

- (UIImage *)emojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView imageForSelectedCategory:(AGEmojiKeyboardViewCategoryImage)category {
  UIImage *img = [self randomImage];
  [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  return img;
}

- (UIImage *)emojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView imageForNonSelectedCategory:(AGEmojiKeyboardViewCategoryImage)category {
  UIImage *img = [self randomImage];
  [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  return img;
}

- (UIImage *)backSpaceButtonImageForEmojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView {
  UIImage *img = [self randomImage];
  [img imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
  return img;
}

- (BOOL)shouldAddBackSpaceButtonToEmojiKeyboardView {
    return NO;
}

- (UIColor *)emojiKeyboardViewBackgroundColor {
   return [UIColor colorWithRed:206/255.0 green:209/255.0 blue:214/255.0 alpha:1.0];
}

- (UIColor *)selectedButtonBackgroundColor {
    return [UIColor colorWithRed:186/255.0 green:189/255.0 blue:194/255.0 alpha:1.0];
}

- (UIColor *)unselectedButtonBackgroundColor {
    return [UIColor colorWithRed:247/255.0 green:248/255.0 blue:248/255.0 alpha:1.0];
}

- (UIColor *)buttonsViewBackgroundColor {
    return [UIColor colorWithRed:173/255.0 green:176/255.0 blue:179/255.0 alpha:1.0];
}

@end
