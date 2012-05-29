//
//	ReaderViewController.m
//	Reader v2.5.4
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderConstants.h"
#import "ReaderViewController.h"
#import "ReaderThumbCache.h"
#import "ReaderThumbQueue.h"
#import "Scanner.h"
#import "CGPDFDocument.h"

@implementation ReaderViewController
@synthesize selections, scanner,keyword;

#pragma mark Constants

#define PAGING_VIEWS 3

#define TOOLBAR_HEIGHT 44.0f
#define PAGEBAR_HEIGHT 48.0f

#define TAP_AREA_SIZE 48.0f
#define BUTTON_X 8.0f
#define BUTTON_Y 8.0f
#define BUTTON_SPACE 8.0f
#define BUTTON_HEIGHT 30.0f

#define DONE_BUTTON_WIDTH 56.0f
#define SHOW_CONTROL_WIDTH 78.0f

#define TITLE_HEIGHT 28.0f

#pragma mark Properties

@synthesize delegate;
@synthesize searchBar;
#pragma mark Support methods

- (void)updateScrollViewContentSize
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger count = [document.pageCount integerValue];

	if (count > PAGING_VIEWS) count = PAGING_VIEWS; // Limit

	CGFloat contentHeight = theScrollView.bounds.size.height;

	CGFloat contentWidth = (theScrollView.bounds.size.width * count);

	theScrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)updateScrollViewContentViews
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self updateScrollViewContentSize]; // Update the content size

	NSMutableIndexSet *pageSet = [NSMutableIndexSet indexSet]; // Page set

	[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(id key, id object, BOOL *stop)
		{
			ReaderContentView *contentView = object; [pageSet addIndex:contentView.tag];
		}
	];

	__block CGRect viewRect = CGRectZero; viewRect.size = theScrollView.bounds.size;

	__block CGPoint contentOffset = CGPointZero; NSInteger page = [document.pageNumber integerValue];

	[pageSet enumerateIndexesUsingBlock: // Enumerate page number set
		^(NSUInteger number, BOOL *stop)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [contentViews objectForKey:key];

			contentView.frame = viewRect; if (page == number) contentOffset = viewRect.origin;

			viewRect.origin.x += viewRect.size.width; // Next view frame position
		}
	];

	if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == false)
	{
		theScrollView.contentOffset = contentOffset; // Update content offset
	}
}

- (void)updateToolbarBookmarkIcon
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger page = [document.pageNumber integerValue];

	BOOL bookmarked = [document.bookmarks containsIndex:page];

	[mainToolbar setBookmarkState:bookmarked]; // Update
}

