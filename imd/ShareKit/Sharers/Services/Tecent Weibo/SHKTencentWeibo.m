//
//  SHKTencentWeibo.m
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

#import "SHKTencentWeibo.h"

#define API_DOMAIN  @"https://open.t.qq.com"

@implementation SHKTencentWeibo

@synthesize xAuth;

- (id)init
{
	if ((self = [super init]))
	{		
        // OAuth
		self.consumerKey = SHKTencentWeiboConsumerKey;		
		self.secretKey = SHKTencentWeiboConsumerSecret;
 		self.authorizeCallbackURL = [NSURL URLWithString:SHKTencentWeiboCallbackUrl];
		
        // xAuth
		self.xAuth = SHKTencentWeiboUseXAuth ? YES : NO;
		
		// You do not need to edit these, they are the same for everyone
        self.authorizeURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/cgi-bin/authorize", API_DOMAIN]];
	    self.requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/cgi-bin/request_token", API_DOMAIN]];
	    self.accessURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/cgi-bin/access_token", API_DOMAIN]];
	}	
	return self;
}

#pragma mark -
#pragma mark Configuration : Service Defination

+ (NSString *)sharerTitle
{
	return @"腾讯微博";
}

+ (BOOL)canShareURL
{
	return YES;
}

+ (BOOL)canShareImage
{
	return YES;
}

+ (BOOL)canShareText
{
	return YES;
}

#pragma mark -
#pragma mark Configuration : Dynamic Enable

- (BOOL)shouldAutoShare
{
	return NO;
}


#pragma mark -
#pragma mark Authorization

- (BOOL)isAuthorized
{		
	return [self restoreAccessToken];
}

- (void)promptAuthorization
{		
	if (xAuth)
		[super authorizationFormShow]; // xAuth process
	
	else
		[super promptAuthorization]; // OAuth process		
}

#pragma mark xAuth

+ (NSString *)authorizationFormCaption
{
	return SHKLocalizedString(@"Create a free account at %@", @"t.qq.com");
}

+ (NSArray *)authorizationFormFields
{
	if ([SHKTencentWeiboUserID isEqualToString:@""])
		return [super authorizationFormFields];
	
    NSString *followMeString = SHKLocalizedString(@"Follow us");
    if ( ! [SHKTencentWeiboScreenName isEqualToString:@""]) {
        followMeString = SHKLocalizedString(@"Follow %@", SHKTencentWeiboScreenName);
    }
    
    return [NSArray arrayWithObjects:
			[SHKFormFieldSettings label:SHKLocalizedString(@"Username") key:@"username" type:SHKFormFieldTypeText start:nil],
			[SHKFormFieldSettings label:SHKLocalizedString(@"Password") key:@"password" type:SHKFormFieldTypePassword start:nil],
			[SHKFormFieldSettings label:followMeString key:@"followMe" type:SHKFormFieldTypeSwitch start:SHKFormFieldSwitchOn],			
			nil];
}

- (void)authorizationFormValidate:(SHKFormController *)form
{
	self.pendingForm = form;
	[self tokenAccess];
}

