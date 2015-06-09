//
//  SHKSinaWeiboForm.h
//  ShareKit
//
//  Created by icyleaf on 11-03-31.
//  Copyright 2011 icyleaf.com. All rights reserved.

//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKSinaWeiboForm.h"
#import "SHK.h"
#import "SHKSinaWeibo.h"

#define WEIBO_Y 80

@implementation SHKSinaWeiboForm

@synthesize delegate;
@synthesize textView;
@synthesize counter;
@synthesize hasAttachment;
@synthesize attachImage;

- (void)dealloc 
{
	[delegate release];
	[textView release];
	[counter release];
    [attachImage release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    /*if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{		
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																							  target:self
																							  action:@selector(cancel)];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"Send to %@", [SHKSinaWeibo sharerTitle])
																				  style:UIBarButtonItemStyleDone
																				 target:self
																				 action:@selector(save)];
    }*/
    

    
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
     {		
     /*    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"关闭")
     style:UIBarButtonItemStyleBordered
     target:self
     action:@selector(cancel)];
    
     
     self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:SHKLocalizedString(@"分享到新浪微博")
     style:UIBarButtonItemStyleBordered
     target:self
     action:@selector(save)];*/
     }
    
    
    return self;
}



- (void)loadView 
{
	[super loadView];
	
    
	self.view.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];
	
    
    UIImageView* titleView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"browser-bg.png"]];
    titleView.frame =CGRectMake(0, 0, self.view.bounds.size.width, 48);
    
    [self.view addSubview:titleView];
    [titleView release];
    
    
    UIButton* closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
     
    closeButton.frame =CGRectMake(13, 7, 70, 36);
    
    [closeButton setImage:[UIImage imageNamed:@"close-btn.png"] forState:UIControlStateNormal];
    [closeButton setImage:[UIImage imageNamed:@"close-btn-active.png"] forState:UIControlStateHighlighted];
    [closeButton setImage:[UIImage imageNamed:@"close-btn-active.png"] forState:UIControlStateSelected];

    [self.view addSubview:closeButton];
    
    
    UIButton* shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [shareButton addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    
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
    
	self.textView = [[UITextView alloc] initWithFrame:CGRectMake(20, WEIBO_Y, self.view.bounds.size.width-20, self.view.bounds.size.height-WEIBO_Y)];
        
	textView.delegate = self;
	textView.font = [UIFont systemFontOfSize:20.0f];
    
    NSLog(@"lh = %f",textView.font.lineHeight);
    
    
	textView.contentInset = UIEdgeInsetsMake(0,0,0,0);
	textView.backgroundColor = [UIColor colorWithRed:247/255.0f green:247/255.0f blue:247/255.0f alpha:1.0f];	
    textView.backgroundColor = [UIColor clearColor];
	textView.autoresizesSubviews = YES;
	textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
    
	[self.view addSubview:textView];
    
    if(hasAttachment)
    {
        NSLog(@"has attachment ");
        UIImageView* img =[[UIImageView alloc] initWithImage:self.attachImage];
        
        img.frame =CGRectMake(18, 160, img.frame.size.width, img.frame.size.height);
        if(img.frame.size.width > 504)
            img.frame = CGRectMake(18, 160, 504, img.frame.size.height*504/img.frame.size.width);
        else if(img.frame.size.height > 460)
            img.frame = CGRectMake(18, 160, img.frame.size.width*460/img.frame.size.height, 460);
        
        
        [self.view addSubview:img];
        [img release];
    }    
    
    //add back image
    
    UIImageView* bgView =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"breaking-line.png"]];
    bgView.frame =CGRectMake(0, 48, 540, 571);
    [self.view addSubview:bgView];
    [bgView release];    
    
    
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
	
	[self.textView becomeFirstResponder];
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