- (void)showDocumentPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (page != currentPage) // Only if different
	{
		NSInteger minValue; NSInteger maxValue;
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1;

		if ((page < minPage) || (page > maxPage)) return;

		if (maxPage <= PAGING_VIEWS) // Few pages
		{
			minValue = minPage;
			maxValue = maxPage;
		}
		else // Handle more pages
		{
			minValue = (page - 1);
			maxValue = (page + 1);

			if (minValue < minPage)
				{minValue++; maxValue++;}
			else
				if (maxValue > maxPage)
					{minValue--; maxValue--;}
		}

		NSMutableIndexSet *newPageSet = [NSMutableIndexSet new];

		NSMutableDictionary *unusedViews = [contentViews mutableCopy];

		CGRect viewRect = CGRectZero; viewRect.size = theScrollView.bounds.size;

		for (NSInteger number = minValue; number <= maxValue; number++)
		{
			NSNumber *key = [NSNumber numberWithInteger:number]; // # key

			ReaderContentView *contentView = [contentViews objectForKey:key];

            if(Searching==YES && number==page  )
            {
                [contentView removeFromSuperview];
                for(UIView *bw in theScrollView.subviews)
                {
                    if(bw.tag == number-1)
                    {
                        [bw removeFromSuperview];
                    }
                }
				NSURL *fileURL = document.fileURL; NSString *phrase = document.password; // Document properties
                
				contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:number password:phrase];
                contentView.tag=number;
				[theScrollView addSubview:contentView]; [contentViews setObject:contentView forKey:key];
                
				contentView.message = self; 
                [contentView zoomReset];
                [unusedViews removeObjectForKey:key];
                contentView.frame = viewRect;
                [contentView release]; 
                //       [newPageSet addIndex:number];           
            }
            
            else if(Searching==YES && number== (page+1)  )
            { 
                [contentView removeFromSuperview];
                for(UIView *bw in theScrollView.subviews)
                {
                    if(bw.tag == number-1)
                    {
                        //[bw removeFromSuperview];
                    }
                }
                NSURL *fileURL = document.fileURL; NSString *phrase = document.password; // Document properties
                
                contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:number password:phrase];
                contentView.tag=number;
                [theScrollView addSubview:contentView]; [contentViews setObject:contentView forKey:key];
                
                contentView.message = self; 
                [contentView zoomReset];
                [unusedViews removeObjectForKey:key];
                contentView.frame = viewRect;
                [contentView release]; 
                
                
            }
            else if (contentView == nil) // Create a brand new document content view
			{
				NSURL *fileURL = document.fileURL; NSString *phrase = document.password; // Document properties

				contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:number password:phrase];

				[theScrollView addSubview:contentView]; [contentViews setObject:contentView forKey:key];

				contentView.message = self; [contentView release]; [newPageSet addIndex:number];
			}
			else // Reposition the existing content view
			{
				contentView.frame = viewRect; [contentView zoomReset];

				[unusedViews removeObjectForKey:key];
			}

			viewRect.origin.x += viewRect.size.width;
		}
        Searching=NO;

		[unusedViews enumerateKeysAndObjectsUsingBlock: // Remove unused views
			^(id key, id object, BOOL *stop)
			{
				[contentViews removeObjectForKey:key];

				ReaderContentView *contentView = object;

				[contentView removeFromSuperview];
			}
		];

		[unusedViews release], unusedViews = nil; // Release unused views

		CGFloat viewWidthX1 = viewRect.size.width;
		CGFloat viewWidthX2 = (viewWidthX1 * 2.0f);

		CGPoint contentOffset = CGPointZero;

		if (maxPage >= PAGING_VIEWS)
		{
			if (page == maxPage)
				contentOffset.x = viewWidthX2;
			else
				if (page != minPage)
					contentOffset.x = viewWidthX1;
		}
		else
			if (page == (PAGING_VIEWS - 1))
				contentOffset.x = viewWidthX1;

		if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == false)
		{
			theScrollView.contentOffset = contentOffset; // Update content offset
		}

		if ([document.pageNumber integerValue] != page) // Only if different
		{
			document.pageNumber = [NSNumber numberWithInteger:page]; // Update page number
		}

		NSURL *fileURL = document.fileURL; NSString *phrase = document.password; NSString *guid = document.guid;

		if ([newPageSet containsIndex:page] == YES) // Preview visible page first
		{
			NSNumber *key = [NSNumber numberWithInteger:page]; // # key

			ReaderContentView *targetView = [contentViews objectForKey:key];

			[targetView showPageThumb:fileURL page:page password:phrase guid:guid];

			[newPageSet removeIndex:page]; // Remove visible page from set
		}

		[newPageSet enumerateIndexesWithOptions:NSEnumerationReverse usingBlock: // Show previews
			^(NSUInteger number, BOOL *stop)
			{
				NSNumber *key = [NSNumber numberWithInteger:number]; // # key

				ReaderContentView *targetView = [contentViews objectForKey:key];

				[targetView showPageThumb:fileURL page:number password:phrase guid:guid];
			}
		];

		[newPageSet release], newPageSet = nil; // Release new page set

		[mainPagebar updatePagebar]; // Update the pagebar display

		[self updateToolbarBookmarkIcon]; // Update bookmark

		currentPage = page; // Track current page number
    }
}
//- (FontCollection *)activeFontCollection
//{
//	Page *page = [pageView pageAtIndex:pageView.page];
//	PDFContentView *pdfPage = (PDFContentView *) [(PDFPage *) page contentView];
//	return [[pdfPage scanner] fontCollection];
//}

- (void)showDocument:(id)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self updateScrollViewContentSize]; // Set content size

	[self showDocumentPage:[document.pageNumber integerValue]]; // Show

	document.lastOpen = [NSDate date]; // Update last opened date

	isVisible = YES; // iOS present modal bodge
}

#pragma mark UIViewController methods

- (id)initWithReaderDocument:(ReaderDocument *)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	id reader = nil; // ReaderViewController object

	if ((object != nil) && ([object isKindOfClass:[ReaderDocument class]]))
	{
		if ((self = [super initWithNibName:nil bundle:nil])) // Designated initializer
		{
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

			[notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillTerminateNotification object:nil];

			[notificationCenter addObserver:self selector:@selector(applicationWill:) name:UIApplicationWillResignActiveNotification object:nil];

			[object updateProperties]; document = [object retain]; // Retain the supplied ReaderDocument object for our use

			[ReaderThumbCache touchThumbCacheWithGUID:object.guid]; // Touch the document thumb cache directory

			reader = self; // Return an initialized ReaderViewController object
		}
	}

	return reader;
}

/*
- (void)loadView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	// Implement loadView to create a view hierarchy programmatically, without using a nib.
}
*/

