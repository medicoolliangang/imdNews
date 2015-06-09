//
//  rootViewController.m
//  imdNews
//
//  Created by wulg on 3/26/12.
//  Copyright (c) 2012 www.i-md.com. All rights reserved.
//

#import "AppDelegate.h"
#import "rootViewController.h"
#import "Reachability.h"

#import "SHK.h"
#import "SHKSinaWeibo.h"
#import "SHKNetEaseWeibo.h"
#import "SHKTencentWeibo.h"
#import "SHKMail.h"

#import "GANTracker.h"

#import "MKNetworkKit.h"
#import <QuartzCore/QuartzCore.h>

#define APP_ID @"519002672"  //for test 
#define SEARCH_APP_ID @"492028918"

#define API_VER @"1.2.1"

#import <mach/mach.h>

void report_memory(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    
    
    
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in M bytes): %f", info.resident_size/(1024*1024.0f));
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
}

//#define APP_ID 519002672 real id

NSString * const iRateiOSAppStoreURLFormat = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";


@interface rootViewController ()

@end

@implementation rootViewController
@synthesize mainWebView,coverView;
@synthesize entryButton;
@synthesize extraView;
@synthesize coverBackground;
@synthesize extraWebView;
@synthesize ratingsURL;
@synthesize extraTitle;
@synthesize extraLoadingView;
@synthesize loadingView;
@synthesize infoLabel;
@synthesize updateButton;
@synthesize extraInfo;
@synthesize shareStatus;
@synthesize weiBoEngine;

- (void)dealloc
{   
    [extraTitle release];
    [infoLabel release];
    [updateButton release];
    
    [sinaWeibo release];
    [netEaseWeibo release];
    [tencentWeibo release];
    
    [extraView release];
    [entryButton release];
    [mainWebView release];
    [extraInfo release];
    [coverView release];
    [coverBackground release];
    [extraWebView release];
    [extraLoadingView release];
    [loadingView release];
    [shareStatus release];
    
    [weiBoEngine setDelegate:nil];
    [weiBoEngine release];
    weiBoEngine = nil;
    
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //[UIApplication sharedApplication].statusBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    
    sharerKey =@"sharerState";
    
    //for test
    //[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"shareStatus"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    //[SHKSinaWeibo logout];
    //[SHKNetEaseWeibo logout];
    
    orientation =5;
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    readyToEnter =NO;
    stillSavingImage =NO;
    isorientationChanged = NO;
    
    sinaWeibo =[[SHKSinaWeibo alloc] init];
    netEaseWeibo =[[SHKNetEaseWeibo alloc] init];
    tencentWeibo = [[SHKTencentWeibo alloc] init];
    [self checkShareStatus];
    
    WBEngine* engine = [[WBEngine alloc] initWithAppKey:SHKSinaWeiboConsumerKey appSecret:SHKSinaWeiboConsumerSecret];
    [engine setRootViewController:self];
    [engine setDelegate:self];
    [engine setRedirectURI:@"http://www.i-md.com"];
    [engine setIsUserExclusive:NO];
    self.weiBoEngine = engine;
    [engine release];
    
    self.ratingsURL =[NSString stringWithFormat:iRateiOSAppStoreURLFormat,APP_ID];
    
    
    
    for (id subview in self.mainWebView.subviews)
        if ([[subview class] isSubclassOfClass: [UIScrollView class]])
            ((UIScrollView *)subview).bounces = NO;
    
    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
   
    //[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];
    
    
    NSURL *url =[NSURL URLWithString:mainURL];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [mainWebView loadRequest:urlRequest];
    mainWebView.delegate = self;
    
    
    
    [self initSwipe];
	
#ifndef __OPTIMIZE__
    //clear this for standard version
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
#endif
    /*NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
    [sharedCache release];
    sharedCache = nil;*/
    
    
    
    firstLoad =YES;
    
    [self performSelector:@selector(checkAppVer) withObject:nil afterDelay:0.5f];
    

    NSTimer* tm;
    tm = [NSTimer scheduledTimerWithTimeInterval: 0.5
                                         target: self
                                       selector: @selector(timerUpdate)
                                       userInfo: nil
                                        repeats: YES];
    
    
    self.extraWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.extraWebView.scalesPageToFit = YES;
    self.extraWebView.autoresizesSubviews = YES;
    
    
    
    [[self.updateButton layer] setCornerRadius:8.0f];
    [self.updateButton setBackgroundColor:[UIColor blackColor]];
    [self.updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.updateButton.hidden =YES;
    
    
    [[self.extraInfo layer] setCornerRadius:8.0f];
    [self.extraInfo setBackgroundColor:[UIColor darkGrayColor]];
    self.extraInfo.alpha =0.8f;
    [self.extraInfo setTextColor:[UIColor whiteColor]];
    self.extraInfo.hidden =YES;
    
    NSLog(@"view did load");
    [self orientationChanged];
    [self renderOrientation];
     
}




- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    self.extraTitle =nil;
    self.infoLabel =nil;
    self.extraLoadingView =nil;
    self.updateButton =nil;
    
    self.entryButton =nil;
    self.mainWebView =nil;
    self.coverView =nil;
    self.extraView =nil;
    self.coverBackground =nil;
    self.extraWebView =nil;
    self.loadingView =nil;
    self.extraInfo =nil;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{    
    return YES;
}

-(void) willAnimateRotationToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation duration: (NSTimeInterval) duration 
{
    isorientationChanged = YES;
    NSLog(@"will rotate");
    [self orientationChanged];
   [self renderOrientation]; 


}


#pragma mark - orientation changed



-(void)orientationChanged
{
    int o =/*[[UIDevice currentDevice] orientation]*/[[UIApplication sharedApplication] statusBarOrientation];
    
    
    //NSLog(@"detected o == %d",o);
    
    //NSLog(@"detected p == %d %d",UIInterfaceOrientationPortrait,UIInterfaceOrientationPortraitUpsideDown);
    
    //NSLog(@"detected l == %d %d",UIInterfaceOrientationLandscapeLeft,UIInterfaceOrientationLandscapeRight);
    
    
    
    if( o == UIInterfaceOrientationPortrait || o == UIInterfaceOrientationPortraitUpsideDown || o== UIInterfaceOrientationLandscapeLeft || o == UIInterfaceOrientationLandscapeRight)
    { 
        orientation =o;  
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:orientation] forKey:@"orientation"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }    

}

