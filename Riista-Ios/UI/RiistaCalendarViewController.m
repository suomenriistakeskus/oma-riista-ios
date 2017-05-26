#import "RiistaCalendarViewController.h"
#import "RiistaHeaderLabel.h"
#import "RiistaLocalization.h"
#import "RiistaUtils.h"

@interface RiistaCalendarMonthView : UIView

@property (strong, nonatomic) UILabel *amountLabel;
@property (strong, nonatomic) UIView *bar;
@property (strong, nonatomic) NSLayoutConstraint *barHeight;
@property (strong, nonatomic) UILabel *monthLabel;

@end

@interface RiistaCategoryView : UIView

@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryNameLabel;

@end

@interface RiistaCalendarYearView : NSObject

@property (strong, nonatomic) UIView *monthView;
@property (strong, nonatomic) UIView *categoryView;
@property (strong, nonatomic) NSMutableArray *monthViews;

@end


@interface RiistaCalendarViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *statisticsView;

@property (strong, nonatomic) NSMutableArray *calendarYears;
@property (strong, nonatomic) NSArray *calendarYearViews;

@property (assign, nonatomic) NSInteger selectedYearIndex;

@end

@implementation RiistaCalendarViewController
{
    NSDateFormatter* dateFormatter;
}

const NSInteger totalMonths = 12;
const CGFloat CALENDAR_PADDING = 20;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setLocale:[RiistaUtils appLocale]];
        _selectedYearIndex = 0;
        _startMonth = 7;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _statisticsView.pagingEnabled = YES;
    _statisticsView.showsHorizontalScrollIndicator = NO;
    _statisticsView.showsVerticalScrollIndicator = NO;
    _statisticsView.scrollsToTop = NO;
    _statisticsView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    RiistaLanguageRefresh;
}

- (void)viewWillDisappear:(BOOL)animated
{
    CGFloat width = _statisticsView.frame.size.width;
    int page = floor((self.statisticsView.contentOffset.x - width / 2) / width) + 1;
    for (int i=0; i<_calendarYears.count; i++) {
        if (abs(i-page) > 1) {
            [((RiistaCalendarYearView*)_calendarYearViews[i]).monthView removeFromSuperview];
            ((RiistaCalendarYearView*)_calendarYearViews[i]).monthView = nil;
            [((RiistaCalendarYearView*)_calendarYearViews[i]).monthViews removeAllObjects];
        }
    }
}

- (void)selectPreviousYear:(id)sender
{
    NSInteger page = self.selectedYearIndex;
    NSInteger prevPage = (page > 0) ? page-1 : 0;
    self.selectedYearIndex = prevPage;
    CGRect frame = self.statisticsView.frame;
    frame.origin.x = frame.size.width * (prevPage);
    [self.statisticsView scrollRectToVisible:frame animated:YES];
    [self setupCalendarContent:prevPage];
}

- (void)selectNextYear:(id)sender
{
    NSInteger page = self.selectedYearIndex;
    NSInteger nextPage = (page < self.calendarYears.count-1) ? page+1 : self.calendarYears.count - 1;
    self.selectedYearIndex = nextPage;
    CGRect frame = self.statisticsView.frame;
    frame.origin.x = frame.size.width * (nextPage);
    [self.statisticsView scrollRectToVisible:frame animated:YES];
    [self setupCalendarContent:nextPage];
}

- (NSInteger)activeSeasonStartYear
{
    if (self.calendarYears.count > 0 && self.selectedYearIndex < self.calendarYears.count)
    {
        return ((RiistaCalendarYear*)self.calendarYears[self.selectedYearIndex]).startYear;
    }

    return [RiistaUtils startYearFromDate:[NSDate date]];
}

- (NSInteger)activeSeasonTotalAmount
{
    if (self.calendarYears.count > 0 && self.selectedYearIndex < self.calendarYears.count)
    {
        RiistaCalendarYear *stats = ((RiistaCalendarYear*)self.calendarYears[self.selectedYearIndex]);
        return stats.totalAmount;
    }

    return 0;
}

- (NSInteger)activeSeasonIndex
{
    return self.selectedYearIndex;
}

- (BOOL)activeSeasonHasPrevious
{
    return self.selectedYearIndex > 0;
}