- (void)viewDidLoad
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewDidLoad];

	NSAssert(!(document == nil), @"ReaderDocument == nil");

	assert(self.splitViewController == nil); // Not supported (sorry)

	self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];

	CGRect viewRect = self.view.bounds; // View controller's view bounds

	theScrollView = [[UIScrollView alloc] initWithFrame:viewRect]; // All

	theScrollView.scrollsToTop = NO;
	theScrollView.pagingEnabled = YES;
	theScrollView.delaysContentTouches = NO;
	theScrollView.showsVerticalScrollIndicator = NO;
	theScrollView.showsHorizontalScrollIndicator = NO;
	theScrollView.contentMode = UIViewContentModeRedraw;
	theScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	theScrollView.backgroundColor = [UIColor clearColor];
	theScrollView.userInteractionEnabled = YES;
	theScrollView.autoresizesSubviews = NO;
	theScrollView.delegate = self;
   

	[self.view addSubview:theScrollView];

	CGRect toolbarRect = viewRect;
	toolbarRect.size.height = TOOLBAR_HEIGHT;

	mainToolbar = [[ReaderMainToolbar alloc] initWithFrame:toolbarRect document:document]; // At top

	mainToolbar.delegate = self;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        
        searchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(0, 0,300,44)];
        [searchBar setPlaceholder:@"Type to search"];
        [searchBar setBarStyle:UIBarStyleBlackOpaque
         ];
        [searchBar setTintColor:[UIColor colorWithWhite:0.6f alpha:0.0f]];
        searchBar.delegate=self;
        
    }else{
//        searchBar=[[UISearchBar alloc]initWithFrame:CGRectMake(115, 0,155,44)];
//        [searchBar setPlaceholder:@"Type to search"];
//        [searchBar setBarStyle:UIBarStyleBlackOpaque];
//        [searchBar setTintColor:[UIColor colorWithWhite:0.6f alpha:0.0f]];
//        [searchBar setBackgroundImage:[UIImage imageNamed:@""]];
//        searchBar.delegate=self;
//        [mainToolbar addSubview:searchBar];
    }
    
    UIImage *markImageN = [[UIImage imageNamed:@"Black_Search.png"] retain];
    
    UIImage *imageH = [UIImage imageNamed:@"Reader-Button-H.png"];
    UIImage *imageN = [UIImage imageNamed:@"Reader-Button-N.png"];
    
    UIImage *buttonH = [imageH stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    UIImage *buttonN = [imageN stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    
    
    
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    if (gCurrentOrientation==UIInterfaceOrientationPortrait) {
        searchButton.frame = CGRectMake(570, BUTTON_Y, 44, BUTTON_HEIGHT);
    }else if(gCurrentOrientation==UIInterfaceOrientationPortraitUpsideDown){
       searchButton.frame = CGRectMake(570, BUTTON_Y, 44, BUTTON_HEIGHT); 
    }else if(gCurrentOrientation==UIInterfaceOrientationLandscapeLeft){
        searchButton.frame = CGRectMake(550, BUTTON_Y, 44, BUTTON_HEIGHT);
        
    }else if(gCurrentOrientation==UIInterfaceOrientationLandscapeRight){
        searchButton.frame = CGRectMake(550, BUTTON_Y, 44, BUTTON_HEIGHT);
    }
    
    [searchButton setImage:markImageN forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [searchButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
    [searchButton setBackgroundImage:buttonN forState:UIControlStateNormal];
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    [mainToolbar addSubview:searchButton];
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    doneButton.frame = CGRectMake(120, 8.0, 80, 32);
    [doneButton setTitle:NSLocalizedString(@"view", @"button") forState:UIControlStateNormal];
    [doneButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:1.0f] forState:UIControlStateNormal];
    [doneButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateHighlighted];
    [doneButton addTarget:self action:@selector(viewButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [doneButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
    [doneButton setBackgroundImage:buttonN forState:UIControlStateNormal];
    doneButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
    doneButton.autoresizingMask = UIViewAutoresizingNone;
    
    [mainToolbar addSubview:doneButton];

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"isScroll"]) {
         doneButton.selected=YES;
        UISwipeGestureRecognizer *swipeLeftRecognizerLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        swipeLeftRecognizerLeft.direction=UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:swipeLeftRecognizerLeft];
        
        UISwipeGestureRecognizer *swipeLeftRecognizerRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        swipeLeftRecognizerRight.direction=UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:swipeLeftRecognizerRight];
        [doneButton setTitleColor:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:255/255.0 alpha:1.0f] forState:UIControlStateNormal];
        theScrollView.scrollEnabled=NO;
        [doneButton setTitle:NSLocalizedString(@"PageCurl", @"button") forState:UIControlStateNormal];
    }else{
         doneButton.selected=NO;
        for (UIGestureRecognizer *recView in [self.view gestureRecognizers]) {
            if ([recView isKindOfClass:[UISwipeGestureRecognizer class]]) {
                [self.view removeGestureRecognizer:recView];
            }
            
        }
        theScrollView.scrollEnabled=YES;
        [doneButton setTitle:NSLocalizedString(@"PageScroll", @"button") forState:UIControlStateNormal];
    }
    

	[self.view addSubview:mainToolbar];

	CGRect pagebarRect = viewRect;
	pagebarRect.size.height = PAGEBAR_HEIGHT;
	pagebarRect.origin.y = (viewRect.size.height - PAGEBAR_HEIGHT);

	mainPagebar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect document:document]; // At bottom

	mainPagebar.delegate = self;

	[self.view addSubview:mainPagebar];

	UITapGestureRecognizer *singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
	singleTapOne.numberOfTouchesRequired = 1; singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;

	UITapGestureRecognizer *doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;

	UITapGestureRecognizer *doubleTapTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapTwo.numberOfTouchesRequired = 2; doubleTapTwo.numberOfTapsRequired = 2; doubleTapTwo.delegate = self;

	[singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail

	[self.view addGestureRecognizer:singleTapOne]; [singleTapOne release];
	[self.view addGestureRecognizer:doubleTapOne]; [doubleTapOne release];
	[self.view addGestureRecognizer:doubleTapTwo]; [doubleTapTwo release];

	contentViews = [NSMutableDictionary new]; lastHideTime = [NSDate new];
}