- (void)renderOrientation
{    
    
   // NSLog(@"displaying o == %d",orientation);
    
    if( orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
    {
        //NSLog(@"portrait");
        if(orientation == UIInterfaceOrientationPortrait && !isorientationChanged)
        {
            self.coverView.frame =CGRectMake(0, 20, 768, 1004);
            self.mainWebView.frame = CGRectMake(0, 20, 768, 1004);
            self.extraView.frame =CGRectMake(0, 0, 768, 1024);
        }
        else
        {
            self.coverView.frame =CGRectMake(0, 0, 768, 1004);
            self.mainWebView.frame = CGRectMake(0, 0, 768, 1004);
            self.extraView.frame =CGRectMake(0, -20, 768, 1024);
        }
        self.entryButton.frame =CGRectMake(534, 856, 112, 37);
        self.coverBackground.frame =CGRectMake(0, -20, 768, 1024);
        
        if(readyToEnter)
           self.coverBackground.image =[UIImage imageNamed:@"splash-vertical-swipe.png"];
        else 
        {
           self.coverBackground.image =[UIImage imageNamed:@"Default-Portrait~ipad.png"];
        }
        
        //self.extraView.frame =CGRectMake(0, -20, 768, 1024);
        self.extraWebView.frame =CGRectMake(0, 68, 768, 956);
        self.extraLoadingView.frame = self.extraWebView.frame;
        
        self.extraTitle.frame =CGRectMake(262, 4, 244, 40);
        self.loadingView.frame =CGRectMake(309, 242, 151, 151);
        self.infoLabel.frame =CGRectMake(234, 750, 300, 21);

        self.updateButton.frame =CGRectMake(324, 790, 120, 37);
        
        self.extraInfo.frame =CGRectMake(284, 512, 200, 52);
        
        
    }
    else if( orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        NSLog(@"landscape");
        self.coverView.frame =CGRectMake(0, 0, 1024, 748);
        self.mainWebView.frame =CGRectMake(0, 0, 1024, 748);
        self.entryButton.frame =CGRectMake(790, 600, 112, 37);
        self.coverBackground.frame =CGRectMake(0, -20, 1024, 768);
        
        if(readyToEnter)
        {    
            self.coverBackground.image =[UIImage imageNamed:@"splash-landscape-swipe.png"];
        }
        else {
            self.coverBackground.image =[UIImage imageNamed:@"Default-Landscape~ipad.png"];
        }
        
        self.extraView.frame =CGRectMake(0, -20, 1024, 768);
        self.extraWebView.frame =CGRectMake(0, 68, 1024, 700);
        self.extraLoadingView.frame = self.extraWebView.frame;
        
        
        self.extraTitle.frame =CGRectMake(262, 4, 500, 40);
        self.loadingView.frame =CGRectMake(437, 242, 151, 151);
        self.infoLabel.frame =CGRectMake(362, 600, 300, 21);

        self.updateButton.frame =CGRectMake(452, 640, 120, 37);
        
        self.extraInfo.frame =CGRectMake(412, 512, 200, 52);
        
        
    }
    /*else {
        NSLog(@"unKnown");
    }*/


}




#pragma mark - entry

-(IBAction)enterMainFrame:(id)sender
{
    if(readyToEnter)
    {
        self.coverView.hidden =YES;
        NSLog(@"slide to enter.");
    }
    
    
   /* [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:5];
    [UIView setAnimationTransition:110 forView:self.view cache:NO];
    [UIView commitAnimations];*/

}

#pragma mark - webview delegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"loaded now"); 
     //[[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
    
    /*NSLog(@"Cache memory capacity = %f M bytes", [[NSURLCache sharedURLCache] memoryCapacity]/(1024*1024.0f));
    NSLog(@"Cache disk capacity = %f M bytes", [[NSURLCache sharedURLCache] diskCapacity] / (1024*1024.0f));
    NSLog(@"Cache Memory Usage = %f M bytes", [[NSURLCache sharedURLCache] currentMemoryUsage] /
          (1024*1024.0f));
    NSLog(@"Cache Disc Usage = %f M bytes", [[NSURLCache sharedURLCache] currentDiskUsage] /
          (1024*1024.0f));*/
    
    if(webView ==self.extraWebView)
    {
       NSString* t =[webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.extraTitle.text = t;
        
        [self stopLoading]; 
        
    
    }
    
    
    if(webView ==self.mainWebView)
    {
        if(firstLoad)
        {  
            firstLoad =NO; 
            
            //NSString* s =@"iosCallback('init', '{\"netStatus\": true}');";
            //[self callWebViewWithFunction:s];
            

        }
    }   
        
    //[self updateNetStatus:hostReach];
    
}


- (void)checkEnter
{



}



//javascript injection

- (void)callWebViewWithFunction:(NSString*)funString
{
    //NSLog(@"calling back %@",funString); 
   [self.mainWebView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@",funString]];
    
}

-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType 
{


    NSString *requestString = [[request URL] absoluteString];
    NSLog(@"pre web get %@",requestString);

    NSArray *components = [requestString componentsSeparatedByString:@"::"];
    
    if([components count]<2) return YES;
    
    NSString* head =(NSString *)[components objectAtIndex:0];
    NSString* fun =(NSString*)[components objectAtIndex:1];
    
    if([head isEqualToString:@"imdnews"])
    {
        NSLog(@"imdNews %@",fun);
        if([fun isEqualToString:@"initCompleted"])
        {
            NSLog(@"init completed");
            NSString* s =@"iosCallback('init', '{\"netStatus\": true}');";
            [self callWebViewWithFunction:s];
            return NO;
        }    
    
        if([fun isEqualToString:@"openLink"])
        {
            if([components count]!=3)return YES; 
           
            NSString* link =(NSString *)[components objectAtIndex:2];
            
            [self openWebViewWithURL:link];
            return NO;
        }
        
        if([fun isEqualToString:@"shareArticle"])
        {
          //imdnews::shareArticle::type::title::url  
            
            
          if([components count]!=5)return YES; 
        
            NSString* shareType =(NSString *)[components objectAtIndex:2];
            NSString* shareTitle =(NSString *)[components objectAtIndex:3];
            NSString* shareURL =(NSString *)[components objectAtIndex:4];
            
            [self shareLink:shareURL title:shareTitle way:shareType];
            
        }    
        
        if([fun isEqualToString:@"shareImage"])
        {
            //imdnews::shareImage::type::url
            
            if([components count]!=5)return YES; 
            
            NSString* shareType =(NSString *)[components objectAtIndex:2];
            NSString* shareTitle =(NSString *)[components objectAtIndex:3];
            NSString* shareURL =(NSString *)[components objectAtIndex:4];
            
            [self shareImage:shareURL title:shareTitle way:shareType];
            
        }
        
        if([fun isEqualToString:@"requestShareBindingInfo"]) 
        {
            NSLog(@"request binding");
           //imdnews::requestShareBindingInfo
           if([components count]!=2)return YES;
            
            [self updateShareStatus];
        
        }
        
        if([fun isEqualToString:@"bindShare"])
        {  
           //imdnews::bindShare::type
            if([components count]!=3)return YES;
            
            NSLog(@"bind now");
            NSString* sharer =(NSString *)[components objectAtIndex:2];
            
            [self bindSharer:sharer];
            
        
        }
        
        if([fun isEqualToString:@"unbindShare"])
        {  
            //imdnews::unbindShare::type
            if([components count]!=3)return YES;
            NSLog(@"unbind now");
            
            NSString* sharer =(NSString *)[components objectAtIndex:2];
            [self unBindConfirm:sharer];
            //[self unBindSharer:sharer];
            
        }
        
        if([fun isEqualToString:@"trackPageview"])
        {    
           //imdnews::trackPageview::url
            if([components count]!=3)return YES;
            
            NSString* trackEntry =(NSString *)[components objectAtIndex:2];
            NSError* error;

            if (![[GANTracker sharedTracker] trackPageview:trackEntry
                                                 withError:&error]) {
                // Handle error here
                
                NSLog(@"track pageview error %@",error);
                
            }
            
            
        }
        
        if([fun isEqualToString:@"trackEvent"])
        {    
           //imdnews::trackEvent::category::action::label::value
            if([components count]!=6)return YES;
            
            NSString* trackEvent =(NSString *)[components objectAtIndex:2];
            NSString* trackAction =(NSString *)[components objectAtIndex:3];
            NSString* trackLabel =(NSString *)[components objectAtIndex:4];
            NSString* trackValue =(NSString *)[components objectAtIndex:5];
            
        
            
            NSError* error;

            if (![[GANTracker sharedTracker] trackEvent:trackEvent
                                                 action:trackAction
                                                  label:trackLabel
                                                  value:[trackValue intValue]
                                              withError:&error]) {
                // Handle error here
                
                NSLog(@"track pageEvent error %@",error);
                
                
            }
            
            
        }
        
        if([fun isEqualToString:@"openapp"])
        { 
           //imdnews::openapp::appname
            if([components count]!=3)return YES;
            
            NSString* appName =(NSString *)[components objectAtIndex:2];
            
            if([appName isEqualToString:@"docsearch"])
            {   
                NSString* url =[NSString stringWithFormat:@"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@&mt=8",SEARCH_APP_ID];
                
                NSLog(@"%@",url);
                
                
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
                //http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=291586600&mt=8
            
            }    
            NSLog(@""); 
            
        }
        
        
        if([fun isEqualToString:@"rateme"])
        { 
            //imdnews::rateme
            if([components count]!=2)return YES;
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString: self.ratingsURL]];
            
            NSLog(@"%@",self.ratingsURL); 
            
        }
        
        if([fun isEqualToString:@"downloadImage"])
        {
           //downloadImage imdnews::downloadImage::url@@url@@url
          
            if([components count]!=3)return YES;
             
            NSString* resString =(NSString *)[components objectAtIndex:2];
            
            [self saveAndDownloadImages:resString];
        
        
        }
        
        if([fun isEqualToString:@"clearCache"])
        {
            //clearCache  imdnews::clearCache::null
            
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
        }
        
    }
    
    
    return YES;
}


