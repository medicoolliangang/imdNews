//
//  AppDelegate.h
//  imdNews
//
//  Created by wulg on 3/26/12.
//  Copyright (c) 2012 www.i-md.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "rootViewController.h"

//#define mainURL @"http://www.sina.com.cn"
  //#define mainURL @"http://192.168.1.127:9005"
#define mainURL @"http://www.i-md.com/news/reader#list/Featured"

  //#define mainURL @"http://www.qa.i-md.com/news/reader#list/Featured"
  //#define mainURL @"http://corp.i-md.com:19005/reader"

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    rootViewController* myRootController;
   
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) rootViewController* myRootController;



@end