- (BOOL)activeSeasonHasNext
{
    return self.selectedYearIndex < self.calendarYears.count - 1;
}

- (void)setupCalendarYears:(NSArray*)calendarStartYears
{
    NSInteger currentYear = -1;
    NSInteger previousYearIndex = -1;
    if (self.calendarYears.count > 0) {
        NSInteger currentPage = self.selectedYearIndex;
        currentYear = ((RiistaCalendarYear*)self.calendarYears[currentPage]).startYear;
    }
    
    NSMutableArray *years = [NSMutableArray new];
    for (int i=0; i<calendarStartYears.count; i++) {
        RiistaCalendarYear *year = [RiistaCalendarYear new];
        year.startYear = [calendarStartYears[i] integerValue];
        [years addObject:year];
    }
    // Adds current year as a default if no other years exist
    if (years.count == 0) {
        NSInteger curYear = [RiistaUtils startYearFromDate:[NSDate date]];
        RiistaCalendarYear *year = [RiistaCalendarYear new];
        year.startYear = curYear;
        [years addObject:year];
    }
    _calendarYears = years;
    
    // If a year was previously selected, find the position of that year in new year list
    if (currentYear != -1) {
        for (int i=0; i<self.calendarYears.count; i++) {
            if (((RiistaCalendarYear*)self.calendarYears[i]).startYear == currentYear) {
                previousYearIndex = i;
            }
        }
    }

    [_statisticsView setContentSize:CGSizeMake(_statisticsView.frame.size.width * self.calendarYears.count, _statisticsView.frame.size.height)];
    [_statisticsView setContentOffset:CGPointMake(_statisticsView.frame.size.width * (self.calendarYears.count-1), 0)];
    
    // Delete previous calendar year views if any
    for (int i=0; i<self.calendarYearViews.count; i++) {
        [((RiistaCalendarYearView*)_calendarYearViews[i]).monthView removeFromSuperview];
        [((RiistaCalendarYearView*)_calendarYearViews[i]).categoryView removeFromSuperview];
    }

    if (self.calendarYears.count > 0) {
        NSMutableArray *viewArray = [NSMutableArray new];
        for (int i=0; i<self.calendarYears.count; i++) {
            RiistaCalendarYearView *year = [RiistaCalendarYearView new];
            year.monthViews = [NSMutableArray new];
            [viewArray addObject:year];
        }

        NSInteger page = 0;
        if (previousYearIndex != -1) {
            page = previousYearIndex;
        } else {
            page = self.calendarYears.count-1;
        }

        _calendarYearViews = [viewArray copy];
        self.calendarYears[page] = [self.delegate dataForYear:((RiistaCalendarYear*)self.calendarYears[page]).startYear];
        [self setupCalendarYearView:viewArray[page] withPage:page forceUpdate:YES];
        [self setupCalendarContent:page];

        // Set correct position in scrollview
        CGRect frame = self.statisticsView.frame;
        frame.origin.x = frame.size.width * page;
        [self.statisticsView scrollRectToVisible:frame animated:NO];
        self.selectedYearIndex = page;
    }
}

- (void)updateCalendarYear:(NSInteger)startYear withMonths:(NSArray*)months
{
    NSUInteger index = [self.calendarYears indexOfObjectPassingTest:^BOOL(id obj, NSUInteger i, BOOL *stop) {
        return ((RiistaCalendarYear*)obj).startYear;
    }];
    if (index != NSNotFound) {
        ((RiistaCalendarYear*)self.calendarYears[index]).monthData = months;
        [self setupCalendarYearView:self.calendarYears[index] withPage:index forceUpdate:YES];
    }
}