- (void)openWebViewWithURL:(NSString*)url
{
    NSLog(@"url =%@",url);
    //url =[NSString stringWithFormat:@"%@#read-more",url];
    
    //NSURL *url1 =[NSURL URLWithString:@"http://www.sina.com.cn"];
    NSURL *url1 =[NSURL URLWithString:url];
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url1];
    [extraWebView loadRequest:urlRequest];
    extraWebView.delegate = self;

    self.extraTitle.text = @"";
    
     //[UIView beginAnimations:nil context:NULL];
     //[UIView setAnimationDuration:0.5];
     
     self.extraView.hidden =NO;
    [self starLoading];
    
    //[UIView commitAnimations];

}





- (void)shareTo:(NSString*)shareWay Content:(NSString*)contents
{


}

- (void)initSwipe
{
    
    //swipes
    UISwipeGestureRecognizer *swipeGesture = nil;
    
    swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(enterMainFrame:)];
    
	swipeGesture.cancelsTouchesInView = NO; 
    swipeGesture.delaysTouchesEnded = NO; 
    swipeGesture.delegate = self;
	swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft; // ++page
	[self.coverView addGestureRecognizer:swipeGesture]; 
    [swipeGesture release];
    

}


#pragma mark - reachabiltiy
//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	[self updateNetStatus:curReach];
}