- (IBAction)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    NSInteger page = [document.pageNumber integerValue];
    NSInteger maxPage = [document.pageCount integerValue];
    NSInteger minPage = 1; // Minimum
   CGPoint location = [recognizer locationInView:self.view];
  // [self showImageWithText:@"swipe" atPoint:location];
   
   if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
       location.x -= 220.0;
       NSLog(@"Swip Left");
       
       if ((maxPage > minPage) && (page != maxPage))
       {
           [self TurnPageRight];
       }
       
      
   }
   else {
       location.x += 220.0;
       NSLog(@"Swip Right");
       
       if ((maxPage > minPage) && (page != minPage))
       {
           [self TurnPageLeft];
       }
            
   }
}
-(void)TurnPageLeft{
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:0.5f];
    
    if (gCurrentOrientation==UIInterfaceOrientationPortrait) {
        [transition setSubtype:@"fromRight"];
        [transition setType:@"pageUnCurl"];
        [self.view.layer addAnimation:transition forKey:@"UnCurlAnim"]; 
    }else if(gCurrentOrientation==UIInterfaceOrientationPortraitUpsideDown){
        
        
        [transition setSubtype:@"fromLeft"];
        [transition setType:@"pageUnCurl"];
        [self.view.layer addAnimation:transition forKey:@"UnCurlAnim"]; 
    }else if(gCurrentOrientation==UIInterfaceOrientationLandscapeLeft){
        [transition setSubtype:@"fromBottom"];
        [transition setType:@"pageCurl"];
        [self.view.layer addAnimation:transition forKey:@"CurlAnim"]; 
    }else if(gCurrentOrientation==UIInterfaceOrientationLandscapeRight){
        [transition setSubtype:@"fromBottom"];
        [transition setType:@"pageUnCurl"];
        [self.view.layer addAnimation:transition forKey:@"UnCurlAnim"]; 
    }
    
    [self showDocumentPage:currentPage-1];
    
}
-(void)TurnPageRight{
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:0.5f];
    
    if (gCurrentOrientation==UIInterfaceOrientationPortrait) {
        [transition setSubtype:@"fromRight"];
        [transition setType:@"pageCurl"];
        [self.view.layer addAnimation:transition forKey:@"CurlAnim"];
    }else if(gCurrentOrientation==UIInterfaceOrientationPortraitUpsideDown){
        [transition setSubtype:@"fromLeft"];
        [transition setType:@"pageCurl"];
        [self.view.layer addAnimation:transition forKey:@"CurlAnim"];
    }else if(gCurrentOrientation==UIInterfaceOrientationLandscapeLeft){
        [transition setSubtype:@"fromBottom"];
        [transition setType:@"pageUnCurl"];
        [self.view.layer addAnimation:transition forKey:@"UnCurlAnim"]; 
    }else if(gCurrentOrientation==UIInterfaceOrientationLandscapeRight){
        [transition setSubtype:@"fromBottom"];
        [transition setType:@"pageCurl"];
        [self.view.layer addAnimation:transition forKey:@"CurlAnim"]; 
    }
    
    [self showDocumentPage:currentPage+1]; 
}

-(IBAction)viewButtonTapped:(id)sender{
    UIButton *btnView=(UIButton*)sender;
    if ([btnView isSelected]) {
        btnView.selected=NO;
        theScrollView.scrollEnabled=YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isScroll"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        for (UIGestureRecognizer *recView in [self.view gestureRecognizers]) {
            if ([recView isKindOfClass:[UISwipeGestureRecognizer class]]) {
                [self.view removeGestureRecognizer:recView];
            }
        }
        
        [btnView setTitleColor:[UIColor colorWithWhite:0.0f alpha:1.0f] forState:UIControlStateNormal];
        [btnView setTitle:NSLocalizedString(@"PageScroll", @"button") forState:UIControlStateNormal];
    }else{
        btnView.selected=YES;
        theScrollView.scrollEnabled=NO;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isScroll"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        UISwipeGestureRecognizer *swipeLeftRecognizerLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        swipeLeftRecognizerLeft.direction=UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:swipeLeftRecognizerLeft];
        
        UISwipeGestureRecognizer *swipeLeftRecognizerRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        swipeLeftRecognizerRight.direction=UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:swipeLeftRecognizerRight];
        [btnView setTitleColor:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:255/255.0 alpha:1.0f] forState:UIControlStateNormal];
        [btnView setTitle:NSLocalizedString(@"PageCurl", @"button") forState:UIControlStateNormal];
        
    }
    
}


