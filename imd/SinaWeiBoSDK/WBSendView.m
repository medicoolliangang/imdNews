//
//  WBSendView.m
//  SinaWeiBoSDK
//  Based on OAuth 2.0
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//
//  Copyright 2011 Sina. All rights reserved.
//

#import "WBSendView.h"

static BOOL WBIsDeviceIPad()
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 30200
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
		return YES;
	}
#endif
	return NO;
}

@interface WBSendView (Private)

- (void)onCloseButtonTouched:(id)sender;
- (void)onSendButtonTouched:(id)sender;
- (void)onClearTextButtonTouched:(id)sender;
- (void)onClearImageButtonTouched:(id)sender;

- (void)sizeToFitOrientation:(UIInterfaceOrientation)orientation;
- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation;
- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation;

- (void)addObservers;
- (void)removeObservers;

- (UIInterfaceOrientation)currentOrientation;

- (void)bounceOutAnimationStopped;
- (void)bounceInAnimationStopped;
- (void)bounceNormalAnimationStopped;
- (void)allAnimationsStopped;

- (int)textLength:(NSString *)text;
- (void)calculateTextLength;

- (void)hideAndCleanUp;

@end

@implementation WBSendView

@synthesize contentText;
@synthesize contentImage;
@synthesize delegate;

#pragma mark - WBSendView Life Circle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
    {		
       
    }
    
    
    return self;
}

- (void)loadView
{
    [super loadView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];	
	
    
    
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object:nil];
	
	[contentTextView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];	
	
	// Remove observers
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name: UIKeyboardWillShowNotification object:nil];
	
	// Remove the SHK view wrapper from the window
	[[SHK currentHelper] viewWasDismissed];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret text:(NSString *)text image:(UIImage *)image
{
    //if (self.view = [super.view initWithFrame:CGRectMake(0, 0, 320, 480)])
    {
        engine = [[WBEngine alloc] initWithAppKey:appKey appSecret:appSecret];
        [engine setDelegate:self];
        
        // background settings
        self.view.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
        [self.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        
        self.view.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
        
        
        UIImageView* titleView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"browser-bg.png"]];
        titleView.frame =CGRectMake(0, 0, self.view.bounds.size.width, 48);
        
        [self.view addSubview:titleView];
        [titleView release];
        
        
        closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeButton addTarget:self action:@selector(onCloseButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        
        closeButton.frame =CGRectMake(13, 7, 70, 36);
        
        [closeButton setImage:[UIImage imageNamed:@"close-btn.png"] forState:UIControlStateNormal];
        [closeButton setImage:[UIImage imageNamed:@"close-btn-active.png"] forState:UIControlStateHighlighted];
        [closeButton setImage:[UIImage imageNamed:@"close-btn-active.png"] forState:UIControlStateSelected];
        
        [self.view addSubview:closeButton];
        
        
        UIButton* shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [shareButton addTarget:self action:@selector(onSendButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        
        shareButton.frame =CGRectMake(457, 7, 70, 36);
        
        [shareButton setImage:[UIImage imageNamed:@"share-btn.png"] forState:UIControlStateNormal];
        [shareButton setImage:[UIImage imageNamed:@"share-btn-active.png"] forState:UIControlStateHighlighted];
        [shareButton setImage:[UIImage imageNamed:@"share-btn-active.png"] forState:UIControlStateSelected];
        
        [self.view addSubview:shareButton];
        
        UILabel* lbl =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 540, 48)];
        lbl.textColor =[UIColor whiteColor];
        lbl.backgroundColor =[UIColor clearColor];
        lbl.textAlignment =UITextAlignmentCenter;
        lbl.font =[UIFont boldSystemFontOfSize:24.0f];
        lbl.text =@"新浪微博";
        [self.view addSubview:lbl];
        [lbl release];
        
        contentTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, 80, self.view.bounds.size.width-20, self.view.bounds.size.height-80)];
        
        contentTextView.delegate = self;
        contentTextView.font = [UIFont systemFontOfSize:20.0f];
        
        NSLog(@"lh = %f",contentTextView.font.lineHeight);
        
        contentTextView.text = text;
        contentTextView.contentInset = UIEdgeInsetsMake(0,0,0,0);
        contentTextView.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];	
        contentTextView.backgroundColor = [UIColor clearColor];
        contentTextView.autoresizesSubviews = YES;
        contentTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        
        [self.view addSubview:contentTextView];
        self.contentText = contentTextView.text;
        
        if(image != nil)
        {
            NSLog(@"has attachment ");
            hasAttachment = YES;
            UIImageView* img =[[UIImageView alloc] initWithImage:image];
            
            img.frame =CGRectMake(18, 160, img.frame.size.width, img.frame.size.height);
            if(img.frame.size.width > 504)
                img.frame = CGRectMake(18, 160, 504, img.frame.size.height*504/img.frame.size.width);
            else if(img.frame.size.height > 460)
                img.frame = CGRectMake(18, 160, img.frame.size.width*460/img.frame.size.height, 460);
            
            
            [self.view addSubview:img];
            [img release];
            
            self.contentImage = image;
        }
        else {
            hasAttachment = NO;
        }
        
        //add back image
        
        UIImageView* bgView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"breaking-line.png"]];
        bgView.frame =CGRectMake(0, 48, 540, 571);
        [self.view addSubview:bgView];
        [bgView release];         
    }
}