- (void)updateNetStatus:(Reachability*)curReach
{

    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired= [curReach connectionRequired];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"Access Not Available";
            connectionRequired= NO;  
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"Reachable WWAN";
            break;
        }
        case ReachableViaWiFi:
        {
            statusString= @"Reachable WiFi";
            break;
        }
    }
    
    //todo: feedback to js

}

- (void)checkAppVer
{
    
    
    MKNetworkEngine* engine =[[MKNetworkEngine alloc] initWithHostName:@"www.i-md.com" customHeaderFields:nil];
    
    //NSString * ver =[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString* ver =API_VER;
    //for test
    //ver =@"2";
    
    MKNetworkOperation* op =[engine operationWithPath:[NSString stringWithFormat:@"news/reader/api/check?v=%@",ver]];
    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        NSLog(@"responseString: %@", [op responseString]);
        
    if([[op responseString] isEqualToString:@"false"])
    {
        //go update this app pls
        NSLog(@"detected api is not ok for now");
        
        self.infoLabel.text =@"睿医资讯已更新，本版本无法正常工作。";
        self.updateButton.hidden =NO;
        
        
        
    }
    else {
        readyToEnter =YES;
        //NSLog(@"check ver o");
        [self renderOrientation];
        self.infoLabel.hidden =YES;
        //[self initSwipe];
        
    }    
        
    } onError:^(NSError *error) { 
        NSLog(@"%@", error);
        
        readyToEnter =YES;
        //NSLog(@"check ver o");
        [self renderOrientation];
        self.infoLabel.hidden =YES;
        //[self initSwipe];
    }];
    
    [engine enqueueOperation:op];
    
    
    
}

