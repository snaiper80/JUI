//
//  TSViewController.m
//  JUIExample
//
//  Created by snaiper on 5/24/12.
//  Copyright (c) 2012 snaiper All rights reserved.
//

#import "TSViewController.h"
#import "JUIFactory.h"

@interface TSViewController ()

@end

@implementation TSViewController {
@private
    JUIFactory *mParser;
    UIScrollView      *mParentView;
    NSArray           *mExamplePages;
}

@synthesize pageControl = mPageControl;

- (UIView *)loadDataFromFileName:(NSString *)aFileName
{
    mParser  = [[JUIFactory alloc] init];
    BOOL sRet = [mParser load:[[NSBundle mainBundle] pathForResource:aFileName ofType:@"json"]];
    if (sRet == NO)
    {
        UIAlertView *sAlertView = [[UIAlertView alloc] initWithTitle:nil 
                                                             message:@"Parse Error"
                                                            delegate:nil 
                                                   cancelButtonTitle:nil 
                                                   otherButtonTitles:@"OK", nil];
        [sAlertView show];
        return nil;
    }
    else
    {
        return [mParser view];
    }
}

- (void)loadExamples
{
    mExamplePages = [[NSArray alloc] initWithObjects:@"login", @"remote", nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self loadExamples];
    
    UIScrollView *sScrollView = [[UIScrollView alloc] initWithFrame:[self.view bounds]];
    [sScrollView setContentSize:CGSizeMake([self.view bounds].size.width * [mExamplePages count], [self.view bounds].size.height)];
    [sScrollView setShowsVerticalScrollIndicator:NO];
    [sScrollView setShowsHorizontalScrollIndicator:YES];
    [sScrollView setAlwaysBounceVertical:NO];             
    [sScrollView setAlwaysBounceHorizontal:NO];         
    [sScrollView setPagingEnabled:YES];         
    [sScrollView setDelegate:self];
    
    [mPageControl setCurrentPage:0];              
    [mPageControl setNumberOfPages:[mExamplePages count]];          
    [mPageControl addTarget:self action:@selector(pageChangeValue:) forControlEvents:UIControlEventValueChanged]; 
    
    mParentView = sScrollView;
    
    int sCount = 0;
    for (NSString *sExampleFileName in mExamplePages)
    {
        UIView *sView   = [self loadDataFromFileName:sExampleFileName];
        
        CGRect  sFrame  = [sView frame];
        sFrame.origin.x = sCount * [self.view bounds].size.width;
        [sView setFrame:sFrame];
        
        [mParentView addSubview:sView];
        
        sCount++;
    }
    
    [self.view addSubview:mParentView];
    [self.view bringSubviewToFront:mPageControl];
}

- (void)viewDidUnload
{
    [self setPageControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)pageChangeValue:(id)sender 
{
    UIPageControl *pControl = (UIPageControl *) sender;
    [mParentView setContentOffset:CGPointMake(pControl.currentPage * [self.view bounds].size.width, 0) animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender 
{  
    CGFloat sPageWidth = mParentView.frame.size.width;  
    [mPageControl setCurrentPage:floor((mParentView.contentOffset.x - sPageWidth / [mExamplePages count]) / sPageWidth) + 1];  
}

@end
