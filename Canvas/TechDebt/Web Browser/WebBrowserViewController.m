//
// Copyright (C) 2016-present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
    
    

#import <CanvasKit1/CanvasKit1.h>
#import "UIViewController+AnalyticsTracking.h"
#import <CanvasKit1/CKActionSheetWithBlocks.h>

#import "WebBrowserViewController.h"

#import "UIWebView+SafeAPIURL.h"
#import "RatingsController.h"
@import SoPretty;
#import "iCanvasConstants.h"
#import "Analytics.h"
@import CanvasKit;

@interface WebBrowserViewController() <UIWebViewDelegate, UIDocumentInteractionControllerDelegate, UITextFieldDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate> {
    __weak IBOutlet UINavigationBar *topToolbar;
    __weak IBOutlet UIToolbar *bottomToolbar;
    __weak IBOutlet UIBarButtonItem *doneButton;
    __weak IBOutlet UIBarButtonItem *backButton;
    __weak IBOutlet UIBarButtonItem *forwardButton;
    __weak IBOutlet UIBarButtonItem *refreshButton;
    __weak IBOutlet UIBarButtonItem *actionButton;
    __strong IBOutlet UIBarButtonItem *stopButton;
    NSUInteger networkOps;
    NSArray *reloadBarItems;
    NSArray *stopBarItems;
    CKActionSheetWithBlocks *optionsActionSheet;
    CKActionSheetWithBlocks *openInErrorSheet;
    UIDocumentInteractionController *dic;
}

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSString *mime;
@property (nonatomic, strong) NSURL *fileURLPath;
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (nonatomic, strong) NSString *fullURL;
@property (nonatomic, strong) NSString *hostURL;
@property (nonatomic, assign) BOOL isTitleAbreviated;
@property (nonatomic, assign) BOOL isAnimatingTitle;

@end


@implementation WebBrowserViewController

- (instancetype)initWithURL:(NSURL *)url
{
    UINavigationController *nav = (UINavigationController *)[[UIStoryboard storyboardWithName:@"Storyboard-WebBrowser" bundle:[NSBundle bundleForClass:[self class]]] instantiateInitialViewController];
    self = nav.viewControllers[0];
    [self setUrl:url];
    return self;
}

- (void)dealloc {
    _webView.delegate = nil;
    dic.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.fileURLPath) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:self.fileURLPath error:&error];
        if (error) {
            NSLog(@"Could not remove the file at that location: %@", self.fileURLPath);
        }
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    doneButton.title = NSLocalizedString(@"Close", @"Close the window");
    topToolbar.topItem.title = @"";
    
    // Set up our two states of buttons for the bottom toolbar.
    // The first one is just a copy of what is laid out in the xib
    // The second one swaps out the Refresh button for a Stop button
    reloadBarItems = bottomToolbar.items;
    NSMutableArray *tempButtons = [NSMutableArray new];
    for (UIBarButtonItem *item in reloadBarItems) {
        if (item == refreshButton) {
            if (! stopButton) {
                stopButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop",@"Stop loading button for webview") style:UIBarButtonItemStylePlain target:self action:@selector(stopButtonTapped:)];
            }
            [tempButtons addObject:stopButton];
        }
        else {
            [tempButtons addObject:item];
        }
    }
    stopBarItems = tempButtons;
    
    // Set up the error action sheet
    openInErrorSheet = [[CKActionSheetWithBlocks alloc] initWithTitle:NSLocalizedString(@"No installed apps support opening this file", @"Error message")];
    [openInErrorSheet addButtonWithTitle:NSLocalizedString(@"OK", nil)];
    
    if (self.request) {
        [self.request loadRequestInWebView:self.webView];
    }
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.view setBackgroundColor:[UIColor prettyBlack]];
    [self.titleField setTextColor:[UIColor whiteColor]];
    [self.titleField setBackgroundColor:[UIColor clearColor]];
    [self setIsTitleAbreviated:YES];
    [self.titleField setBorderStyle:UITextBorderStyleNone];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(webViewTapped:)];
    [self.webView addGestureRecognizer:tapRecognizer];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(onKeyboardHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self.titleField setTintColor:Brand.current.tintColor];
    [self.webView setScalesPageToFit:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.webView loadHTMLString:@"<body></body>" baseURL:nil];
    [self.request loadRequestInWebView:self.webView];
}