- (void)tokenAccessModifyRequest:(OAMutableURLRequest *)oRequest
{	
	if (xAuth)
	{
		NSDictionary *formValues = [pendingForm formValues];
		
		OARequestParameter *username = [[[OARequestParameter alloc] initWithName:@"x_auth_username"
                                                                           value:[formValues objectForKey:@"username"]] autorelease];
		
		OARequestParameter *password = [[[OARequestParameter alloc] initWithName:@"x_auth_password"
                                                                           value:[formValues objectForKey:@"password"]] autorelease];
		
		OARequestParameter *mode = [[[OARequestParameter alloc] initWithName:@"x_auth_mode"
                                                                       value:@"client_auth"] autorelease];
		
		[oRequest setParameters:[NSArray arrayWithObjects:username, password, mode, nil]];
	}
    else
    {
        if (pendingAction == SHKPendingRefreshToken)
        {
            if (accessToken.sessionHandle != nil)
                [oRequest setOAuthParameterName:@"oauth_session_handle" withValue:accessToken.sessionHandle];	
        }
        
        else
            [oRequest setOAuthParameterName:@"oauth_verifier" withValue:[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
    }
}

- (void)tokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
	if (xAuth) 
	{
		if (ticket.didSucceed)
		{
			[item setCustomValue:[[pendingForm formValues] objectForKey:@"followMe"] forKey:@"followMe"];
			[pendingForm close];
		}
		
		else
		{
			NSString *response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			
			SHKLog(@"tokenAccessTicket Response Body: %@", response);
			
			[self tokenAccessTicket:ticket didFailWithError:[SHK error:response]];
			return;
		}
	}
    
	[super tokenAccessTicket:ticket didFinishWithData:data];		
}



#pragma mark -
#pragma mark UI Implementation

- (void)show
{
    if (item.shareType == SHKShareTypeURL)
	{
		[self shortenURL];
	}
	
    else if (item.shareType == SHKShareTypeImage)
	{
		[item setCustomValue:item.title forKey:@"status"];
		[self showTencentWeiboForm];
	}
	
	else if (item.shareType == SHKShareTypeText)
	{
		[item setCustomValue:item.text forKey:@"status"];
		[self showTencentWeiboForm];
	}
}

- (void)showTencentWeiboForm
{
    NSLog(@"showing weiboform");
    
	SHKTencentWeiboForm *rootView = [[SHKTencentWeiboForm alloc] initWithNibName:nil bundle:nil];	
	rootView.delegate = self;
	
	// force view to load so we can set textView text
	[rootView view];
	
	rootView.textView.text = [item customValueForKey:@"status"];
	rootView.hasAttachment = item.image != nil;
	
	[self pushViewController:rootView animated:NO];
	
	[[SHK currentHelper] showViewController:self];	

}



- (void)sendForm:(SHKTencentWeiboForm *)form
{	
	[item setCustomValue:form.textView.text forKey:@"status"];
	[self tryToSend];
}

#pragma mark -

#pragma mark -

- (void)shortenURL
{	
	if (![SHK connected])
	{
		[item setCustomValue:[NSString stringWithFormat:@"%@: %@", item.title, [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forKey:@"status"];
		[self showTencentWeiboForm];		
		return;
	}
    
	if (!quiet)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Shortening URL...")];
	
	self.request = [[[SHKRequest alloc] initWithURL:[NSURL URLWithString:[NSMutableString stringWithFormat:@"http://open.t.qq.com/short_url/shorten.json?source=%@&url_long=%@",
																		  SHKTencentWeiboConsumerKey,						  
																		  SHKEncodeURL(item.URL)
																		  ]]
											 params:nil
										   delegate:self
								 isFinishedSelector:@selector(shortenURLFinished:)
											 method:@"GET"
										  autostart:YES] autorelease];
    
    NSLog(@"short url: %@", self.request.url);
    
}

- (void)shortenURLFinished:(SHKRequest *)aRequest
{
	[[SHKActivityIndicator currentIndicator] hide];
    
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"(http://t.cn/(\\w+))"
                                                                      options:NSRegularExpressionCaseInsensitive 
                                                                        error:nil];
    
    NSArray *matches = [regex matchesInString:[aRequest getResult]
                                      options:0
                                        range:NSMakeRange(0, [[aRequest getResult] length])];
    [regex release];
    
    NSString *result = nil;
    for (NSTextCheckingResult *match in matches) 
    {
        NSRange range = [match rangeAtIndex:0];
        result = [[aRequest getResult] substringWithRange:range]; 
    }

	if (result == nil || [NSURL URLWithString:result] == nil)
	{
		// TODO - better error message
		[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Shorten URL Error")
									 message:SHKLocalizedString(@"We could not shorten the URL.")
									delegate:nil
						   cancelButtonTitle:SHKLocalizedString(@"Continue")
						   otherButtonTitles:nil] autorelease] show];
		
		[item setCustomValue:[NSString stringWithFormat:@"%@: %@", item.text ? item.text : item.title, [item.URL.absoluteString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] forKey:@"status"];
	}
	
	else
	{		
		[item setCustomValue:[NSString stringWithFormat:@"%@: %@", item.text ? item.text : item.title, result] forKey:@"status"];
	}
	
	[self showTencentWeiboForm];
}

#pragma mark - Word Count

- (int)TencentCountWord:(NSString*)s

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
#pragma mark Share API Methods

- (BOOL)validate
{
	NSString *status = [item customValueForKey:@"status"];
    return status != nil && status.length > 0 && [self TencentCountWord:status] <= 140;
}

- (BOOL)send
{	
	// Check if we should send follow request too
	if (xAuth && [item customBoolForSwitchKey:@"followMe"])
		[self followMe];	
	
	if (![self validate])
		[self show];
	
	else
	{	
		if (item.shareType == SHKShareTypeImage) {
			[self sendImage];
		} else {
			[self sendStatus];
		}
		
		// Notify delegate
		[self sendDidStart];	
		
		return YES;
	}
	
	return NO;
}

- (void)sendStatus
{
	/*OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/statuses/update.json", API_DOMAIN]]
                                                                    consumer:consumer
                                                                       token:accessToken
                                                                       realm:nil
                                                           signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
	
	OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status"
																		 value:[item customValueForKey:@"status"]];
	NSArray *params = [NSArray arrayWithObjects:statusParam, nil];
	[oRequest setParameters:params];
	[statusParam release];
	
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendStatusTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendStatusTicket:didFailWithError:)];	
    
	[fetcher start];
	[oRequest release];*/
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://open.t.qq.com/api/t/add"]] consumer:consumer token:accessToken realm:nil signatureProvider:nil];
    
    [oRequest setHTTPMethod:@"POST"];
    
    NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableString *body =[NSMutableString stringWithFormat:@""];
    [parameters addObject:[OARequestParameter requestParameterWithName:@"content" value:[item  customValueForKey:@"status"]]];
    [parameters addObject:[OARequestParameter requestParameterWithName:@"format" value:@"json"]];
    
    [parameters addObject:[OARequestParameter requestParameterWithName:@"clientip" value:@"127.0.0.1"]];
    
    [oRequest setParameters:parameters];
    [body appendFormat:@"%@", [oRequest txBaseString]];
    
    [oRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(sendStatusTicket:didFinishWithData:)
                                                                                   didFailSelector:@selector(sendStatusTicket:didFailWithError:)];	
    
	[fetcher start];
	[oRequest release];
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{	
	// TODO better error handling here
    
	if (ticket.didSucceed) 
		[self sendDidFinish];
	
	else
	{		
		if (SHKDebugShowLogs)
        {
            SHKLog(@"Tencent Weibo Send Status Error: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
        }
		
		// CREDIT: Oliver Drobnik
		
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];		
		
		// in case our makeshift parsing does not yield an error message
		NSString *errorMessage = @"Unknown Error";		
		
		NSScanner *scanner = [NSScanner scannerWithString:string];
		
		// skip until error message
		[scanner scanUpToString:@"\"error\":\"" intoString:nil];
		
		
		if ([scanner scanString:@"\"error\":\"" intoString:nil])
		{
			// get the message until the closing double quotes
			[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&errorMessage];
		}
		
		
		// this is the error message for revoked access
		if ([errorMessage isEqualToString:@"Invalid / used nonce"])
		{
			[self sendDidFailShouldRelogin];
		}
		else 
		{
			NSError *error = [NSError errorWithDomain:@"Tencent Weibo" code:2 userInfo:[NSDictionary dictionaryWithObject:errorMessage forKey:NSLocalizedDescriptionKey]];
			[self sendDidFailWithError:error];
		}
	}
}

- (void)sendStatusTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[self sendDidFailWithError:error];
}

- (void)sendImage 
{
	NSMutableString *body =[NSMutableString stringWithFormat:@""];
    OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://open.t.qq.com/api/t/add_pic"]] consumer:consumer token:accessToken realm:nil signatureProvider:nil];
    
    [oRequest setHTTPMethod:@"POST"];
    
    NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:0];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    [dic setValue:[item customValueForKey:@"status"] forKey:@"content"];
    [dic setValue:@"json" forKey:@"format"];
    [dic setValue:@"127.0.0.1" forKey:@"clientip"];
    
    for(NSString *key in [dic allKeys])
    {
        [parameters addObject:[OARequestParameter requestParameterWithName:key value:[dic valueForKey:key]]];
    }
    [oRequest setParameters:parameters];
    [body appendFormat:@"%@", [oRequest txBaseString]];
    NSString *url = [NSString stringWithFormat:@"http://open.t.qq.com/api/t/add_pic?%@",body];
    [oRequest setURL:[NSURL URLWithString:url]];
    
    NSMutableData *postbody = [[NSMutableData alloc] init];
    NSString *param = [self nameValString:dic];
    NSString *footer = [NSString stringWithFormat:@"\r\n--%@--\r\n",BOUNDARY];
    
    param = [param stringByAppendingString:[NSString stringWithFormat:@"--%@\r\n",BOUNDARY]];
    param = [param stringByAppendingString:@"Content-Disposition: form-data; name=\"pic\";filename=\"image.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n"];
    
    CGFloat compression = 0.9f;
    NSData *imageData = UIImageJPEGRepresentation([item image], compression);
    while ([imageData length] > 700000 && compression > 0.1) {
		// NSLog(@"Image size too big, compression more: current data size: %d bytes",[imageData length]);
		compression -= 0.1;
		imageData = UIImageJPEGRepresentation([item image], compression);
	}
    
    [postbody appendData:[param dataUsingEncoding:NSUTF8StringEncoding]];
    [postbody appendData:imageData];
    [postbody appendData:[footer dataUsingEncoding:NSUTF8StringEncoding]];
	
    [oRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", BOUNDARY] forHTTPHeaderField:@"Content-Type"];
    [oRequest setValue:[NSString stringWithFormat:@"%d", [postbody length]] forHTTPHeaderField:@"Content-Length"];
    
    //    NSLog(@"%@",body);
    [oRequest setHTTPBody:postbody];
    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
																						  delegate:self
																				 didFinishSelector:@selector(sendImageTicket:didFinishWithData:)
																				   didFailSelector:@selector(sendImageTicket:didFailWithError:)];	
	
	[fetcher start];
	[oRequest release];
    
}