//#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)keyboardWillShow:(NSNotification *)notification
{	
	CGRect keyboardFrame;
	CGFloat keyboardHeight;
	
	// 3.2 and above
	/*if (UIKeyboardFrameEndUserInfoKey)
	 {		
	 [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardFrame];		
	 if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationPortrait || [[UIDevice currentDevice] orientation] == UIDeviceOrientationPortraitUpsideDown) 
	 keyboardHeight = keyboardFrame.size.height;
	 else
	 keyboardHeight = keyboardFrame.size.width;
	 }
	 
	 // < 3.2
	 else 
	 {*/
	[[notification.userInfo valueForKey:UIKeyboardBoundsUserInfoKey] getValue:&keyboardFrame];
	keyboardHeight = keyboardFrame.size.height;
	//}
	
	// Find the bottom of the screen (accounting for keyboard overlay)
	// This is pretty much only for pagesheet's on the iPad
	UIInterfaceOrientation orient = [[UIApplication sharedApplication] statusBarOrientation];
	BOOL inLandscape = orient == UIInterfaceOrientationLandscapeLeft || orient == UIInterfaceOrientationLandscapeRight;
	BOOL upsideDown = orient == UIInterfaceOrientationPortraitUpsideDown || orient == UIInterfaceOrientationLandscapeRight;
	
	CGPoint topOfViewPoint = [self.view convertPoint:CGPointZero toView:nil];
	CGFloat topOfView = inLandscape ? topOfViewPoint.x : topOfViewPoint.y;
	
	CGFloat screenHeight = inLandscape ? [[UIScreen mainScreen] applicationFrame].size.width : [[UIScreen mainScreen] applicationFrame].size.height;
	
	CGFloat distFromBottom = screenHeight - ((upsideDown ? screenHeight - topOfView : topOfView ) + self.view.bounds.size.height) + ([UIApplication sharedApplication].statusBarHidden || upsideDown ? 0 : 20);							
	CGFloat maxViewHeight = self.view.bounds.size.height - keyboardHeight + distFromBottom;
	
	//textView.frame = CGRectMake(0,0,self.view.bounds.size.width,maxViewHeight);
    
    textView.frame =CGRectMake(20, WEIBO_Y, self.view.bounds.size.width-20, maxViewHeight-WEIBO_Y);
    
	[self layoutCounter];
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
	if (counter == nil)
	{
		self.counter = [[UILabel alloc] initWithFrame:CGRectZero];
		counter.backgroundColor = [UIColor clearColor];
		counter.opaque = NO;
		counter.font = [UIFont boldSystemFontOfSize:14];
        counter.textAlignment = UITextAlignmentRight;
		
		counter.autoresizesSubviews = YES;
		counter.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		
		[self.view addSubview:counter];
		[self layoutCounter];
		
		[counter release];
	}
	
    //NSLog(@"updating [%@]",self.textView.text);
    
	int count = (hasAttachment?115:140) - [self sinaCountWord:textView.text];
	//counter.text = [NSString stringWithFormat:@"%@%i", hasAttachment ? @"Image + ":@"" , count];
	
    
    
    counter.text = [NSString stringWithFormat:@"还可以输入%i字", count];
    counter.textColor = count >= 0 ? [UIColor colorWithRed:102/255.0f green:102/255.0f blue:102/255.0f alpha:102/255.0f]: [UIColor redColor];
    
}

- (void)layoutCounter
{
	/*counter.frame = CGRectMake(textView.bounds.size.width-150-15,
							   textView.bounds.size.height-15-9,
							   150,
							   15);*/
    
    counter.frame = CGRectMake(textView.bounds.size.width-150-15+18,
							   62,
							   150,
							   15);
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateCounter];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self updateCounter];	
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	[self updateCounter];
}

#pragma mark -

- (void)cancel
{	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void)save
{	
	if ([self sinaCountWord:textView.text] > (hasAttachment?115:140))
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is too long")
									 message:SHKLocalizedString(@"Sina Weibo posts can only be 140 characters in length.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	else if (textView.text.length == 0)
	{
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Message is empty")
									 message:SHKLocalizedString(@"You must enter a message in order to post.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Close")
						   otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	[(SHKSinaWeibo *)delegate sendForm:self];
	
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

@end