- (void)onKeyboardHide:(NSNotification *)notification
{
    if ( ! self.isTitleAbreviated) {
        [self toggleTitleDisplayState];
    }
}

- (void)webViewTapped:(id)sender
{
    if ( ! self.isTitleAbreviated) {
        [self toggleTitleDisplayState];
        [self.titleField resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.titleField.text]]];
    [self.titleField resignFirstResponder];
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    NSLog(@"TRACKING: %@", kGAIScreenWebBrowser);
    [Analytics logScreenView:kGAIScreenWebBrowser];
}

#pragma mark - Setters

- (void)setUrl:(NSURL *)url {
    _url = url;
    
    if (url) {
        self.request = [NSURLRequest requestWithURL:url];
    
        [self.request loadRequestInWebView:self.webView];
    }
}

- (void)setContentHTML:(NSString *)html baseURL:(NSURL *)baseURL {
    self.request = [StaticHTMLRequest requestWithHTML:html baseURL:baseURL];
}

#pragma mark -
#pragma mark IBAction

- (IBAction)doneButtonTapped:(id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:^{
        // Blank the webview by loading empty HTML
        [_webView loadHTMLString:@"" baseURL:nil];
        [RatingsController appLoadedOnViewController:self];
    }];
    if (self.browserWillDismissBlock) {
        self.browserWillDismissBlock();
    }
}

- (IBAction)backButtonTapped:(id)sender
{
    if ([_webView canGoBack]) {
        networkOps = 0;
        [_webView goBack];
    }
    else {
        NSLog(@"Can't go back in the history.");
    }
}

- (IBAction)forwardButtonTapped:(id)sender
{
    if ([_webView canGoForward]) {
        networkOps = 0;
        [_webView goForward];
    }
    else {
        NSLog(@"Can't go forward in the history.");
    }
}

#pragma mark TextField Delegate


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self toggleTitleDisplayState];
}