- (void)dealloc
{
    [engine setDelegate:nil];
    [engine release], engine = nil;
    
    [panelView release], panelView = nil;
    [panelImageView release], panelImageView = nil;
    [titleLabel release], titleLabel = nil;
    [contentTextView release], contentTextView = nil;
    [wordCountLabel release], wordCountLabel = nil;
    [contentImageView release], contentImageView = nil;
    
    
    [contentText release], contentText = nil;
    [contentImage release], contentImage = nil;
    
    delegate = nil;
    
    [super dealloc];
}

#pragma mark - WBSendView Private Methods

#pragma mark Actions

- (void)onCloseButtonTouched:(id)sender
{
    //[self hide:YES];
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void)onSendButtonTouched:(id)sender
{
    if ([contentTextView.text isEqualToString:@""])
    {
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is empty")
									 message:SHKLocalizedString(@"You must enter a message in order to post.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
    else if (contentTextView.text.length > (hasAttachment?115:140))
    {
        [[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is too long")
									 message:SHKLocalizedString(@"Sina Weibo posts can only be 140 characters in length.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
    }
    
    [engine sendWeiBoWithText:contentTextView.text image:contentImage];
    [[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"正在分享至 %@", @"新浪微博")];
}

- (void)onClearTextButtonTouched:(id)sender
{
   [contentTextView setText:@""];
	[self calculateTextLength];
}

- (void)onClearImageButtonTouched:(id)sender
{
    [contentImageView setHidden:YES];
    [clearImageButton setHidden:YES];
	[contentImage release], contentImage = nil;
}

#pragma mark - Word Count

- (int)sinaCountWord:(NSString*)s

{
    
    int i,n=[s length],l=0,a=0,b=0;
    
    unichar c;
    
    for(i=0;i<n;i++){
        
        c=[s characterAtIndex:i];
        
        if(isblank(c)){
            
            b++;
            
        }else if(isascii(c)){
            
            a++;
            
        }else{
            
            l++;
            
        }
        
    }
    
    if(a==0 && l==0) return 0;
    
    return l+(int)ceilf((float)(a+b)/2.0);
    
}

#pragma mark -

- (void)updateCounter
{
	if (wordCountLabel == nil)
	{
		wordCountLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		wordCountLabel.backgroundColor = [UIColor clearColor];
		wordCountLabel.opaque = NO;
		wordCountLabel.font = [UIFont boldSystemFontOfSize:14];
        wordCountLabel.textAlignment = UITextAlignmentRight;
		
		wordCountLabel.autoresizesSubviews = YES;
		wordCountLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[self.view addSubview:wordCountLabel];
		[self layoutCounter];
	}
	
    int count = (hasAttachment?115:140) - [self sinaCountWord:contentTextView.text];
    
    wordCountLabel.text = [NSString stringWithFormat:@"还可以输入%i字", count];
    wordCountLabel.textColor = count >= 0 ? [UIColor colorWithRed:102/255.0f green:102/255.0f blue:102/255.0f alpha:102/255.0f]: [UIColor redColor];
    
}

- (void)layoutCounter
{
	wordCountLabel.frame = CGRectMake(contentTextView.bounds.size.width-150-15+18,
							   62,
							   150,
							   15);
}

#pragma mark Obeservers

- (void)addObservers
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)removeObservers
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIDeviceOrientationDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillShowNotification" object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UIKeyboardWillHideNotification" object:nil];
}

#pragma mark Text Length

- (int)textLength:(NSString *)text
{
    float number = 0.0;
    for (int index = 0; index < [text length]; index++)
    {
        NSString *character = [text substringWithRange:NSMakeRange(index, 1)];
        
        if ([character lengthOfBytesUsingEncoding:NSUTF8StringEncoding] == 3)
        {
            number++;
        }
        else
        {
            number = number + 0.5;
        }
    }
    return ceil(number);
}

- (void)calculateTextLength
{
    if (contentTextView.text.length > 0) 
	{ 
		[sendButton setEnabled:YES];
		[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	}
	else 
	{
		[sendButton setEnabled:NO];
		[sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
	}
	
	int wordcount = [self textLength:contentTextView.text];
	NSInteger count  = 140 - wordcount;
	if (count < 0)
    {
		[wordCountLabel setTextColor:[UIColor redColor]];
		[sendButton setEnabled:NO];
		[sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
	}
	else
    {
		[wordCountLabel setTextColor:[UIColor darkGrayColor]];
		[sendButton setEnabled:YES];
		[sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	}
	
	[wordCountLabel setText:[NSString stringWithFormat:@"%i",count]];
}

#pragma mark Animations

- (void)bounceOutAnimationStopped
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceInAnimationStopped)];
    [panelView setAlpha:0.8];
	[panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9)];
	[UIView commitAnimations];
}

- (void)bounceInAnimationStopped
{
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.13];
    [UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(bounceNormalAnimationStopped)];
    [panelView setAlpha:1.0];
	[panelView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0)];
	[UIView commitAnimations];
}

