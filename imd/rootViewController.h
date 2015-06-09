//
//  rootViewController.h
//  imdNews
//
//  Created by wulg on 3/26/12.
//  Copyright (c) 2012 www.i-md.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WBEngine.h"
#import "WBSendView.h"

@class SHKSinaWeibo,SHKNetEaseWeibo,SHKTencentWeibo;
@class Reachability;


@interface rootViewController : UIViewController<UIWebViewDelegate,UIGestureRecognizerDelegate,UIAlertViewDelegate,WBEngineDelegate,WBSendViewDelegate>
{
    UIButton* entryButton;
    
    UIView* coverView;
    UIWebView* mainWebView;
    UIView* extraView;
    UIImageView* coverBackground;
    UIWebView* extraWebView;

    UIView* extraLoadingView;
    UIView* loadingView;
    
    Reachability* hostReach;
    BOOL firstLoad;
    BOOL readyToEnter;
    BOOL isorientationChanged;

    SHKSinaWeibo* sinaWeibo;
    SHKNetEaseWeibo* netEaseWeibo;
    SHKTencentWeibo* tencentWeibo;
    
    NSString* ratingsURL;
    
    UILabel* extraTitle;
    
    NSString* showingMessage;
    
    UILabel* infoLabel;
    UIButton* updateButton;
    
    UILabel* extraInfo;
    
    BOOL stillSavingImage;
    
    int orientation;
    
    NSString* shareStatus;
    
    int sharerState;
    int oldState;
    NSString* sharerKey;
    WBEngine* weiBoEngine;
}

@property (strong, nonatomic) IBOutlet NSString* ratingsURL;
@property (strong, nonatomic) IBOutlet UIWebView* mainWebView;
@property (strong, nonatomic) IBOutlet UIView* coverView;
@property (strong, nonatomic) IBOutlet UIButton* entryButton;
@property (strong, nonatomic) IBOutlet UIImageView* coverBackground;
@property (strong, nonatomic) IBOutlet UIView* extraView;
@property (strong, nonatomic) IBOutlet UIWebView* extraWebView;
@property (strong, nonatomic) IBOutlet UILabel* extraTitle;
@property (strong, nonatomic) IBOutlet UILabel* extraInfo;
@property (strong, nonatomic) IBOutlet UIView* extraLoadingView;
@property (strong, nonatomic) IBOutlet UIView* loadingView;
@property (strong, nonatomic) IBOutlet UILabel* infoLabel;
@property (strong, nonatomic) IBOutlet UIButton* updateButton;
@property (strong, nonatomic) NSString* shareStatus;
@property (nonatomic, retain) WBEngine* weiBoEngine;


- (void)initSwipe;


- (IBAction)enterMainFrame:(id)sender;

- (IBAction)popShare:(id)sender;

- (IBAction)hideExtraWeb:(id)sender;

- (IBAction)refreshExtraWeb:(id)sender;

- (IBAction)forwardExtraWeb:(id)sender;

- (IBAction)backwardExtraWeb:(id)sender;

- (void)unBindConfirm:(NSString*)way;

- (void)orientationChanged;

- (void)renderOrientation;

- (void)callWebViewWithFunction:(NSString*)funName;

- (void)openWebViewWithURL:(NSString*)url;


- (void)shareTo:(NSString*)shareWay Content:(NSString*)contents;

- (void)reachabilityChanged: (NSNotification* )note;

- (void)updateNetStatus:(Reachability*)curReach;

- (void)checkAppVer;

- (void)shareLink:(NSString*)url title:(NSString*)title way:(NSString*)sharer;

- (void)shareImage:(NSString*)url title:(NSString*)title way:(NSString*)sharer;

- (void)checkShareStatus;
- (void)checkShare;
- (void)updateShareStatus;

- (void)saveAndDownloadImages:(NSString*)resString;

- (void)starLoading;
- (void)stopLoading;

- (void)showMessage:(NSString*)s;
- (void)hideMessage;

- (IBAction)updateMe:(id)sender;

- (void)timerUpdate;
- (NSString*)getShareStatus;
- (int)getSharerStatus;

@end