- (void)sendImageTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data {
	// TODO better error handling here
    SHKLog(@"%@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
    
	// NSLog([[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
	
	if (ticket.didSucceed) {
		[self sendDidFinish];
		// Finished uploading Image, now need to posh the message and url in Tencent weibo
		NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSRange startingRange = [dataString rangeOfString:@"<url>" options:NSCaseInsensitiveSearch];
		//NSLog(@"found start string at %d, len %d",startingRange.location,startingRange.length);
		NSRange endingRange = [dataString rangeOfString:@"</url>" options:NSCaseInsensitiveSearch];
		//NSLog(@"found end string at %d, len %d",endingRange.location,endingRange.length);
		
		if (startingRange.location != NSNotFound && endingRange.location != NSNotFound) {
			NSString *urlString = [dataString substringWithRange:NSMakeRange(startingRange.location + startingRange.length, endingRange.location - (startingRange.location + startingRange.length))];
			//NSLog(@"extracted string: %@",urlString);
			[item setCustomValue:[NSString stringWithFormat:@"%@ %@",[item customValueForKey:@"status"],urlString] forKey:@"status"];
			[self sendStatus];
		}
		
		
	} else {
		[self sendDidFailWithError:nil];
	}
}

- (void)sendImageTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error {
	[self sendDidFailWithError:error];
}


- (void)followMe
{
	// remove it so in case of other failures this doesn't get hit again
	[item setCustomValue:nil forKey:@"followMe"];
    
	OAMutableURLRequest *oRequest = [[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/friendships/create/%@.json", API_DOMAIN, SHKTencentWeiboUserID]]
																	consumer:consumer
																	   token:accessToken
																	   realm:nil
														   signatureProvider:nil];
	
	[oRequest setHTTPMethod:@"POST"];
    
	OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:oRequest
                                                                                          delegate:nil // Currently not doing any error handling here.  If it fails, it's probably best not to bug the user to follow you again.
                                                                                 didFinishSelector:nil
                                                                                   didFailSelector:nil];	
	
	[fetcher start];
	[oRequest release];
}

- (NSString*) nameValString: (NSDictionary*) dict {
	NSArray* keys = [dict allKeys];
	NSString* result = [NSString string];
	int i;
	for (i = 0; i < [keys count]; i++) {
        result = [result stringByAppendingString:
                  [@"--" stringByAppendingString:
                   [BOUNDARY stringByAppendingString:
                    [@"\r\nContent-Disposition: form-data; name=\"" stringByAppendingString:
                     [[keys objectAtIndex: i] stringByAppendingString:
                      [@"\"\r\n\r\n" stringByAppendingString:
                       [[dict valueForKey: [keys objectAtIndex: i]] stringByAppendingString: @"\r\n"]]]]]]];
	}
	
	return result;
}


#pragma mark - Overrewrite parent method
- (void)tokenRequest
{
	[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Connecting...")];
	
    OAHMAC_SHA1SignatureProvider *hmacSha1Provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
    OAMutableURLRequest *oRequest = [[[OAMutableURLRequest alloc] initWithURL:requestURL
                                                                     consumer:consumer
                                                                        token:nil
                                                                        realm:nil
                                                            signatureProvider:hmacSha1Provider
                                                                        nonce:[self _generateNonce]
                                                                    timestamp:[self _generateTimestamp]] autorelease];
    //    [hmacSha1Request setOAuthParameterName:@"oauth_callback" withValue:CallBackURL];
    [oRequest setHTTPMethod:@"POST"];
    [oRequest setParameters:[NSArray arrayWithObject:[OARequestParameter requestParameterWithName:@"oauth_callback" value:SHKTencentWeiboCallbackUrl]]];
    NSString *url = [NSString stringWithFormat:@"%@?oauth_callback=%@&%@",requestURL,[SHKTencentWeiboCallbackUrl URLEncodedString],[oRequest txBaseString]];
    [oRequest setURL:[NSURL URLWithString:url]];
    
    OAAsynchronousDataFetcher *fetcher = [[OAAsynchronousDataFetcher alloc] initWithRequest:oRequest delegate:self didFinishSelector:@selector(txtokenRequestTicket:didFinishWithData:) didFailSelector:@selector(txtokenRequestTicket:didFailWithError:)];
    [fetcher start];
    [fetcher release];
}

- (void)txtokenRequestTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
#if SHKDebugShowLogs // check so we don't have to alloc the string with the data if we aren't logging
    SHKLog(@"tokenRequestTicket Response Body: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
#endif
	
	[[SHKActivityIndicator currentIndicator] hide];
	
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		self.requestToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		
		[self tokenAuthorize];
	}
	
	else
		// TODO - better error handling here
		[self tokenRequestTicket:ticket didFailWithError:[SHK error:SHKLocalizedString(@"There was a problem requesting authorization from %@", [self sharerTitle])]];
}

- (void)txtokenRequestTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[[SHKActivityIndicator currentIndicator] hide];
	
	[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Request Error")
								 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
								delegate:nil
					   cancelButtonTitle:SHKLocalizedString(@"Close")
					   otherButtonTitles:nil] autorelease] show];
}

