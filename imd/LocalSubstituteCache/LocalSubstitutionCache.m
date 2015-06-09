//
//  LocalSubstitutionCache.m
//  LocalSubstitutionCache
//
//  Created by Matt Gallagher on 2010/09/06.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "LocalSubstitutionCache.h"
#import "AppDelegate.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation LocalSubstitutionCache

- (NSString *)mimeTypeForPath:(NSString *)originalPath
{
	//
	// Current code only substitutes PNG images
	//
    //return @"image/png";
    //return @"text/html";
    
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)[originalPath pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI,kUTTagClassMIMEType);
    CFRelease(UTI);
    
    //NSLog(@"mime type %@",(NSString*)MIMEType);
    if(MIMEType == nil)
        return @"text/html";
        
    return [(NSString *)MIMEType autorelease];
    
    //if(mimeType == nil)
    //    return @"text/html";
    
    //return mimeType;
    	
}


- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    // Get the path for the request
	NSString *pathString = [[request URL] absoluteString];
    //check http://192.168.1.164:9005/assets/images/common/fav-blank.png
    
    //NSLog(@"path string %@",pathString);
    
    
   
    
    BOOL bypassCaching =NO;
    
    NSRange ignoringRequestRange = [[pathString lowercaseString] rangeOfString:@"file:"];
    
    
    if(ignoringRequestRange.location != NSNotFound)
    {
        bypassCaching =YES;
    }
    
    BOOL containCheckingURL =NO;
    
    
    if([[pathString lowercaseString] isEqualToString:mainURL])
    {
        //NSLog(@"got readers");
        
        NSString *substitutionFilePath =
		[[NSBundle mainBundle]
         pathForResource:[NSString stringWithFormat:@"%@",
                          [[@"reader" stringByDeletingPathExtension] lastPathComponent]]
         ofType:[@"reader" pathExtension] inDirectory:[@"reader" stringByDeletingLastPathComponent]];
        
        NSLog(@"path %@",substitutionFilePath);
        
        NSCachedURLResponse *cachedResponse = [cachedResponses objectForKey:pathString];
        if (cachedResponse)
        {
            //NSLog(@"cached");
            return cachedResponse;
        }
        
        // Load the data	
        NSData *data = [NSData dataWithContentsOfFile:substitutionFilePath];
        
        
        // Create the cacheable response
        NSURLResponse *response =
		[[[NSURLResponse alloc]
          initWithURL:[request URL]
          MIMEType:[self mimeTypeForPath:pathString]
          expectedContentLength:[data length]
          textEncodingName:nil]
         autorelease];
       
        cachedResponse =
		[[[NSCachedURLResponse alloc] initWithResponse:response data:data] autorelease];
        
        
        // Add it to our cache dictionary
        if (!cachedResponses)
        {
            cachedResponses = [[NSMutableDictionary alloc] init];
        }
        [cachedResponses setObject:cachedResponse forKey:pathString];
        
        return cachedResponse;
        
        
        //return [super cachedResponseForRequest:request];
    
    }   
    
    
    
    NSRange checkingRequestRange = [[pathString lowercaseString] rangeOfString:@"http://s.i-md.com/news/assets"];
    
    if(checkingRequestRange.location != NSNotFound)
    {
       containCheckingURL=YES;
    }   
    
    checkingRequestRange = [[pathString lowercaseString] rangeOfString:@"http://www.i-md.com/news/reader/assets"];
    
    if(checkingRequestRange.location != NSNotFound)
    {
        containCheckingURL=YES;
    }   
    
    if(!containCheckingURL)bypassCaching =YES;
    
    if(bypassCaching)
    {
    
        NSCachedURLResponse *cachedResponse = [cachedResponses objectForKey:pathString];
        if (cachedResponse)
        {
            return cachedResponse;
        }
    
    
        return [super cachedResponseForRequest:request];
    } 
    
	
	//NSLog(@"cache request %@",pathString);
	
    //check if we need to replace the request, check if hase key word assets
    //NSRange requestRange = [[pathString lowercaseString] rangeOfString:@"http://s.i-md.com/news/assets"];
    NSRange requestRange = [[pathString lowercaseString] rangeOfString:@"assets"];
    
    NSString* replacingFile;
    if(requestRange.location != NSNotFound)// && [[pathString pathExtension] isEqualToString:@"png"])
    {
        //NSLog(@"found a file");
        replacingFile =[pathString substringFromIndex:requestRange.location];
        //NSLog(@"replace file found %@",replacingFile);
    }    
    else
    {
        return [super cachedResponseForRequest:request];
        
       /*
       requestRange = [[pathString lowercaseString] rangeOfString:@"http://www.i-md.com/news/reader/assets"];
        if(requestRange.location != NSNotFound)// && [[pathString pathExtension] isEqualToString:@"png"])
        {
            //NSLog(@"found a file");
            replacingFile =[pathString substringFromIndex:requestRange.location];
             NSLog(@"replace file found %@",replacingFile);
            
        }   
        else {
            //not we want part
            return [super cachedResponseForRequest:request];
                    
       
        
        } */
        
        
    }
    
    
    
    
    
    // If we've already created a cache entry for this path, then return it.
	NSCachedURLResponse *cachedResponse = [cachedResponses objectForKey:pathString];
	if (cachedResponse)
	{
        //NSLog(@"cached");
		return cachedResponse;
	}
    
    /*NSLog(@"file name %@",[NSString stringWithFormat:@"%@",
                           [[replacingFile stringByDeletingPathExtension] lastPathComponent]]);*/
    //NSLog(@"in dict %@",[replacingFile stringByDeletingLastPathComponent]);
	
    // Get the path to the substitution file
	NSString *substitutionFilePath =
		[[NSBundle mainBundle]
			pathForResource:[NSString stringWithFormat:@"%@",
        [[replacingFile stringByDeletingPathExtension] lastPathComponent]]
			ofType:[replacingFile pathExtension] inDirectory:[replacingFile stringByDeletingLastPathComponent]];
	
    
    /*NSString *substitutionFilePath =
    [[NSBundle mainBundle]
     pathForResource:[NSString stringWithFormat:@"%@",
                      [[replacingFile stringByDeletingPathExtension] lastPathComponent]]
     ofType:[replacingFile pathExtension] inDirectory:@"assets"];*/
	
    
    //NSLog(@"substitueFiltPath %@",substitutionFilePath);
    
    //check if local file exitst, if not back to normal remote request
    if(![[NSFileManager defaultManager] fileExistsAtPath:substitutionFilePath])
    {
        NSLog(@"not found local file %@,return",substitutionFilePath);
        return [super cachedResponseForRequest:request];
    } 

	// Load the data	
	NSData *data = [NSData dataWithContentsOfFile:substitutionFilePath];
	

	// Create the cacheable response
	NSURLResponse *response =
		[[[NSURLResponse alloc]
			initWithURL:[request URL]
			MIMEType:[self mimeTypeForPath:pathString]
			expectedContentLength:[data length]
			textEncodingName:nil]
		autorelease];
	cachedResponse =
		[[[NSCachedURLResponse alloc] initWithResponse:response data:data] autorelease];
	
	
	// Add it to our cache dictionary
	if (!cachedResponses)
	{
		cachedResponses = [[NSMutableDictionary alloc] init];
	}
	[cachedResponses setObject:cachedResponse forKey:pathString];
	
	return cachedResponse;
}


- (void)removeCachedResponseForRequest:(NSURLRequest *)request
{
	//
	// Get the path for the request
	//
	NSString *pathString = [[request URL] path];
	if ([cachedResponses objectForKey:pathString])
	{
		[cachedResponses removeObjectForKey:pathString];
	}
	else
	{
		[super removeCachedResponseForRequest:request];
	}
}

- (void)dealloc
{
	[cachedResponses release];
	cachedResponses = nil;
	[super dealloc];
}

@end