-(IBAction)searchButtonTapped:(id)sender{
    //if (![sender isSelected]) {

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        ObjVC=[[UIViewController alloc] init];//WithNibName:@"SearchPopVC" bundle:nil];
        ObjVC.view.frame=CGRectMake(0, 0, 300, 44);
        ObjVC.view.backgroundColor=[UIColor whiteColor];
//        UIButton *btn=[UIButton buttonWithType:UIButtonTypeRoundedRect];
//        btn.frame=CGRectMake(0, 0, 300, 44);
//        [btn setTitle:@"tast" forState:UIControlStateNormal];
//        [ObjVC.view addSubview:btn];
        NSString *str;
        if (searchBar) {
            str=[searchBar text];
            if ([str length]>0 && [arrSearchPagesIndex count]>0) {
                [ObjVC setContentSizeForViewInPopover:CGSizeMake(300, 344)];
            }else{
               [ObjVC setContentSizeForViewInPopover:CGSizeMake(300, 44)]; 
            }
            
        }else{
            [ObjVC setContentSizeForViewInPopover:CGSizeMake(300, 44)];
        }
//        searchBarVC=[[UISearchDisplayController alloc]initWithSearchBar:searchBar contentsController:ObjVC];
//        [searchBarVC setActive:YES];
        searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
        [ObjVC.view addSubview:searchBar];
        [searchBar setText:str];
        searchBar.delegate=self;
        [searchBar setPlaceholder:@"Type to search"];
        
        searchPopVC=[[UIPopoverController alloc]initWithContentViewController:ObjVC];
        [searchPopVC presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        tblSearchResult =[[UITableView alloc] initWithFrame:CGRectMake(0, 44, 300, 300)];
        tblSearchResult.delegate=self;
        tblSearchResult.dataSource=self;
        [ObjVC.view addSubview:tblSearchResult];
        
        
    }
       
    [sender setSelected:YES];
    [searchBar becomeFirstResponder];
    
    
}
                                                   
- (void)viewWillAppear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewWillAppear:animated];

	if (CGSizeEqualToSize(lastAppearSize, CGSizeZero) == false)
	{
		if (CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) == false)
		{
			[self updateScrollViewContentViews]; // Update content views
		}

		lastAppearSize = CGSizeZero; // Reset view size tracking
	}
}

- (void)viewDidAppear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewDidAppear:animated];

	if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero)) // First time
	{
		[self performSelector:@selector(showDocument:) withObject:nil afterDelay:0.02];
	}

#if (READER_DISABLE_IDLE == TRUE) // Option

	[UIApplication sharedApplication].idleTimerDisabled = YES;

#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewWillDisappear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewWillDisappear:animated];

	lastAppearSize = self.view.bounds.size; // Track view size

#if (READER_DISABLE_IDLE == TRUE) // Option

	[UIApplication sharedApplication].idleTimerDisabled = NO;

#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewDidDisappear:(BOOL)animated
{
#ifdef DEBUGX
	NSLog(@"%s %@", __FUNCTION__, NSStringFromCGRect(self.view.bounds));
#endif

	[super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[mainToolbar release], mainToolbar = nil; [mainPagebar release], mainPagebar = nil;

	[theScrollView release], theScrollView = nil; [contentViews release], contentViews = nil;

	[lastHideTime release], lastHideTime = nil; lastAppearSize = CGSizeZero; currentPage = 0;

	[super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
#ifdef DEBUGX
	NSLog(@"%s (%d)", __FUNCTION__, interfaceOrientation);
#endif
    gCurrentOrientation=interfaceOrientation;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            //searchBar.frame=CGRectMake(700, 0,200,44);
        }else{
            //searchBar.frame=CGRectMake(475, 0,200,44);
        }
    }
    if (!OrientationLock) {
        return YES;
    }else{
        return NO;
    }
	
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUGX
	NSLog(@"%s %@ (%d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), toInterfaceOrientation);
#endif

	if (isVisible == NO) return; // iOS present modal bodge

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
#ifdef DEBUGX
	NSLog(@"%s %@ (%d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), interfaceOrientation);
#endif

	if (isVisible == NO) return; // iOS present modal bodge

	[self updateScrollViewContentViews]; // Update content views

	lastAppearSize = CGSizeZero; // Reset view size tracking
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
#ifdef DEBUGX
	NSLog(@"%s %@ (%d to %d)", __FUNCTION__, NSStringFromCGRect(self.view.bounds), fromInterfaceOrientation, self.interfaceOrientation);
#endif

	//if (isVisible == NO) return; // iOS present modal bodge

	//if (fromInterfaceOrientation == self.interfaceOrientation) return;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[super didReceiveMemoryWarning];
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[mainToolbar release], mainToolbar = nil; [mainPagebar release], mainPagebar = nil;

	[theScrollView release], theScrollView = nil; [contentViews release], contentViews = nil;

	[lastHideTime release], lastHideTime = nil; [document release], document = nil;

	[super dealloc];
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	__block NSInteger page = 0;

	CGFloat contentOffsetX = scrollView.contentOffset.x;

	[contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
		^(id key, id object, BOOL *stop)
		{
			ReaderContentView *contentView = object;

			if (contentView.frame.origin.x == contentOffsetX)
			{
				page = contentView.tag; *stop = YES;
			}
		}
	];

	if (page != 0) [self showDocumentPage:page]; // Show the page
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:theScrollView.tag]; // Show page

	theScrollView.tag = 0; // Clear page number tag
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ([touch.view isKindOfClass:[UIScrollView class]]) return YES;

	return NO;
}

#pragma mark UIGestureRecognizer action methods

- (void)decrementPageNumber
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [document.pageNumber integerValue];
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != minPage))
		{
			CGPoint contentOffset = theScrollView.contentOffset;

			contentOffset.x -= theScrollView.bounds.size.width; // -= 1

			[theScrollView setContentOffset:contentOffset animated:YES];

			theScrollView.tag = (page - 1); // Decrement page number
		}
	}
}

