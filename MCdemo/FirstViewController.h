//
//  FirstViewController.h
//  MCdemo
//
//  Created by 赵安 on 16/6/16.
//  Copyright © 2016年 zc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtMessage;
@property (weak, nonatomic) IBOutlet UITextView *tvChat;


- (IBAction)sendMessage:(id)sender;
- (IBAction)cancelMessage:(id)sender;
- (IBAction)clearMessage:(id)sender;


@end