- (IBAction)refreshButtonTapped:(id)sender
{
    networkOps = 0;
    if (_webView.request && _webView.request.URL.absoluteString.length && ![_webView.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        [_webView reload];
    } else {
        [self.request loadRequestInWebView:self.webView];
    }
}

- (IBAction)stopButtonTapped:(id)sender
{
    networkOps = 0;
    [_webView stopLoading];
}

- (IBAction)actionButtonTapped:(id)sender
{
    BOOL addedAtLeastOneButton = NO;
    
    if ([optionsActionSheet isVisible]) {
        [optionsActionSheet dismissWithClickedButtonIndex:[optionsActionSheet cancelButtonIndex] animated:NO];
    }
    
    if ([openInErrorSheet isVisible]) {
        [openInErrorSheet dismissWithClickedButtonIndex:[openInErrorSheet cancelButtonIndex] animated:NO];
    }
    
    optionsActionSheet = [[CKActionSheetWithBlocks alloc] initWithTitle:[_webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
    
    // Present an action sheet.
    // 1. Open in Safari
    NSURL *theURL = [NSURL URLWithString:self.fullURL]; // Copy to a local variable to avoid a retain cycle
    if (self.request.canOpenInSafari) {
        [optionsActionSheet addButtonWithTitle:NSLocalizedString(@"Open in Safari", @"Open a document in the application Safari") handler:^{
            [[UIApplication sharedApplication] openURL:theURL];
        }];
        addedAtLeastOneButton = YES;
    }
    
    // 2. Open in another application
    CKActionSheetWithBlocks *localOpenInErrorSheet = openInErrorSheet;
    
    if (self.fileURLPath) {
        dic = [UIDocumentInteractionController interactionControllerWithURL:self.fileURLPath];
        dic.delegate = self;
        __weak UIDocumentInteractionController *weakDic = dic;
        [optionsActionSheet addButtonWithTitle:NSLocalizedString(@"Open in...", @"Open file in another application") handler:^{
            // Dismiss this action sheet and generate an OpenIn DIC display.
            // If there are no apps to handle the URL, display an action sheet that says, "Nothing supports this document". This is required to be in the App Store.
            BOOL presentedOpenInMenu = [weakDic presentOpenInMenuFromBarButtonItem:sender animated:YES];
            
            if (presentedOpenInMenu == NO) {
                [localOpenInErrorSheet showFromBarButtonItem:sender animated:YES];
            }
        }];
        addedAtLeastOneButton = YES;
    }
    
    // 3. Print
    // 4. Make a sandwich
    // 5. Sudo make a sandwich
    // 6. Cancel
    [optionsActionSheet addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil)];;
    
    if (addedAtLeastOneButton == NO) {
        optionsActionSheet.title = NSLocalizedString(@"There are no actions for this item", @"Error message");
    }
    
    [optionsActionSheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark -
#pragma mark UIDocumentInteractionControllerDelegate

- (void) documentInteractionController: (UIDocumentInteractionController *) controller didEndSendingToApplication: (NSString *) application
{
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)theWebView shouldStartLoadWithRequest:(NSURLRequest *)req navigationType:(UIWebViewNavigationType)navigationType
{
    self.fullURL = req.URL.description;
    self.hostURL = req.URL.host.description;
    
    if (self.isTitleAbreviated) {
        [self.titleField setText:self.hostURL];
    } else {
        [self.titleField setText:self.fullURL];
        [self toggleTitleDisplayState];
    }
    
    return YES;
}

- (void)downloadFileAtURL:(NSURL *)url
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryPath = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
        return [documentsDirectoryPath URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        self.fileURLPath = filePath;
    }];
    [downloadTask resume];
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error
{
    // Display an error page on the screen?
    if (networkOps > 0) networkOps--;
    if (networkOps == 0) {
        [self.activityIndicator stopAnimating];
        bottomToolbar.items = reloadBarItems;
        actionButton.enabled = YES;
    }
    
    if (error && [error code] != kCFURLErrorCancelled) {
        
        if ([error code] == 204 && [error userInfo][NSURLErrorFailingURLStringErrorKey]) {
            // Handle Kaltura media
            // 204 is "Plug-in handled load", meaning it was handled outside the webview. Just let it be.
            return;
        } else if ([error code] == 555) {
            NSLog(@"error: %@", error);
            
            //    MBL-5318 - If Penn State return an actual HTTP error code instead of swallowing the error then we can reload the page with the referrer for them - nlambson
            return;
        } else {
            NSString *localizedMessage = NSLocalizedString(@"There was an error loading the document.", @"Web browser error handling message");
            
            NSString *htmlMessage = [NSString stringWithFormat:@"<html><body style=\"font-family:sans-serif;font-size:30px;text-align:center;color:#555;padding:5px;\">%@</body></html>", localizedMessage];
            
            [_webView loadHTMLString:htmlMessage baseURL:nil];
        }
    }
}

- (void)webViewDidStartLoad:(UIWebView *)theWebView
{
    networkOps++;
    
    backButton.enabled = [_webView canGoBack];
    forwardButton.enabled = [_webView canGoForward];
    
    if (networkOps == 1) {
        [self.activityIndicator startAnimating];
        bottomToolbar.items = stopBarItems;
        actionButton.enabled = NO;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    backButton.enabled = [_webView canGoBack];
    [self setFullURL:theWebView.request.URL.description];
    // Show the title of the document.
    if ([theWebView.request.URL isFileURL]) {
        topToolbar.topItem.title = [theWebView.request.URL lastPathComponent];
    }
    else {
        [self.titleField setText:[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
        [self setHostURL:[self.webView stringByEvaluatingJavaScriptFromString:@"document.title"]];
    }
    
    if (networkOps > 0) networkOps--;
    if (networkOps == 0) {
        [self.activityIndicator stopAnimating];
        bottomToolbar.items = reloadBarItems;
        actionButton.enabled = YES;
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        if (self.titleField.text.length) {
            CGSize size = [self.titleField.text sizeWithAttributes:@{NSFontAttributeName: self.titleField.font}];
            [self.titleField setFrame:CGRectMake((self.view.frame.size.width - roundf(size.width)) * 0.5, self.titleField.frame.origin.y, roundf(size.width), self.titleField.frame.size.height)];
        }
    }];
    
    NSString *html = [theWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    if ([html isEqualToString:@"Could not find download URL"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"There was an error loading your content. If it is an audio or video upload it may still be processing.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
        [alert show];
    }
    
    [theWebView replaceHREFsWithAPISafeURLs];
    [self.delegate webBrowser:self didFinishLoadingWebView:theWebView];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // The only alertview shown will be for a 'Could not find download URL' error
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)toggleTitleDisplayState
{
    if (self.isAnimatingTitle) {
        return;
    }
    if (self.isTitleAbreviated) {
        [self setIsAnimatingTitle:YES];
        [self.titleField setText:self.fullURL];
        [self.titleField setBorderStyle:UITextBorderStyleRoundedRect];
        [UIView animateWithDuration:0.3 animations:^{
            [self.titleField setTextColor:[UIColor darkTextColor]];
            [self.titleField setFrame:CGRectMake(0, self.titleField.frame.origin.y, self.view.frame.size.width, self.titleField.frame.size.height)];
            [self.titleField setBackgroundColor:[UIColor whiteColor]];
        } completion:^(BOOL finished) {
            [self setIsAnimatingTitle:NO];
        }];
    } else {
        [self setIsAnimatingTitle:YES];
        [UIView animateWithDuration:0.3 animations:^{
            [self.titleField setText:self.hostURL];
            CGSize size = [self.hostURL sizeWithAttributes:@{NSFontAttributeName: self.titleField.font}];
            [self.titleField setFrame:CGRectMake((self.view.frame.size.width - roundf(size.width)) * 0.5, self.titleField.frame.origin.y, roundf(size.width), self.titleField.frame.size.height)];
            [self.titleField setBackgroundColor:[UIColor clearColor]];
            [self.titleField setTextColor:[UIColor whiteColor]];
        } completion:^(BOOL finished) {
            [self setIsAnimatingTitle:NO];
            [self.titleField setBorderStyle:UITextBorderStyleNone];
        }];
        [self.titleField resignFirstResponder];
    }
    
    [self setIsTitleAbreviated:! self.isTitleAbreviated];
}


@end


@implementation NSURLRequest (WebBrowser)

- (void)loadRequestInWebView:(UIWebView *)webView {
    [webView loadRequest:self];
}

- (BOOL)canOpenInSafari {
    return !self.URL.isFileURL;
}

@end

@interface StaticHTMLRequest ()
@property (nonatomic, nonnull) NSString *html;
@property (nonatomic, nonnull) NSURL *baseURL;
@end

@implementation StaticHTMLRequest

+ (instancetype)requestWithHTML:( NSString * _Nonnull )html baseURL:(NSURL * _Nonnull)baseURL {
    StaticHTMLRequest *req = [self new];
    req.html = html;
    req.baseURL = baseURL;
    return req;
}

- (void)loadRequestInWebView:(UIWebView *)webView {
    [webView loadHTMLString:self.html baseURL:self.baseURL];
}

- (BOOL)canOpenInSafari {
    return NO;
}

@end
