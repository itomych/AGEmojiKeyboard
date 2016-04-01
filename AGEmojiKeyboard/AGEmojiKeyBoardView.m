//
//  AGEmojiKeyboardView.m
//  AGEmojiKeyboard
//
//  Created by Ayush on 09/05/13.
//  Copyright (c) 2013 Ayush. All rights reserved.
//

#import "AGEmojiKeyBoardView.h"
#import "AGEmojiPageView.h"
#import "UIImage+UIColor.h"

static const CGFloat ButtonWidth = 45;
static const CGFloat ButtonHeight = 37;

static const NSUInteger DefaultRecentEmojisMaintainedCount = 50;
static const CGFloat AGSelectingButtonMargin = 0.5;

static NSString *const segmentRecentName = @"Recent";
NSString *const RecentUsedEmojiCharactersKey = @"RecentUsedEmojiCharactersKey";


@interface AGEmojiKeyboardView () <UIScrollViewDelegate, AGEmojiPageViewDelegate>

@property (nonatomic) UISegmentedControl *segmentsBar;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) UIScrollView *emojiPagesScrollView;
@property (nonatomic) NSDictionary *emojis;
@property (nonatomic) NSMutableArray *pageViews;
@property (nonatomic) NSString *category;
@property (nonatomic) NSArray *buttons;

@property (nonatomic) CGRect pageControlFrame;
@property (nonatomic) CGRect emojiPagesFrame;
@property (nonatomic) CGRect segmentsBarFrame;
@property (nonatomic) CGRect buttonsBarFrame;

@end

@implementation AGEmojiKeyboardView

- (NSDictionary *)emojis {
  if (!_emojis) {
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"EmojisList"
                                                          ofType:@"plist"];
    _emojis = [[NSDictionary dictionaryWithContentsOfFile:plistPath] copy];
  }
  return _emojis;
}

- (NSString *)categoryNameAtIndex:(NSUInteger)index {
  NSArray *categoryList = @[segmentRecentName, @"People", @"Objects", @"Nature", @"Places", @"Symbols"];
  return categoryList[index];
}

- (AGEmojiKeyboardViewCategoryImage)defaultSelectedCategory {
  if ([self.dataSource respondsToSelector:@selector(defaultCategoryForEmojiKeyboardView:)]) {
    return [self.dataSource defaultCategoryForEmojiKeyboardView:self];
  }
  return AGEmojiKeyboardViewCategoryImageRecent;
}

- (NSUInteger)recentEmojisMaintainedCount {
  if ([self.dataSource respondsToSelector:@selector(recentEmojisMaintainedCountForEmojiKeyboardView:)]) {
    return [self.dataSource recentEmojisMaintainedCountForEmojiKeyboardView:self];
  }
  return DefaultRecentEmojisMaintainedCount;
}

- (NSArray *)imagesForSelectedSegments {
  static NSMutableArray *array;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    array = [NSMutableArray array];
    for (AGEmojiKeyboardViewCategoryImage i = AGEmojiKeyboardViewCategoryImageRecent;
         i <= AGEmojiKeyboardViewCategoryImageCharacters;
         ++i) {
      [array addObject:[self.dataSource emojiKeyboardView:self imageForSelectedCategory:i]];
    }
  });
  return array;
}

- (NSArray *)imagesForNonSelectedSegments {
  static NSMutableArray *array;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    array = [NSMutableArray array];
    for (AGEmojiKeyboardViewCategoryImage i = AGEmojiKeyboardViewCategoryImageRecent;
         i <= AGEmojiKeyboardViewCategoryImageCharacters;
         ++i) {
      [array addObject:[self.dataSource emojiKeyboardView:self imageForNonSelectedCategory:i]];
    }
  });
  return array;
}

// recent emojis are backed in NSUserDefaults to save them across app restarts.
- (NSMutableArray *)recentEmojis {
  NSArray *emojis = [[NSUserDefaults standardUserDefaults] arrayForKey:RecentUsedEmojiCharactersKey];
  NSMutableArray *recentEmojis = [emojis mutableCopy];
  if (recentEmojis == nil) {
    recentEmojis = [NSMutableArray array];
  }
  return recentEmojis;
}

- (void)setRecentEmojis:(NSMutableArray *)recentEmojis {
  // remove emojis if they cross the cache maintained limit
  if ([recentEmojis count] > self.recentEmojisMaintainedCount) {
    NSRange indexRange = NSMakeRange(self.recentEmojisMaintainedCount,
                                     [recentEmojis count] - self.recentEmojisMaintainedCount);
    NSIndexSet *indexesToBeRemoved = [NSIndexSet indexSetWithIndexesInRange:indexRange];
    [recentEmojis removeObjectsAtIndexes:indexesToBeRemoved];
  }
  [[NSUserDefaults standardUserDefaults] setObject:recentEmojis forKey:RecentUsedEmojiCharactersKey];
}