- (void)bounceNormalAnimationStopped
{
    [self allAnimationsStopped];
}

- (void)allAnimationsStopped
{
    [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6f]];
    if ([delegate respondsToSelector:@selector(sendViewDidAppear:)])
    {
        [delegate sendViewDidAppear:self];
    }
}

#pragma mark Dismiss

- (void)hideAndCleanUp
{
    [self removeObservers];
	[self.view removeFromSuperview];	
    
    if ([delegate respondsToSelector:@selector(sendViewDidDisappear:)])
    {
        [delegate sendViewDidDisappear:self];
    }
}

#pragma mark - WBSendView Public Methods

- (void)show:(BOOL)animated
{
    [self sizeToFitOrientation:[self currentOrientation]];
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
	if (!window)
    {
		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
	}
  	[window addSubview:self.view];
    
    if ([delegate respondsToSelector:@selector(sendViewWillAppear:)])
    {
        [delegate sendViewWillAppear:self];
    }
    
    if (animated)
    {
        [panelView setAlpha:0];
        CGAffineTransform transform = CGAffineTransformIdentity;
        [panelView setTransform:CGAffineTransformScale(transform, 0.3, 0.3)];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(bounceOutAnimationStopped)];
        [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6f]];
        [panelView setAlpha:0.5];
        [panelView setTransform:CGAffineTransformScale(transform, 1.1, 1.1)];
        [UIView commitAnimations];
    }
    else
    {
        [self allAnimationsStopped];
    }
	
	[self addObservers];
    
}

- (void)hide:(BOOL)animated
{
    if ([delegate respondsToSelector:@selector(sendViewWillDisappear:)])
    {
        [delegate sendViewWillDisappear:self];
    }
    
	if (animated)
    {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(hideAndCleanUp)];
		self.view.alpha = 0;
		[UIView commitAnimations];
	} else {
		
		[self hideAndCleanUp];
	}
}

#pragma mark - UIDeviceOrientationDidChangeNotification Methods