- (void)tokenAccess:(BOOL)refresh
{
	if (!refresh)
		[[SHKActivityIndicator currentIndicator] displayActivity:SHKLocalizedString(@"Authenticating...")];
	
    NSString *accessStr = [NSString stringWithFormat:@"%@/cgi-bin/access_token?oauth_verifier=%@", API_DOMAIN,[authorizeResponseQueryVars objectForKey:@"oauth_verifier"]];
    OAHMAC_SHA1SignatureProvider *hmacSha1Provider = [[OAHMAC_SHA1SignatureProvider alloc] init];
    OAMutableURLRequest *oRequest = [[[OAMutableURLRequest alloc] initWithURL:[NSURL URLWithString:accessStr]
                                                                     consumer:consumer
                                                                        token:(refresh ? accessToken : requestToken)
                                                                        realm:nil
                                                            signatureProvider:hmacSha1Provider
                                                                        nonce:[self _generateNonce]
                                                                    timestamp:[self _generateTimestamp]] autorelease];
    
    //[self tokenAccessModifyRequest:oRequest];
    NSString *url = [NSString stringWithFormat:@"%@?oauth_verifier=%@&%@",accessURL,[authorizeResponseQueryVars objectForKey:@"oauth_verifier"],[oRequest txBaseString]];
    [oRequest setURL:[NSURL URLWithString:url]];
    
    
    OAAsynchronousDataFetcher *fetcher = [[OAAsynchronousDataFetcher alloc] initWithRequest:oRequest delegate:self didFinishSelector:@selector(txtokenAccessTicket:didFinishWithData:) didFailSelector:@selector(txtokenAccessTicket:didFailWithError:)];
    [fetcher start];
    [fetcher release];
}


