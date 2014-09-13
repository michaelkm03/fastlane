//
//  VWebContentViewController.m
//  victorious
//
//  Recreated by Lawrence H. Leach on 08/13/14.
//  Copyright (c) 2014 Victorious. All rights reserved.
//

#import "VWebContentViewController.h"
#import "VThemeManager.h"

@interface VWebContentViewController ()

@property (nonatomic, weak, readwrite) IBOutlet UIWebView* webView;
@property (nonatomic, strong, readwrite) UIActivityIndicatorView *activitiyIndicator;

@end

@implementation VWebContentViewController

#pragma mark - Factory Methods

+ (instancetype)webContentViewController
{
    VWebContentViewController *webviewVC = [[self alloc] initWithNibName:@"webContentView" bundle:nil];
    return webviewVC;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.activitiyIndicator)
    {
        self.activitiyIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activitiyIndicator.center = self.view.center;
        [self.view addSubview:self.activitiyIndicator];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.translucent = NO;
    
    [[VThemeManager sharedThemeManager] applyNormalNavBarStyling];
    
    self.webView.delegate = self;
    
    if (self.urlToView)
    {
        NSURLRequest *requestWithURL = [NSURLRequest requestWithURL:self.urlToView];
        [self.webView loadRequest:requestWithURL];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.webView stopLoading];
    
    self.webView.delegate = nil;    // disconnect the delegate as the webview is hidden
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.activitiyIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activitiyIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.activitiyIndicator stopAnimating];
    
    // report the error inside the webview
    NSString* errorString = @"<html><center><font size=+5 color='red'>Failed To Load Page</font></center></html>";
    [self.webView loadHTMLString:errorString baseURL:nil];
}

@end