- (IBAction)popShare:(id)sender
{
    NSLog(@"pop share");
    //SHKItem *item = [SHKItem text:@"sth."];
    
    if(![sinaWeibo isAuthorized])
       [sinaWeibo authorize]; 
    else {
        //NSLog(@"hasBeenAuthorized [%@]",SHKSinaWeiboScreenName);
    }
    
    //[SHKSinaWeibo performSelector:@selector(shareItem:) withObject:item];
    
    
    
    
    //[NSClassFromString([sharers objectAtIndex:buttonIndex]) performSelector:@selector(shareItem:) withObject:item];
  
}


- (IBAction)refreshExtraWeb:(id)sender
{

    [self.extraWebView reload];  

}

- (IBAction)forwardExtraWeb:(id)sender
{
    [self.extraWebView goForward];
}

- (IBAction)backwardExtraWeb:(id)sender
{
    [self.extraWebView goBack];

}




-(void)shareLink:(NSString*)url title:(NSString*)title way:(NSString*)sharer
{   
    NSLog(@"sharing title %@, link %@",title,url);
    
    title =[title
     stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    
    
    if([sharer isEqualToString:@"sina"])
    {
        //SHKItem *item = [SHKItem URL:[NSURL URLWithString:url] title:title];
        //[SHKSinaWeibo performSelector:@selector(shareItem:) withObject:item];
        
        BOOL isSina = [weiBoEngine isLoggedIn] && ![weiBoEngine isAuthorizeExpired];
        if(isSina)
        {
            WBSendView *sendView = [[WBSendView alloc] initWithNibName:nil bundle:nil];
            [sendView setDelegate:self];
            [sendView initWithAppKey:SHKSinaWeiboConsumerKey appSecret:SHKSinaWeiboConsumerSecret text:[NSString stringWithFormat:@"%@ %@", title, url] image:nil];
            //[sendView show:YES];
            [[SHK currentHelper] showViewController:sendView];
            [sendView release];
        }
        else 
        {
            [weiBoEngine logIn];
        }
    }
    
    
    if([sharer isEqualToString:@"netease"])
    {    
        SHKItem *item = [SHKItem URL:[NSURL URLWithString:url] title:title];
        [SHKNetEaseWeibo performSelector:@selector(shareItem:) withObject:item];
    }
    
    if([sharer isEqualToString:@"tencent"])
    {
        NSString* body = [NSString stringWithFormat:@"%@ %@",title,url];
        SHKItem *item = [SHKItem text:body];
        [SHKTencentWeibo performSelector:@selector(shareItem:) withObject:item];
    }
    
    if([sharer isEqualToString:@"mail"])
    {
        [SHKMail shareURL:[NSURL URLWithString:url] title:title];
    }    
    
}

-(void)shareImage:(NSString*)url title:(NSString*)title way:(NSString*)sharer
{   
    NSLog(@"sharing title %@, image %@",title,url);
    
    title = [title stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    if([sharer isEqualToString:@"sina"])
    {
        MKNetworkEngine* engine =[[MKNetworkEngine alloc] initWithHostName:@"http://www.i-md.com/" customHeaderFields:nil];
        
        
        [engine useCache];
        
        
        NSURL* imgUrl = [NSURL URLWithString:url];
        
        //imgUrl =[NSURL URLWithString:@"http://cc.cocimg.com/bbs/attachment/photo/Mon_1203/21_a8e51333201571ae4d84b112ecba0.jpg"];
        
        
        
        //download the image
        
        [engine imageAtURL:imgUrl
              onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                  
                  if(fetchedImage ==nil)
                  {
                      NSLog(@"get image error");
                      //[self showMessage:@"保存出错"];
                      
                  }
                  else 
                  {
                      
                      
                      //SHKItem *item = [SHKItem image:fetchedImage title:title];
                      //[SHKSinaWeibo performSelector:@selector(shareItem:) withObject:item];
                      WBSendView *sendView = [[WBSendView alloc] initWithNibName:nil bundle:nil];
                      [sendView setDelegate:self];
                      [sendView initWithAppKey:SHKSinaWeiboConsumerKey appSecret:SHKSinaWeiboConsumerSecret text:[NSString stringWithFormat:@"%@", title] image:fetchedImage];
                      
                      [[SHK currentHelper] showViewController:sendView];
                      [sendView release];
                
                      
                  }
                  
              }];
        

        
    }
    
    
    if([sharer isEqualToString:@"netease"])
    {
        MKNetworkEngine* engine =[[MKNetworkEngine alloc] initWithHostName:@"http://www.i-md.com/" customHeaderFields:nil];
        
        
        [engine useCache];
        
        
        NSURL* imgUrl = [NSURL URLWithString:url];
        
        //imgUrl =[NSURL URLWithString:@"http://cc.cocimg.com/bbs/attachment/photo/Mon_1203/21_a8e51333201571ae4d84b112ecba0.jpg"];
        
        
        
        //download the image
        
        [engine imageAtURL:imgUrl
              onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                  
                  if(fetchedImage ==nil)
                  {
                      NSLog(@"get image error");
                      //[self showMessage:@"保存出错"];
                      
                  }
                  else 
                  {
                      
                      
                      SHKItem *item = [SHKItem image:fetchedImage title:title];
                      [SHKNetEaseWeibo performSelector:@selector(shareItem:) withObject:item];
                     
                      
                      
                  }
                                    
              }];
        

        
        
        
    }
    
    if([sharer isEqualToString:@"tencent"])
    {
        MKNetworkEngine* engine =[[MKNetworkEngine alloc] initWithHostName:@"http://www.i-md.com/" customHeaderFields:nil];
        
        
        [engine useCache];
        
        
        NSURL* imgUrl = [NSURL URLWithString:url];
        
        //imgUrl =[NSURL URLWithString:@"http://cc.cocimg.com/bbs/attachment/photo/Mon_1203/21_a8e51333201571ae4d84b112ecba0.jpg"];
        
        
        
        //download the image
        
        [engine imageAtURL:imgUrl
              onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                  
                  if(fetchedImage ==nil)
                  {
                      NSLog(@"get image error");
                      //[self showMessage:@"保存出错"];
                      
                  }
                  else 
                  {
                      
                      
                      SHKItem *item = [SHKItem image:fetchedImage title:title];
                      [SHKTencentWeibo performSelector:@selector(shareItem:) withObject:item];
                      
                      
                      
                  }
                  
              }];
        
        
        
        
        
    }

    
    if([sharer isEqualToString:@"mail"])
    {
        [SHKMail shareURL:[NSURL URLWithString:url] title:title];
    }
    
}