- (instancetype)initWithFrame:(CGRect)frame dataSource:(id<AGEmojiKeyboardViewDataSource>)dataSource {
  self = [super initWithFrame:frame];
  if (self) {
    // initialize category

    _dataSource = dataSource;

    self.category = [self categoryNameAtIndex:self.defaultSelectedCategory];

      if (CGRectGetHeight(self.segmentsBarFrame)) {
          self.segmentsBar = [[UISegmentedControl alloc] initWithItems:self.imagesForSelectedSegments];
          self.segmentsBar.frame = self.segmentsBarFrame;
          self.segmentsBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
          
          [self.segmentsBar addTarget:self
                               action:@selector(categoryChangedViaSegmentsBar:)
                     forControlEvents:UIControlEventValueChanged];
          [self setSelectedCategoryImageInSegmentControl:self.segmentsBar
                                                 atIndex:self.defaultSelectedCategory];
          self.segmentsBar.selectedSegmentIndex = self.defaultSelectedCategory;
          [self addSubview:self.segmentsBar];
      }
      if (CGRectGetHeight(self.buttonsBarFrame)) {
          UIView *buttonsView = [[UIView alloc] initWithFrame:self.buttonsBarFrame];
          buttonsView.backgroundColor = [self.dataSource buttonsViewBackgroundColor];
          int count = (int)self.imagesForSelectedSegments.count;
          CGFloat buttonWidth = (CGRectGetWidth(self.buttonsBarFrame) - (count + 2) * AGSelectingButtonMargin) / (count + 1);
          NSMutableArray *buttons = [NSMutableArray array];
          for (int i = 0; i < count; i++) {
              UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
              CGFloat offset = AGSelectingButtonMargin + i * (buttonWidth + AGSelectingButtonMargin);
              button.frame = CGRectMake(offset, AGSelectingButtonMargin, buttonWidth, CGRectGetHeight(self.buttonsBarFrame) - AGSelectingButtonMargin);
              [button setImage:self.imagesForNonSelectedSegments[i] forState:UIControlStateNormal];
              [button setImage:self.imagesForSelectedSegments[i] forState:UIControlStateSelected];
              [button setBackgroundImage:[UIImage resizableImageWithColor:[self.dataSource unselectedButtonBackgroundColor] cornerRadius:0] forState:UIControlStateNormal];
              [button setBackgroundImage:[UIImage resizableImageWithColor:[self.dataSource selectedButtonBackgroundColor] cornerRadius:0] forState:UIControlStateSelected];
              [button setBackgroundImage:[UIImage resizableImageWithColor:[self.dataSource selectedButtonBackgroundColor] cornerRadius:0] forState:UIControlStateSelected | UIControlStateHighlighted];
              [button setBackgroundImage:[UIImage resizableImageWithColor:[self.dataSource selectedButtonBackgroundColor] cornerRadius:0] forState:UIControlStateHighlighted];
              button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
              button.tag = i;
              [button addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
              button.selected = i == 0 ? YES : NO;
              [buttonsView addSubview:button];
              [buttons addObject:button];
          }
          UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
          deleteButton.frame = CGRectMake(AGSelectingButtonMargin + count * (buttonWidth + AGSelectingButtonMargin), AGSelectingButtonMargin, buttonWidth, CGRectGetHeight(self.buttonsBarFrame) - AGSelectingButtonMargin);
          [deleteButton setImage:[self.dataSource backSpaceButtonImageForEmojiKeyboardView:self] forState:UIControlStateNormal];
          deleteButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
          deleteButton.tag = count;
          deleteButton.backgroundColor = [self.dataSource selectedButtonBackgroundColor];
          [deleteButton addTarget:self action:@selector(emojiPageViewDidPressBackSpace:) forControlEvents:UIControlEventTouchUpInside];
          [buttonsView addSubview:deleteButton];
          [buttons addObject:deleteButton];
          self.buttons = [buttons copy];
          
          [self addSubview:buttonsView];
      }

    self.pageControl = [[UIPageControl alloc] init];
    self.pageControl.hidesForSinglePage = YES;
    self.pageControl.currentPage = 0;
    self.pageControl.backgroundColor = [UIColor clearColor];
    CGSize pageControlSize = [self.pageControl sizeForNumberOfPages:3];
    CGSize frameSize = CGSizeMake(CGRectGetWidth(self.bounds),
                                  CGRectGetHeight(self.bounds) - CGRectGetHeight(self.segmentsBar.bounds) - pageControlSize.height);
    NSUInteger numberOfPages = [self numberOfPagesForCategory:self.category
                                                  inFrameSize:frameSize];
    self.pageControl.numberOfPages = numberOfPages;
    pageControlSize = [self.pageControl sizeForNumberOfPages:numberOfPages];
    CGRect pageControlFrame = CGRectMake((CGRectGetWidth(self.bounds) - pageControlSize.width) / 2,
                                         self.pageControlFrame.origin.y,
                                         pageControlSize.width,
                                         CGRectGetHeight(self.pageControlFrame));
    self.pageControl.frame = CGRectIntegral(pageControlFrame);
    [self.pageControl addTarget:self
                         action:@selector(pageControlTouched:)
               forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.pageControl];

    CGFloat barHeight = CGRectGetHeight(self.segmentsBarFrame) ? CGRectGetHeight(self.segmentsBarFrame) : CGRectGetHeight(self.buttonsBarFrame);
                                        
    self.emojiPagesScrollView = [[UIScrollView alloc] initWithFrame:self.emojiPagesFrame];
    self.emojiPagesScrollView.backgroundColor = [UIColor clearColor];
    self.emojiPagesScrollView.pagingEnabled = YES;
    self.emojiPagesScrollView.showsHorizontalScrollIndicator = NO;
    self.emojiPagesScrollView.showsVerticalScrollIndicator = NO;
    self.emojiPagesScrollView.delegate = self;

    self.backgroundColor = [self.dataSource emojiKeyboardViewBackgroundColor];
    [self addSubview:self.emojiPagesScrollView];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame pageControlFrame:(CGRect)pageControlFrame segmentsBarFrame:(CGRect)segmentsBarFrame dataSource:(id<AGEmojiKeyboardViewDataSource>)dataSource {
    self.pageControlFrame = pageControlFrame;
    self.segmentsBarFrame = segmentsBarFrame;
    return [self initWithFrame:frame dataSource:dataSource];
}

- (instancetype)initWithFrame:(CGRect)frame emojiPagesFrame:(CGRect)emojiPagesFrame pageControlFrame:(CGRect)pageControlFrame buttonsBarFrame:(CGRect)buttonsBarFrame dataSource:(id<AGEmojiKeyboardViewDataSource>)dataSource {
    self.emojiPagesFrame = emojiPagesFrame;
    self.pageControlFrame = pageControlFrame;
    self.buttonsBarFrame = buttonsBarFrame;
    return [self initWithFrame:frame dataSource:dataSource];
}


- (void)layoutSubviews {
  CGSize pageControlSize = [self.pageControl sizeForNumberOfPages:3];
  NSUInteger numberOfPages = [self numberOfPagesForCategory:self.category
                                                inFrameSize:CGSizeMake(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds) - CGRectGetHeight(self.segmentsBar.bounds) - pageControlSize.height)];

  NSInteger currentPage = (self.pageControl.currentPage > numberOfPages) ? numberOfPages : self.pageControl.currentPage;

  // if (currentPage > numberOfPages) it is set implicitly to max pageNumber available
  self.pageControl.numberOfPages = numberOfPages;
  pageControlSize = [self.pageControl sizeForNumberOfPages:numberOfPages];
  CGRect pageControlFrame = CGRectMake((CGRectGetWidth(self.bounds) - pageControlSize.width) / 2,
                                       self.pageControlFrame.origin.y,
                                       pageControlSize.width,
                                       CGRectGetHeight(self.pageControlFrame));
  self.pageControl.frame = CGRectIntegral(pageControlFrame);
  self.pageControl.pageIndicatorTintColor = self.pageIndicatorTintColor;
  self.pageControl.currentPageIndicatorTintColor = self.currentPageIndicatorTintColor;
  
  CGFloat barHeight = CGRectGetHeight(self.segmentsBarFrame) ? CGRectGetHeight(self.segmentsBarFrame) : CGRectGetHeight(self.buttonsBarFrame);
  self.emojiPagesScrollView.frame = self.emojiPagesFrame;
  [self.emojiPagesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
  self.emojiPagesScrollView.contentOffset = CGPointMake(CGRectGetWidth(self.emojiPagesScrollView.bounds) * currentPage, 0);
  self.emojiPagesScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.emojiPagesScrollView.bounds) * numberOfPages,
                                                     CGRectGetHeight(self.emojiPagesScrollView.bounds));
  [self purgePageViews];
  self.pageViews = [NSMutableArray array];
  [self setPage:currentPage];
}

#pragma mark event handlers

- (void)buttonSelected:(UIButton *)button {
    self.category = [self categoryNameAtIndex:button.tag];
    self.pageControl.currentPage = 0;
    for (UIButton *item in self.buttons) {
        item.selected = item == button ? YES : NO;
    }
    [self setNeedsLayout];
}

- (void)setSelectedCategoryImageInSegmentControl:(UISegmentedControl *)segmentsBar
                                         atIndex:(NSInteger)index {
  for (int i=0; i < self.segmentsBar.numberOfSegments; ++i) {
    [segmentsBar setImage:self.imagesForNonSelectedSegments[i] forSegmentAtIndex:i];
  }
  [segmentsBar setImage:self.imagesForSelectedSegments[index] forSegmentAtIndex:index];
}

- (void)categoryChangedViaSegmentsBar:(UISegmentedControl *)sender {
  // recalculate number of pages for new category and recreate emoji pages
  self.category = [self categoryNameAtIndex:sender.selectedSegmentIndex];
  [self setSelectedCategoryImageInSegmentControl:sender
                                         atIndex:sender.selectedSegmentIndex];
  self.pageControl.currentPage = 0;
  [self setNeedsLayout];
}

- (void)pageControlTouched:(UIPageControl *)sender {
  CGRect bounds = self.emojiPagesScrollView.bounds;
  bounds.origin.x = CGRectGetWidth(bounds) * sender.currentPage;
  bounds.origin.y = 0;
  // scrollViewDidScroll is called here. Page set at that time.
  [self.emojiPagesScrollView scrollRectToVisible:bounds animated:YES];
}

// Track the contentOffset of the scroll view, and when it passes the mid
// point of the current view’s width, the views are reconfigured.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  CGFloat pageWidth = CGRectGetWidth(scrollView.frame);
  NSInteger newPageNumber = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
  if (self.pageControl.currentPage == newPageNumber) {
    return;
  }
  self.pageControl.currentPage = newPageNumber;
  [self setPage:self.pageControl.currentPage];
}