- (void)incrementPageNumber
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (theScrollView.tag == 0) // Scroll view did end
	{
		NSInteger page = [document.pageNumber integerValue];
		NSInteger maxPage = [document.pageCount integerValue];
		NSInteger minPage = 1; // Minimum

		if ((maxPage > minPage) && (page != maxPage))
		{
			CGPoint contentOffset = theScrollView.contentOffset;

			contentOffset.x += theScrollView.bounds.size.width; // += 1

			[theScrollView setContentOffset:contentOffset animated:YES];

			theScrollView.tag = (page + 1); // Increment page number
		}
	}
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect areaRect = CGRectInset(viewRect, TAP_AREA_SIZE, 0.0f); // Area

		if (CGRectContainsPoint(areaRect, point)) // Single tap is inside the area
		{
			NSInteger page = [document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			ReaderContentView *targetView = [contentViews objectForKey:key];

			id target = [targetView singleTap:recognizer]; // Process tap

			if (target != nil) // Handle the returned target object
			{
				if ([target isKindOfClass:[NSURL class]]) // Open a URL
				{
					[[UIApplication sharedApplication] openURL:target];
				}
				else // Not a URL, so check for other possible object type
				{
					if ([target isKindOfClass:[NSNumber class]]) // Goto page
					{
						NSInteger value = [target integerValue]; // Number

						[self showDocumentPage:value]; // Show the page
					}
				}
			}
			else // Nothing active tapped in the target content view
			{
				if ([lastHideTime timeIntervalSinceNow] < -0.75) // Delay since hide
				{
					if ((mainToolbar.hidden == YES) || (mainPagebar.hidden == YES))
					{
						[mainToolbar showToolbar]; [mainPagebar showPagebar]; // Show
					}
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (recognizer.state == UIGestureRecognizerStateRecognized)
	{
		CGRect viewRect = recognizer.view.bounds; // View bounds

		CGPoint point = [recognizer locationInView:recognizer.view];

		CGRect zoomArea = CGRectInset(viewRect, TAP_AREA_SIZE, TAP_AREA_SIZE);

		if (CGRectContainsPoint(zoomArea, point)) // Double tap is in the zoom area
		{
			NSInteger page = [document.pageNumber integerValue]; // Current page #

			NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key

			ReaderContentView *targetView = [contentViews objectForKey:key];

			switch (recognizer.numberOfTouchesRequired) // Touches count
			{
				case 1: // One finger double tap: zoom ++
				{
					[targetView zoomIncrement]; break;
				}

				case 2: // Two finger double tap: zoom --
				{
					[targetView zoomDecrement]; break;
				}
			}

			return;
		}

		CGRect nextPageRect = viewRect;
		nextPageRect.size.width = TAP_AREA_SIZE;
		nextPageRect.origin.x = (viewRect.size.width - TAP_AREA_SIZE);

		if (CGRectContainsPoint(nextPageRect, point)) // page++ area
		{
			[self incrementPageNumber]; return;
		}

		CGRect prevPageRect = viewRect;
		prevPageRect.size.width = TAP_AREA_SIZE;

		if (CGRectContainsPoint(prevPageRect, point)) // page-- area
		{
			[self decrementPageNumber]; return;
		}
	}
}

#pragma mark ReaderContentViewDelegate methods

- (void)contentView:(ReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((mainToolbar.hidden == NO) || (mainPagebar.hidden == NO))
	{
		if (touches.count == 1) // Single touches only
		{
			UITouch *touch = [touches anyObject]; // Touch info

			CGPoint point = [touch locationInView:self.view]; // Touch location

			CGRect areaRect = CGRectInset(self.view.bounds, TAP_AREA_SIZE, TAP_AREA_SIZE);

			if (CGRectContainsPoint(areaRect, point) == false) return;
		}

		[mainToolbar hideToolbar]; [mainPagebar hidePagebar]; // Hide

		[lastHideTime release]; lastHideTime = [NSDate new];
	}
}

#pragma mark ReaderMainToolbarDelegate methods

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar doneButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

#if (READER_STANDALONE == FALSE) // Option

	[document saveReaderDocument]; // Save any ReaderDocument object changes

	[[ReaderThumbQueue sharedInstance] cancelOperationsWithGUID:document.guid];

	[[ReaderThumbCache sharedInstance] removeAllObjects]; // Empty the thumb cache

	if (printInteraction != nil) [printInteraction dismissAnimated:NO]; // Dismiss

	if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
	{
		[delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
	}
	else // We have a "Delegate must respond to -dismissReaderViewController: error"
	{
		NSAssert(NO, @"Delegate must respond to -dismissReaderViewController:");
	}

#endif // end of READER_STANDALONE Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar thumbsButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (printInteraction != nil) [printInteraction dismissAnimated:NO]; // Dismiss

	ThumbsViewController *thumbsViewController = [[ThumbsViewController alloc] initWithReaderDocument:document];

	thumbsViewController.delegate = self; thumbsViewController.title = self.title;

	thumbsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	thumbsViewController.modalPresentationStyle = UIModalPresentationFullScreen;

	[self presentModalViewController:thumbsViewController animated:NO];

	[thumbsViewController release]; // Release ThumbsViewController
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar printButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

#if (READER_ENABLE_PRINT == TRUE) // Option

	Class printInteractionController = NSClassFromString(@"UIPrintInteractionController");

	if ((printInteractionController != nil) && [printInteractionController isPrintingAvailable])
	{
		NSURL *fileURL = document.fileURL; // Document file URL

		printInteraction = [printInteractionController sharedPrintController];

		if ([printInteractionController canPrintURL:fileURL] == YES) // Check first
		{
			UIPrintInfo *printInfo = [NSClassFromString(@"UIPrintInfo") printInfo];

			printInfo.duplex = UIPrintInfoDuplexLongEdge;
			printInfo.outputType = UIPrintInfoOutputGeneral;
			printInfo.jobName = document.fileName;

			printInteraction.printInfo = printInfo;
			printInteraction.printingItem = fileURL;
			printInteraction.showsPageRange = YES;

			if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
			{
				[printInteraction presentFromRect:button.bounds inView:button animated:YES completionHandler:
					^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
					{
						#ifdef DEBUG
							if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
						#endif
					}
				];
			}
			else // Presume UIUserInterfaceIdiomPhone
			{
				[printInteraction presentAnimated:YES completionHandler:
					^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
					{
						#ifdef DEBUG
							if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
						#endif
					}
				];
			}
		}
	}

#endif // end of READER_ENABLE_PRINT Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar emailButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

#if (READER_ENABLE_MAIL == TRUE) // Option

	if ([MFMailComposeViewController canSendMail] == NO) return;

	if (printInteraction != nil) [printInteraction dismissAnimated:YES];

	unsigned long long fileSize = [document.fileSize unsignedLongLongValue];

	if (fileSize < (unsigned long long)15728640) // Check attachment size limit (15MB)
	{
		NSURL *fileURL = document.fileURL; NSString *fileName = document.fileName; // Document

		NSData *attachment = [NSData dataWithContentsOfURL:fileURL options:(NSDataReadingMapped|NSDataReadingUncached) error:nil];

		if (attachment != nil) // Ensure that we have valid document file attachment data
		{
			MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];

			[mailComposer addAttachmentData:attachment mimeType:@"application/pdf" fileName:fileName];

			[mailComposer setSubject:fileName]; // Use the document file name for the subject

			mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
			mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;

			mailComposer.mailComposeDelegate = self; // Set the delegate

			[self presentModalViewController:mailComposer animated:YES];

			[mailComposer release]; // Cleanup
		}
	}

#endif // end of READER_ENABLE_MAIL Option
}

- (void)tappedInToolbar:(ReaderMainToolbar *)toolbar markButton:(UIButton *)button
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (printInteraction != nil) [printInteraction dismissAnimated:YES];

	NSInteger page = [document.pageNumber integerValue];

	if ([document.bookmarks containsIndex:page])
	{
		[mainToolbar setBookmarkState:NO];

		[document.bookmarks removeIndex:page];
	}
	else // Add the bookmarked page index
	{
		[mainToolbar setBookmarkState:YES];

		[document.bookmarks addIndex:page];
	}
}

#pragma mark MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	#ifdef DEBUG
		if ((result == MFMailComposeResultFailed) && (error != NULL)) NSLog(@"%@", error);
	#endif

	[self dismissModalViewControllerAnimated:YES]; // Dismiss
}

