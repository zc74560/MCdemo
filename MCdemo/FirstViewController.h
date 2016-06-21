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
@property (weak, nonatomic) IBOutlet UITableView *tvChat;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottom;
@property (weak, nonatomic) IBOutlet UIView *inputView;
/** 信息记录数据 */
@property(nonatomic, strong) NSMutableArray *messages;


- (IBAction)sendMessage:(id)sender;
- (IBAction)cancelMessage:(id)sender;


@end