#pragma mark change a page on scrollView

// Check if setting pageView for an index is required
- (BOOL)requireToSetPageViewForIndex:(NSUInteger)index {
  if (index >= self.pageControl.numberOfPages) {
    return NO;
  }
  for (AGEmojiPageView *page in self.pageViews) {
    if ((page.frame.origin.x / CGRectGetWidth(self.emojiPagesScrollView.bounds)) == index) {
      return NO;
    }
  }
  return YES;
}

// Create a pageView and add it to the scroll view.
- (AGEmojiPageView *)synthesizeEmojiPageView {
  NSUInteger rows = [self numberOfRowsForFrameSize:self.emojiPagesScrollView.bounds.size];
  NSUInteger columns = [self numberOfColumnsForFrameSize:self.emojiPagesScrollView.bounds.size];
  CGRect pageViewFrame = self.emojiPagesScrollView.frame;
  UIImage *backSpaceImage;
  if ([self.dataSource shouldAddBackSpaceButtonToEmojiKeyboardView]) {
      backSpaceImage = [self.dataSource backSpaceButtonImageForEmojiKeyboardView:self];
  }
  AGEmojiPageView *pageView = [[AGEmojiPageView alloc] initWithFrame:pageViewFrame
                                                backSpaceButtonImage:backSpaceImage
                                                          buttonSize:CGSizeMake(ButtonWidth, ButtonHeight)
                                                                rows:rows
                                                             columns:columns];
  pageView.delegate = self;
  [self.pageViews addObject:pageView];
  [self.emojiPagesScrollView addSubview:pageView];
  return pageView;
}