-(NSString*)getShareStatus
{
   //'{\"sina\": true, \"netease\": false}');"; 
    BOOL isSina = [weiBoEngine isLoggedIn] && ![weiBoEngine isAuthorizeExpired];
    
   //NSString* s =[NSString stringWithFormat:@"{\"sina\": %@, \"netease\": %@, \"tencent\": %@}",[SHKSinaWeibo isServiceAuthorized]?@"true":@"false",[SHKNetEaseWeibo isServiceAuthorized]?@"true":@"false",[SHKTencentWeibo isServiceAuthorized]?@"true":@"false"]; 
    //modify by merlin
    NSString* s =[NSString stringWithFormat:@"{\"sina\": %@, \"netease\": %@, \"tencent\": %@}",isSina?@"true":@"false",[SHKNetEaseWeibo isServiceAuthorized]?@"true":@"false",[SHKTencentWeibo isServiceAuthorized]?@"true":@"false"];
    
   return s;


}

- (int)getSharerStatus
{
    int state =0;
    
    //if([SHKSinaWeibo isServiceAuthorized])
    //modify by merlin
    if([weiBoEngine isLoggedIn] && ![weiBoEngine isAuthorizeExpired])
        state = state | 4;
    if([SHKNetEaseWeibo isServiceAuthorized])
        state = state | 2;
    if([SHKTencentWeibo isServiceAuthorized])
        state = state | 1;
    
    return state;
}



