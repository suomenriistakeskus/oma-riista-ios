#import <UIKit/UIKit.h>

@interface RiistaCalendarCategory : NSObject

@property (strong, nonatomic) NSString *name;
@property (assign, nonatomic) NSInteger amount;

@end

@interface RiistaCalendarYear : NSObject

@property (assign, nonatomic) NSInteger startYear;
@property (assign, nonatomic) NSInteger totalAmount;
@property (strong, nonatomic) NSArray *monthData;
@property (strong, nonatomic) NSArray *categoryData;

@end

@protocol RiistaCalendarDelegate <NSObject>

@required
- (RiistaCalendarYear*)dataForYear:(NSInteger)startYear;

@optional
- (void)calendarYearClicked:(NSInteger)year;

@end

@interface RiistaCalendarViewController : UIViewController

@property id<RiistaCalendarDelegate> delegate;
@property (assign, nonatomic) NSInteger startMonth;

- (void)selectPreviousYear:(id)sender;
- (void)selectNextYear:(id)sender;

- (NSInteger)activeSeasonStartYear;
- (NSInteger)activeSeasonTotalAmount;

- (NSInteger)activeSeasonIndex;
- (BOOL)activeSeasonHasPrevious;
- (BOOL)activeSeasonHasNext;

/**
 * Setups calendar years
 * @param calendarYears RiistaCalendarYear objects
 */
- (void)setupCalendarYears:(NSArray*)calendarYears;

/**
 * Updates existing calendar
 */
- (void)updateCalendarYear:(NSInteger)startYear withMonths:(NSArray*)months;

@end