- (void)setupCalendarYearView:(RiistaCalendarYearView*)calendarYearView withPage:(NSInteger)page forceUpdate:(BOOL)forceUpdate
{

    if (forceUpdate || !((RiistaCalendarYear*)self.calendarYears[page]).monthData) {
        self.calendarYears[page] = [self.delegate dataForYear:((RiistaCalendarYear*)self.calendarYears[page]).startYear];
    }
    
    UIImage *barImage = [UIImage imageNamed:@"bar.png"];

    CGFloat monthWidth = (_statisticsView.frame.size.width - 2*CALENDAR_PADDING) / totalMonths;
    NSInteger currentMonth = self.startMonth;
    
    if (!calendarYearView.monthView) {
        calendarYearView.monthView = [UIView new];
        [_statisticsView addSubview:calendarYearView.monthView];
        calendarYearView.categoryView = [UIView new];
        [_statisticsView addSubview:calendarYearView.categoryView];
    }

    CGFloat monthViewHeight = 90;
    
    calendarYearView.monthView.frame = CGRectMake(page * self.statisticsView.frame.size.width + CALENDAR_PADDING, 0, self.statisticsView.frame.size.width, monthViewHeight);
    calendarYearView.categoryView.frame = CGRectMake(page * self.statisticsView.frame.size.width, monthViewHeight, self.statisticsView.frame.size.width, self.statisticsView.frame.size.height-monthViewHeight);
    
    UIFont *amountLabelFont = [UIFont systemFontOfSize:13];
    UIFont *monthLabelFont = [UIFont systemFontOfSize:10];

    RiistaLanguageRefresh;
    [dateFormatter setLocale:[RiistaUtils appLocale]];

    for (int i=0; i<totalMonths; i++) {
        RiistaCalendarMonthView *monthView = nil;

        if (calendarYearView.monthViews.count <= i) {
            
            monthView = [RiistaCalendarMonthView new];
            monthView.amountLabel = [UILabel new];
            monthView.amountLabel.font = amountLabelFont;
            monthView.monthLabel = [UILabel new];
            monthView.monthLabel.font = monthLabelFont;
            monthView.bar = [UIView new];
            
            [calendarYearView.monthView addSubview:monthView.amountLabel];
            [calendarYearView.monthView addSubview:monthView.monthLabel];
            [calendarYearView.monthView addSubview:monthView.bar];

            [calendarYearView.monthViews addObject:monthView];
            monthView.frame = CGRectMake(i*monthWidth, 0, monthWidth, _statisticsView.frame.size.height);
        } else {
            monthView = calendarYearView.monthViews[i];
        }
        monthView.bar.backgroundColor = [UIColor colorWithPatternImage:barImage];
        NSString *dateString = [NSString stringWithFormat: @"%ld", (long)currentMonth+1];
        [dateFormatter setDateFormat:@"MM"];
        NSDate* date = [dateFormatter dateFromString:dateString];
        [dateFormatter setDateFormat:@"MMM"];
        monthView.monthLabel.text = [[dateFormatter stringFromDate:date]  uppercaseString];
        if (monthView.monthLabel.text.length > 3) {
            monthView.monthLabel.text = [monthView.monthLabel.text substringToIndex:3];
        }

        const NSInteger barPadding = 5;
        const NSInteger amountTextHeight = 20;
        const NSInteger monthTextHeight = 20;
        
        int maxValue =[[((RiistaCalendarYear*)self.calendarYears[page]).monthData valueForKeyPath:@"@max.intValue"] intValue];
        NSInteger maxBars = (monthViewHeight - amountTextHeight - monthTextHeight) / barImage.size.height;
        NSInteger amount = [((RiistaCalendarYear*)self.calendarYears[page]).monthData[currentMonth] integerValue];
        NSInteger barAmount = [self getNumberOfBars:amount :maxValue :maxBars];

        if (barAmount > maxBars)
            barAmount = maxBars;
        if (barAmount > 0) {
            monthView.amountLabel.text = [NSString stringWithFormat:@"%ld", (long)amount];
            monthView.bar.frame = CGRectMake(i*monthWidth+barPadding, monthViewHeight-monthTextHeight-barImage.size.height*barAmount, monthWidth-2*barPadding, barImage.size.height*barAmount);
        } else {
            monthView.amountLabel.text = @"";
            monthView.bar.frame = CGRectMake(i*monthWidth+barPadding, monthViewHeight-monthTextHeight-barImage.size.height*barAmount, monthWidth-2*barPadding, 2);
        }

        CGRect amountRect = [monthView.amountLabel.text boundingRectWithSize:CGSizeMake(monthWidth, amountTextHeight) options:0 attributes:@{NSFontAttributeName: amountLabelFont} context:nil];
        monthView.amountLabel.frame = CGRectMake(i*monthWidth + monthWidth/2 - amountRect.size.width/2, monthViewHeight-amountTextHeight-barImage.size.height*barAmount-monthTextHeight, monthWidth, amountTextHeight);
        CGRect monthRect = [monthView.monthLabel.text boundingRectWithSize:CGSizeMake(monthWidth, amountTextHeight) options:0 attributes:@{NSFontAttributeName: monthLabelFont} context:nil];
        monthView.monthLabel.frame = CGRectMake(i*monthWidth + monthWidth/2 - monthRect.size.width/2, monthViewHeight-monthTextHeight, monthWidth, monthTextHeight);
        
        currentMonth++;
        if (currentMonth == 12) {
            currentMonth = 0;
        }
    }
    
    // Setup categories
    [self setupCategories:((RiistaCalendarYear*)self.calendarYears[page]).categoryData forView:calendarYearView.categoryView];
    
    CALayer *topBorder = [CALayer layer];
    topBorder.frame = CGRectMake(0, 0, self.view.frame.size.width, 1);
    topBorder.backgroundColor = [UIColor colorWithWhite:0.8f
                                                  alpha:1.0f].CGColor;
    [calendarYearView.categoryView.layer addSublayer:topBorder];
}