- (void)txtokenAccessTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data 
{
#if SHKDebugShowLogs // check so we don't have to alloc the string with the data if we aren't logging
    SHKLog(@"tokenAccessTicket Response Body: %@", [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease]);
#endif
	
	[[SHKActivityIndicator currentIndicator] hide];
	
	if (ticket.didSucceed) 
	{
		NSString *responseBody = [[NSString alloc] initWithData:data
													   encoding:NSUTF8StringEncoding];
		self.accessToken = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
		[responseBody release];
		
		[self storeAccessToken];
		
		[self tryPendingAction];
	}
	
	
	else
		// TODO - better error handling here
		[self tokenAccessTicket:ticket didFailWithError:[SHK error:SHKLocalizedString(@"There was a problem requesting access from %@", [self sharerTitle])]];
}

- (void)txtokenAccessTicket:(OAServiceTicket *)ticket didFailWithError:(NSError*)error
{
	[[SHKActivityIndicator currentIndicator] hide];
	
	[[[[UIAlertView alloc] initWithTitle:SHKLocalizedString(@"Access Error")
								 message:error!=nil?[error localizedDescription]:SHKLocalizedString(@"There was an error while sharing")
								delegate:nil
					   cancelButtonTitle:SHKLocalizedString(@"Close")
					   otherButtonTitles:nil] autorelease] show];
}

#pragma mark 获得时间戳
- (NSString *)_generateTimestamp 
{
    return [NSString stringWithFormat:@"%d", time(NULL)];
}

#pragma mark 获得随时字符串
- (NSString *)_generateNonce 
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    NSMakeCollectable(theUUID);
    return (NSString *)string;
}
- (NSString *)generateNonce
{
    return [NSString stringWithFormat:@"%u", arc4random() % (9999999 - 123400) + 123400];
}


@end
