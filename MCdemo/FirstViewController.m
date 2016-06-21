//
//  FirstViewController.m
//  MCdemo
//
//  Created by 赵安 on 16/6/16.
//  Copyright © 2016年 zc. All rights reserved.
//

#import "FirstViewController.h"
#import "AppDelegate.h"
#import "Message.h"
#import "MessageCell.h"
#import "MessageFrame.h"

@interface FirstViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) AppDelegate *appDelegate;

//-(void)sendMyMessage;
-(void)didReceiveDataWithNotification:(NSNotification *)notification;

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
     //设置dataSource
    self.tvChat.dataSource = self;
    
     //设置tcChat的delegate
    self.tvChat.delegate = self;
    
    self.tvChat.separatorStyle = UITableViewCellSeparatorStyleNone;
    // 禁止选中cell
    [self.tvChat setAllowsSelection:NO];
    
    _appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _txtMessage.delegate = self;
    

    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveDataWithNotification:)
                                                 name:@"MCDidReceiveDataNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
}

#pragma mark - dataSource方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return  self.messages.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageCell *cell = [MessageCell cellWithTableView:self.tvChat];
    cell.messageFrame = self.messages[indexPath.row];
    
    return cell;
}

#pragma mark - 数据加载
/** 延迟加载plist文件数据 */
- (NSMutableArray *)messages {
    if (nil == _messages) {
        NSArray *dictArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"messages.plist" ofType:nil]];
        
        NSMutableArray *mdictArray = [NSMutableArray array];
        for (NSDictionary *dict in dictArray) {
            Message *message = [Message messageWithDictionary:dict];
            
            // 判断是否发送时间与上一条信息的发送时间相同，若是则不用显示了
            MessageFrame *lastMessageFrame = [mdictArray lastObject];
            if (lastMessageFrame && [message.time isEqualToString:lastMessageFrame.message.time]) {
                message.hideTime = YES;
            }
            
            MessageFrame *messageFrame = [[MessageFrame alloc] init];
            messageFrame.message = message;
            [mdictArray addObject:messageFrame];
        }
        
        _messages = mdictArray;
    }
    
    return _messages;
}

#pragma mark - tableView代理方法
/** 动态设置每个cell的高度 */
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageFrame *messageFrame = self.messages[indexPath.row];
    return messageFrame.cellHeight;
}

#pragma mark - scrollView 代理方法
/** 点击拖曳聊天区的时候，缩回键盘 */
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // 1.缩回键盘
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//手动移除通知
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 监听方法
/**
 *  键盘工具条处理
 */
- (void)keyboardWillChangeFrame:(NSNotification *)note{
    // 获得键盘
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // 计算键盘移动的范围
    CGFloat transformY = frame.origin.y - [UIScreen mainScreen].bounds.size.height;
    
    CGFloat duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 添加动画
    //transformY += 20;
    [UIView animateWithDuration:duration animations:^{
        self.view.transform = CGAffineTransformMakeTranslation(0, transformY);
    }];
}


#pragma mark - UITextField Delegate method implementation

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self sendMyMessage:textField.text andType:MessageTypeMe];
    return YES;
}


#pragma mark - IBAction method implementation

- (IBAction)sendMessage:(id)sender {
    [self sendMyMessage:_txtMessage.text andType:MessageTypeMe];
}

- (IBAction)cancelMessage:(id)sender {
    [_txtMessage resignFirstResponder];
}


#pragma mark - Private method implementation

-(void)sendMyMessage: (NSString *) text andType:(MessageType) type {
    NSData *dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *allPeers = _appDelegate.mcManager.session.connectedPeers;
    NSError *error;
    
    [_appDelegate.mcManager.session sendData:dataToSend
                                     toPeers:allPeers
                                    withMode:MCSessionSendDataReliable
                                       error:&error];
    
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
//    [_tvChat setText:[_tvChat.text stringByAppendingString:[NSString stringWithFormat:@"I wrote:\n%@\n\n", _txtMessage.text]]];
    // 获取当前时间
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MMM-dd hh:mm:ss";
    NSString *dateStr = [formatter stringFromDate:date];
    
    // 我方发出信息
    NSDictionary *dict = @{@"text":text,
                           @"time":dateStr,
//                           @"name":@"me",
                           @"type":[NSString stringWithFormat:@"%d", type]};
    
    Message *message = [[Message alloc] init];
    [message setValuesForKeysWithDictionary:dict];
    MessageFrame *messageFrame = [[MessageFrame alloc] init];
    messageFrame.message = message;
    
    [self.messages addObject:messageFrame];
    //清空输入框
    [_txtMessage setText:@""];
    [_txtMessage resignFirstResponder];
    [self.tvChat reloadData];
    // 滚动到最新的消息
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tvChat scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
}


-(void)didReceiveDataWithNotification:(NSNotification *)notification{
    MCPeerID *peerID = [[notification userInfo] objectForKey:@"peerID"];
    NSString *peerDisplayName = peerID.displayName;
    
    NSData *receivedData = [[notification userInfo] objectForKey:@"data"];
    NSString *receivedText = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
    
//    [_tvChat performSelectorOnMainThread:@selector(setText:) withObject:[_tvChat.text stringByAppendingString:[NSString stringWithFormat:@"%@ wrote:\n%@\n\n", peerDisplayName, receivedText]] waitUntilDone:NO];
    // 获取当前时间
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MMM-dd hh:mm:ss";
    NSString *dateStr = [formatter stringFromDate:date];
    
    NSDictionary *dict = @{@"text":receivedText,
                           @"time":dateStr,
                           @"name":peerDisplayName,
                           @"type":[NSString stringWithFormat:@"%d", MessageTypeOhter]};
    
    Message *message = [[Message alloc] init];
    [message setValuesForKeysWithDictionary:dict];
    MessageFrame *messageFrame = [[MessageFrame alloc] init];
    messageFrame.message = message;
    
    [self.messages addObject:messageFrame];
    //更新数据
    [self.tvChat reloadData];
    // 滚动到最新的消息
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tvChat scrollToRowAtIndexPath:lastIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    
    UILocalNotification *localNotification=[[UILocalNotification alloc]init];
    localNotification.timeZone=[NSTimeZone defaultTimeZone];
    localNotification.alertBody=[NSString stringWithFormat:@"%@",message];
    localNotification.soundName=UILocalNotificationDefaultSoundName;
    localNotification.applicationIconBadgeNumber++;
    
    [[UIApplication sharedApplication]presentLocalNotificationNow:localNotification];
    [[UIApplication sharedApplication]cancelLocalNotification:localNotification];
}


@end