/**
 * Scales the number of bars to show for a month based on available space and maximum value.
 */
-(NSInteger)getNumberOfBars:(NSInteger)amount :(NSInteger)maxLevel :(NSInteger)maxBars
{
    if (maxLevel <= maxBars && amount <= maxLevel) {
        return amount;
    }
    else if(amount > maxLevel) {
        return maxBars;
    }

    float count = (maxBars * (float)amount) / (float)maxLevel;
    return ceil(count);
}

/**
 * Setups calendar content for given page
 */
- (void)setupCalendarContent:(NSInteger)page
{
    [self updateAdjacentCalendarViews:page];
}

/**
 * Setups adjacent calendar views for specified page
 */
- (void)updateAdjacentCalendarViews:(NSInteger)page
{
    if (page-1 >= 0) {
        [self setupCalendarYearView:self.calendarYearViews[page-1] withPage:page-1 forceUpdate:NO];
    }
    if (page+1 < self.calendarYears.count) {
        [self setupCalendarYearView:self.calendarYearViews[page+1] withPage:page+1 forceUpdate:NO];
    }
}

- (void)setupCategories:(NSArray*)categories forView:(UIView*)categoryView
{
    for (UIView *view in categoryView.subviews) {
        [view removeFromSuperview];
    }

    CGFloat width = categoryView.frame.size.width / categories.count;
    for (int i=0; i<categories.count; i++) {
        RiistaCategoryView *view = [[[NSBundle mainBundle] loadNibNamed:@"RiistaCategoryView" owner:self options:nil] firstObject];
        [categoryView addSubview:view];
        view.frame = CGRectMake(i*width, 1.0f, width, categoryView.frame.size.height-1.0f);
        view.amountLabel.text = [NSString stringWithFormat:@"%ld", (long)((RiistaCalendarCategory*)categories[i]).amount];
        view.categoryNameLabel.text = ((RiistaCalendarCategory*)categories[i]).name;
        [view.categoryNameLabel sizeToFit];
        
        if (i>0) {
            CALayer *leftBorder = [CALayer layer];
            leftBorder.frame = CGRectMake(0, 0, 1, view.frame.size.height);
            leftBorder.backgroundColor = [UIColor colorWithWhite:0.8f
                                                             alpha:1.0f].CGColor;
            [view.layer addSublayer:leftBorder];
        }
    }

}

# pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    NSInteger page = [self currentScrollPage];
    if (page >= 0 && page < self.calendarYears.count) {
        [self setupCalendarContent:page];
    }
}

- (NSInteger)currentScrollPage
{
    CGFloat width = _statisticsView.frame.size.width;
    return floor((self.statisticsView.contentOffset.x - width / 2) / width) + 1;
}

@end

@implementation RiistaCalendarCategory
@end

@implementation RiistaCalendarYear
@end

@implementation RiistaCalendarYearView
@end

@implementation RiistaCalendarMonthView
@end

@implementation RiistaCategoryView
@end