- (void)deviceOrientationDidChange:(id)object
{
	UIInterfaceOrientation orientation = [self currentOrientation];
	if ([self shouldRotateToOrientation:orientation])
    {
        NSTimeInterval duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
		[self sizeToFitOrientation:orientation];
		[UIView commitAnimations];
	}
}

#pragma mark - UIKeyboardNotification Methods

- (void)keyboardWillShow:(NSNotification*)notification
{
    if (isKeyboardShowing)
    {
        return;
    }
	
	isKeyboardShowing = YES;
	
	/*if (WBIsDeviceIPad())
    {
		// iPad is not supported in this version
		return;
	}
	
	if (UIInterfaceOrientationIsLandscape([self currentOrientation]))
    {
        
 		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
 		
        [contentTextView setFrame:CGRectMake(13, 50, 480 - 32 - 26, 60)];
        [contentImageView setCenter:CGPointMake(448 / 2, 155)];
        [clearImageButton setCenter:CGPointMake(contentImageView.center.x + contentImageView.frame.size.width / 2,
                                                contentImageView.center.y - contentImageView.frame.size.height / 2)];

		[wordCountLabel setFrame:CGRectMake(224 + 90, 100, 30, 30)];
		[clearTextButton setFrame:CGRectMake(224 + 120, 101, 30, 30)];
        
 		[UIView commitAnimations];
	}
	else
    {
		
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		
		[panelView setFrame:CGRectInset(panelView.frame, 0, -51)];
		
 		[UIView commitAnimations];
	}*/
    CGRect keyboardFrame;
	CGFloat keyboardHeight;
	
	[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
	keyboardHeight = keyboardFrame.size.height;
	
    UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL inLandscape = orient == UIInterfaceOrientationLandscapeLeft || orient == UIInterfaceOrientationLandscapeRight;
	BOOL upsideDown = orient == UIInterfaceOrientationPortraitUpsideDown || orient == UIInterfaceOrientationLandscapeRight;
	
	CGPoint topOfViewPoint = [self.view convertPoint:CGPointZero toView:nil];
	CGFloat topOfView = inLandscape ? topOfViewPoint.x : topOfViewPoint.y;
	
	CGFloat screenHeight = inLandscape ? [[UIScreen mainScreen] applicationFrame].size.width : [[UIScreen mainScreen] applicationFrame].size.height;
	
	CGFloat distFromBottom = screenHeight - ((upsideDown ? screenHeight - topOfView : topOfView ) + self.view.bounds.size.height) + ([UIApplication sharedApplication].statusBarHidden || upsideDown ? 0 : 20);							
	CGFloat maxViewHeight = self.view.bounds.size.height - keyboardHeight + distFromBottom;
	
	contentTextView.frame =CGRectMake(20, 80, self.view.bounds.size.width-20, maxViewHeight-80);
    
	[self layoutCounter];
}

- (void)keyboardWillHide:(NSNotification*)notification
{
	isKeyboardShowing = NO;
	
	if (WBIsDeviceIPad())
    {
		return;
	}
}

#pragma mark - UITextViewDelegate Methods

- (void)textViewDidChange:(UITextView *)textView
{
	//[self calculateTextLength];
    [self updateCounter];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateCounter];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{	
    return YES;
}

#pragma mark - WBEngineDelegate Methods

- (void)engine:(WBEngine *)engine requestDidSucceedWithResult:(id)result
{
    if ([delegate respondsToSelector:@selector(sendViewDidFinishSending:)])
    {
        [delegate sendViewDidFinishSending:self];
    }
}

- (void)engine:(WBEngine *)engine requestDidFailWithError:(NSError *)error
{
    if ([delegate respondsToSelector:@selector(sendView:didFailWithError:)])
    {
        [delegate sendView:self didFailWithError:error];
    }
}

- (void)engineNotAuthorized:(WBEngine *)engine
{
    if ([delegate respondsToSelector:@selector(sendViewNotAuthorized:)])
    {
        [delegate sendViewNotAuthorized:self];
    }
}

- (void)engineAuthorizeExpired:(WBEngine *)engine
{
    if ([delegate respondsToSelector:@selector(sendViewAuthorizeExpired:)])
    {
        [delegate sendViewAuthorizeExpired:self];
    }
}

@end