-(void)updateShareStatus
{
    self.shareStatus =[self getShareStatus];
    NSLog(@"changed calling back");
    //status changed
    NSString* s =[NSString stringWithFormat:@"iosCallback('updateBindInfo', '%@');",shareStatus];
    
    //@"iosCallback('updateBindInfo',  '{\"sina\": true, \"netease\": false}');";
    [self callWebViewWithFunction:s]; 
    
    
}

-(void)checkShare
{
    [self performSelector:@selector(checkShareStatus) withObject:nil afterDelay:0.5f];

}

-(void)checkShareStatus
{
    //if(YES)return;
    
    //NSLog(@"updating status");
    
    /*
    sharerState =[self getSharerStatus];
    oldState =[[[NSUserDefaults standardUserDefaults] objectForKey:sharerKey] intValue];
    
    if(oldState!=sharerState)
    {
        //NSLog(@"updating"); 
        [self updateShareStatus];

        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:sharerState] forKey:sharerKey];
        [[NSUserDefaults standardUserDefaults] synchronize];

    } */   
    
    

   
    
    self.shareStatus =[self getShareStatus];
    
    NSString* oldStatus =[[NSUserDefaults standardUserDefaults] objectForKey:@"shareStatus"];
    
    NSLog(@"old %@",oldStatus);
    
    NSLog(@"new %@",shareStatus);
    
    
    
    if(oldStatus !=nil)
    {
        
        if(![oldStatus isEqualToString:shareStatus])
        {    
            NSLog(@"status changed");
            [self updateShareStatus];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:shareStatus forKey:@"shareStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];


}


-(void)bindSharer:(NSString*)way
{
   if([way isEqualToString:@"sina"])
   {
       //if(![SHKSinaWeibo isServiceAuthorized])
       /*[sinaWeibo release];
       sinaWeibo =[[SHKSinaWeibo alloc] init];
       [sinaWeibo authorize];*/
       [weiBoEngine logIn];
   }   
   else if([way isEqualToString:@"netease"])
   {
       [netEaseWeibo release];
       netEaseWeibo  =[[SHKNetEaseWeibo alloc] init];
       [netEaseWeibo authorize];
   
   }
    
    else if([way isEqualToString:@"tencent"])
    {
        [tencentWeibo release];
        tencentWeibo = [[SHKTencentWeibo alloc] init];
        [tencentWeibo authorize];
    }

    self.shareStatus =[self getShareStatus];
    [[NSUserDefaults standardUserDefaults] setObject:shareStatus forKey:@"shareStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

-(void)unBindConfirm:(NSString*)way
{
    NSString* weiboName =@"";
    int tagOffset =0;
    
    if([way isEqualToString:@"sina"])
    {
       weiboName =@"新浪微博";
        tagOffset =0;
    }
    else if([way isEqualToString:@"netease"])
    {
       weiboName =@"网易微博";
        tagOffset =1;
    }
    else if([way isEqualToString:@"tencent"])
    {
        weiboName = @"腾讯微博";
        tagOffset = 2;
    }

    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"睿医资讯"
                                                      message:[NSString stringWithFormat:@"解除绑定%@?",weiboName]
                                                     delegate:self
                                            cancelButtonTitle:@"取消"
                                            otherButtonTitles:@"确认", nil];
    
    message.tag =114+tagOffset;
    [message show];

}

-(void)unBindSharer:(NSString*)way
{
    if([way isEqualToString:@"sina"])
    {
        //[SHKSinaWeibo logout];
        //modify by merlin
        [weiBoEngine logOut];
        [self updateShareStatus];
    }
    
    if([way isEqualToString:@"netease"])
    {
        [SHKNetEaseWeibo logout];
        [self updateShareStatus];
    }
    
    if([way isEqualToString:@"tencent"])
    {
        [SHKTencentWeibo logout];
        [self updateShareStatus];
    }
    
    self.shareStatus =[self getShareStatus];
    [[NSUserDefaults standardUserDefaults] setObject:shareStatus forKey:@"shareStatus"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}         

- (IBAction)hideExtraWeb:(id)sender
{
    self.extraView.hidden =YES;


}


- (void)saveAndDownloadImages:(NSString*)resString
{
    if(stillSavingImage)return;
    
    if(!stillSavingImage)
        stillSavingImage =YES;
    
    
    NSArray *components = [resString componentsSeparatedByString:@"@@"];

    //NSLog(@"down image test");
    
    
    MKNetworkEngine* engine =[[MKNetworkEngine alloc] initWithHostName:@"http://www.i-md.com/" customHeaderFields:nil];
    
    
    [engine useCache];
    
    
    for (int i=0; i<components.count; i++) {
        
        NSURL* url = [NSURL URLWithString:[components objectAtIndex:i]];
        //url =[NSURL URLWithString:@"http://cc.cocimg.com/bbs/attachment/photo/Mon_1203/21_a8e51333201571ae4d84b112ecba0.jpg"];
        
        //download the image
    
        [engine imageAtURL:url
              onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                  
                  if(fetchedImage ==nil)
                  {
                      NSLog(@"error");
                      [self showMessage:@"保存出错"];
                      
                  }
                  else 
                  {
                      
                      UIImageWriteToSavedPhotosAlbum(fetchedImage, nil, nil, nil);
                      
                      NSLog(@"completed");
                      [self showMessage:@"已保存到照片库"];
                      
                      
                  }
                  stillSavingImage =NO;
                  
              }];
        

        
    }
    
   
    
    /*
    //set the image's URL
    NSURL* url = [NSURL URLWithString:@"http://mycharitywater.org/images/instruct_graphic.jpg"];
    
    //download the image
    [engine imageAtURL:url
          onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
              UIImageWriteToSavedPhotosAlbum(fetchedImage, nil, nil, nil);
          }];
    */

    
    
}

- (void)starLoading
{
    self.extraLoadingView.hidden =NO;
}


- (void)stopLoading
{
    self.extraLoadingView.hidden =YES;
}


- (void)showMessage:(NSString*)s
{
    self.extraInfo.hidden =NO;
    self.extraInfo.text =s;

    [self performSelector:@selector(hideMessage) withObject:nil afterDelay:0.8f];
        
}

- (void)hideMessage
{
    self.extraInfo.hidden =YES;

}

- (IBAction)updateMe:(id)sender
{
    NSString* url =[NSString stringWithFormat:@"http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%@&mt=8",APP_ID];
    
    NSLog(@"%@",url);

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (void)timerUpdate
{
   if(orientation ==5)
   {
       [self orientationChanged];
   }
    
   //[self checkShareStatus];
   //report_memory();
    
}

- (void)showMessageInfo
{
    [self showMessage:@"已保存到照片库"];
}


#pragma mark - uialertview delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    if(alertView.tag<114)return;
    
    if (buttonIndex == 1)
    {
        NSLog(@"confirmed");
        int way =alertView.tag -114;
        if(way ==0)
        { 
            [self unBindSharer:@"sina"];
        }
        else if(way ==1)
        {
            [self unBindSharer:@"netease"];
            
        }
        else if(way == 2)
        {
            [self unBindSharer:@"tencent"];
        }
        
        
        
    }
    
    if (buttonIndex == 0)
    {
        NSLog(@"canceled");
       
    }
}

#pragma mark - WBSendViewDelegate Methods

- (void)sendViewDidFinishSending:(WBSendView *)view
{
    //[view hide:YES];
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
    [[SHKActivityIndicator currentIndicator] displayCompleted:SHKLocalizedString(@"分享成功!")];
}

- (void)sendView:(WBSendView *)view didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
    //[view hide:YES];
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
    [[SHKActivityIndicator currentIndicator] hide];
    UIAlertView* alertView = [[UIAlertView alloc]initWithTitle:nil 
													   message:@"微博发送失败！" 
													  delegate:nil
											 cancelButtonTitle:@"确定" 
											 otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

@end