// return a pageView that can be used in the current scrollView.
// look for an available pageView in current pageView-s on scrollView.
// If all are in use i.e. are of current page or neighbours
// of current page, we create a new one

- (AGEmojiPageView *)usableEmojiPageView {
  AGEmojiPageView *pageView = nil;
  for (AGEmojiPageView *page in self.pageViews) {
    NSUInteger pageNumber = page.frame.origin.x / CGRectGetWidth(self.emojiPagesScrollView.bounds);
    if (abs((int)(pageNumber - self.pageControl.currentPage)) > 1) {
      pageView = page;
      break;
    }
  }
  if (!pageView) {
    pageView = [self synthesizeEmojiPageView];
  }
  return pageView;
}

// Set emoji page view for given index.
- (void)setEmojiPageViewInScrollView:(UIScrollView *)scrollView atIndex:(NSUInteger)index {

  if (![self requireToSetPageViewForIndex:index]) {
    return;
  }

  AGEmojiPageView *pageView = [self usableEmojiPageView];

  NSUInteger rows = [self numberOfRowsForFrameSize:scrollView.bounds.size];
  NSUInteger columns = [self numberOfColumnsForFrameSize:scrollView.bounds.size];
  NSUInteger backSpaceButton = [self.dataSource shouldAddBackSpaceButtonToEmojiKeyboardView] ? 1 : 0;
  NSUInteger startingIndex = index * (rows * columns - backSpaceButton);
  NSUInteger endingIndex = (index + 1) * (rows * columns - backSpaceButton);
  NSMutableArray *buttonTexts = [self emojiTextsForCategory:self.category
                                                  fromIndex:startingIndex
                                                    toIndex:endingIndex];
  [pageView setButtonTexts:buttonTexts];
  pageView.frame = CGRectMake(index * CGRectGetWidth(scrollView.bounds),
                              0,
                              CGRectGetWidth(scrollView.bounds),
                              CGRectGetHeight(scrollView.bounds));
}