#pragma mark ThumbsViewControllerDelegate methods

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self updateToolbarBookmarkIcon]; // Update bookmark icon

	[self dismissModalViewControllerAnimated:NO]; // Dismiss
}

- (void)thumbsViewController:(ThumbsViewController *)viewController gotoPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:page]; // Show the page
}

#pragma mark ReaderMainPagebarDelegate methods

- (void)pagebar:(ReaderMainPagebar *)pagebar gotoPage:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[self showDocumentPage:page]; // Show the page
}

#pragma mark UIApplication notification methods

- (void)applicationWill:(NSNotification *)notification
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[document saveReaderDocument]; // Save any ReaderDocument object changes

	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
	{
		if (printInteraction != nil) [printInteraction dismissAnimated:NO];
	}
}
-(void)searchBarTextDidEndEditing:(UISearchBar *)aSearchBar
{
    if([keyWord isEqualToString:[[aSearchBar text] retain]] )
    {
        [aSearchBar resignFirstResponder];
        return;
    }
    
    if([keyWord isEqualToString:@""] && [[aSearchBar text] isEqualToString:@""])
    {
        [aSearchBar resignFirstResponder];
        return;
    }else{
        //[alertmessage ShowAlertWithTitle:@"Searching  Please Wait ....\n\n"];
        [ObjVC setContentSizeForViewInPopover:CGSizeMake(300, 344)];
        arrSearchPagesIndex=[[NSMutableArray alloc]init];
        [tblSearchResult reloadData];

        [self performSelectorInBackground:@selector(SerchDataFromPDF) withObject:nil];
        //[self performSelector:@selector(SerchDataFromPDF) withObject:nil afterDelay:0.01];
//        [searchPopVC dismissPopoverAnimated:YES];
//        [self performSelector:@selector(SerchDataFromPDF) withObject:nil afterDelay:0.0];
    }
   
}
-(void)SerchDataFromPDF{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    keyWord = [[searchBar text] retain];
    int lastPage=currentPage;
    currentPage=currentPage-1;
    Searching=YES;
    //[searchPopVC dismissPopoverAnimated:YES];
    [self showDocumentPage:lastPage];
    [self GetListOfSearchPage];
    [pool release];
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    
    
    return YES;
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)aSearchBar
{
    //	[keyword release];
    // Show the page
    //	[pageView setKeyword:keyword];
	
	[aSearchBar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [arrSearchPagesIndex count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell=[[UITableViewCell alloc]init];
    cell.textLabel.text=[[arrSearchPagesIndex objectAtIndex:indexPath.row] valueForKey:@"PageTitle"];
    if ([[[arrSearchPagesIndex objectAtIndex:indexPath.row] valueForKey:@"PageTitle"] isEqualToString:@"No Result"]) {
        cell.userInteractionEnabled=NO;
    }else{
        cell.userInteractionEnabled=YES;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showDocumentPage:[[[arrSearchPagesIndex objectAtIndex:indexPath.row] valueForKey:@"PageNo"] integerValue]];
    [searchPopVC dismissPopoverAnimated:YES];
}

-(void)GetListOfSearchPage{
    OrientationLock=TRUE;
    
//    NSLog(@"%@ %@",document.fileURL,document.password);

        PDFDocRef = CGPDFDocumentCreateX((CFURLRef)document.fileURL,document.password);
    float pages = CGPDFDocumentGetNumberOfPages(PDFDocRef);
    for (i=0; i<pages; i++) {
        PDFPageRef = CGPDFDocumentGetPage(PDFDocRef,i+1); // Get page
        if ([[self selections] count]>0) {
            [arrSearchPagesIndex addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"Page %d (%d Times)",i+1,[[self selections] count]],@"PageTitle",[NSString stringWithFormat:@"%d",i+1],@"PageNo",nil]]; 
            [self performSelectorOnMainThread:@selector(RefereshTableOnMainThred) withObject:nil waitUntilDone:NO];
        }
        [self performSelectorOnMainThread:@selector(PerFormONMainThresd:) withObject:[NSString stringWithFormat:@"%f",(i+1/pages)/pages] waitUntilDone:NO];
        CGPDFPageRelease(PDFPageRef);
        selections=nil;
    }
   //[alertmessage hideAlert];
     OrientationLock=FALSE;
    if ([arrSearchPagesIndex count]==0) {
         [arrSearchPagesIndex addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"No Result",@"PageTitle",@"-1",@"PageNo",nil]];
        
    }
    
}
-(void)RefereshTableOnMainThred{
    NSIndexPath *path1 = [NSIndexPath indexPathForRow:[arrSearchPagesIndex count]-1 inSection:0];
    NSArray *indexArray = [NSArray arrayWithObjects:path1,nil];
    [tblSearchResult insertRowsAtIndexPaths:indexArray withRowAnimation:UITableViewRowAnimationTop];
}
-(void)PerFormONMainThresd:(NSString*)UpdateProgress{
    [alertmessage updateProcess:[UpdateProgress floatValue]];
}


- (NSArray *)selections
{
	@synchronized (self)
	{
            scanner = [[Scanner alloc] init];
			[self.scanner setKeyword:keyWord];
            [self.scanner scanPage:PDFPageRef];
			self.selections = [self.scanner selections];
            return selections;
	}
}

@end