// Set the current page.
// sets neightbouring pages too, as they are viewable by part scrolling.
- (void)setPage:(NSInteger)page {
  [self setEmojiPageViewInScrollView:self.emojiPagesScrollView atIndex:page - 1];
  [self setEmojiPageViewInScrollView:self.emojiPagesScrollView atIndex:page];
  [self setEmojiPageViewInScrollView:self.emojiPagesScrollView atIndex:page + 1];
}

- (void)purgePageViews {
  for (AGEmojiPageView *page in self.pageViews) {
    page.delegate = nil;
  }
  self.pageViews = nil;
}

#pragma mark data methods

- (NSUInteger)numberOfColumnsForFrameSize:(CGSize)frameSize {
  return (NSUInteger)floor(frameSize.width / ButtonWidth);
}

- (NSUInteger)numberOfRowsForFrameSize:(CGSize)frameSize {
  return (NSUInteger)floor(frameSize.height / ButtonHeight);
}

- (NSArray *)emojiListForCategory:(NSString *)category {
  if ([category isEqualToString:segmentRecentName]) {
    return [self recentEmojis];
  }
  return [self.emojis objectForKey:category];
}

// for a given frame size of scroll view, return the number of pages
// required to show all the emojis for a category
- (NSUInteger)numberOfPagesForCategory:(NSString *)category inFrameSize:(CGSize)frameSize {

  if ([category isEqualToString:segmentRecentName]) {
    return 1;
  }

  NSUInteger emojiCount = [[self emojiListForCategory:category] count];
  NSUInteger numberOfRows = [self numberOfRowsForFrameSize:frameSize];
  NSUInteger numberOfColumns = [self numberOfColumnsForFrameSize:frameSize];
  NSUInteger numberOfEmojisOnAPage = (numberOfRows * numberOfColumns) - 1;

  NSUInteger numberOfPages = (NSUInteger)ceil((float)emojiCount / numberOfEmojisOnAPage);
  return numberOfPages;
}

// return the emojis for a category, given a staring and an ending index
- (NSMutableArray *)emojiTextsForCategory:(NSString *)category
                                fromIndex:(NSUInteger)start
                                  toIndex:(NSUInteger)end {
  NSArray *emojis = [self emojiListForCategory:category];
  end = ([emojis count] > end)? end : [emojis count];
  NSIndexSet *index = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(start, end-start)];
  return [[emojis objectsAtIndexes:index] mutableCopy];
}

#pragma mark EmojiPageViewDelegate

- (void)setInRecentsEmoji:(NSString *)emoji {
  NSAssert(emoji != nil, @"Emoji can't be nil");

  NSMutableArray *recentEmojis = [self recentEmojis];
  for (int i = 0; i < [recentEmojis count]; ++i) {
    if ([recentEmojis[i] isEqualToString:emoji]) {
      [recentEmojis removeObjectAtIndex:i];
    }
  }
  [recentEmojis insertObject:emoji atIndex:0];
  [self setRecentEmojis:recentEmojis];
}

// add the emoji to recents
- (void)emojiPageView:(AGEmojiPageView *)emojiPageView didUseEmoji:(NSString *)emoji {
  [self setInRecentsEmoji:emoji];
  [self.delegate emojiKeyBoardView:self didUseEmoji:emoji];
}

- (void)emojiPageViewDidPressBackSpace:(AGEmojiPageView *)emojiPageView {
  [self.delegate emojiKeyBoardViewDidPressBackSpace:self];
}

@end
