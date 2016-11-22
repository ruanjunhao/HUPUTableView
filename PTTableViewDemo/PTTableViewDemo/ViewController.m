//
//  ViewController.m
//  PTTableViewDemo
//
//  Created by joey on 16/10/29.
//  Copyright © 2016年 com.joey. All rights reserved.
//
#define SW [[UIScreen mainScreen]bounds].size.width
#define SH [[UIScreen mainScreen]bounds].size.height
#define maxoffset currentTable.contentSize.height - SH

#import "ViewController.h"
#import "BackView.h"

typedef NS_ENUM(NSUInteger, TurnPageDirection) {
    TurnPageDirectionUp,
    TurnPageDirectionDown,
};

@interface ViewController ()<UITableViewDelegate,
                             UITableViewDataSource>

@property (nonatomic ,strong) UITableView *oddTable;

@property (nonatomic ,strong) UITableView *evenTable;

@property (nonatomic, strong) BackView *backView;

@property (nonatomic, strong) NSMutableArray *data;

@end

@implementation ViewController{
    
    UITableView *currentTable,*lastTable;
    int pageIndex;
    CGPoint lastDistance;
    TurnPageDirection turnDirection;
}

#pragma mark 懒加载
-(BackView*)backView{
    
    if (!_backView) {
        _backView=[[BackView alloc]initWithFrame:self.view.bounds];
    }
    return _backView;
}

-(NSMutableArray *)data{
    if (_data == nil) {
       
        _data=[NSMutableArray new];
        for (int i = 0; i < 50; i++) {
            NSString *str = [NSString stringWithFormat:@"cww%d",arc4random_uniform(100)];
            [_data addObject:str];
        }
    }
    return _data;
}

-(UITableView *)oddTable{
    
    if (!_oddTable) {
        
        _oddTable = [[UITableView alloc]initWithFrame:self.view.bounds];
        _oddTable.delegate=self;
        _oddTable.dataSource=self;
        [_oddTable.panGestureRecognizer addTarget:self action:@selector(pan:)];
    }
    return _oddTable;
}

-(UITableView *)evenTable{
    
    if (!_evenTable) {
        
        _evenTable = [[UITableView alloc]initWithFrame:self.view.bounds];
        _evenTable.delegate=self;
        _evenTable.dataSource=self;
        [_evenTable.panGestureRecognizer addTarget:self action:@selector(pan:)];
    }
    return _evenTable;
}


#pragma mark TableView-Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 20;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *ID = @"id";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
    }
    cell.textLabel.text = self.data[indexPath.row];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return 100;
}
#pragma mark TurnPage

/*
 
 1.找到tableview开始发生位移的关键点，当tableview的偏移量大于0并且小于最大偏移量时说明tableview
 在正常滚动，不做操作，只记录下手势移动的translation以在后面手动推回时判断是否推到了起点
 
 2.panGesture的translation是有误差，所以可能导致结果有偏差我们必须找到这些关键点加以限制
 以免误差的出现
 
 3.翻页后要调整好两个tableview和BackView直接的层级顺序
*/

-(void)pan:(UIPanGestureRecognizer *)sender{

//如果在下拉的过程中,去滚动了lastTableview,则返回,以免影响当前的操作
    if (sender.view != currentTable) return;
    
    CGPoint moveDistance=[sender translationInView:self.view];
    
//在上拉手动推回速度过大时可能导致，translation变成正数而导致tableview的y变为负的，即下方有空出部分
    if (currentTable.frame.origin.y > 0) {
        
        [currentTable setFrame:self.view.bounds];
    }
    
//同样在下拉推回时也可能导致lastTable的y大于-SH，即并没有完全上去，上方有空出部分
    if (lastTable.frame.origin.y > 0) {
        
        [lastTable setFrame:self.view.bounds];
    }
    
//如果当前tableview.y为负，当前tableview必须一直保持最大偏移量
    if(currentTable.frame.origin.y < 0){
        
        [currentTable setContentOffset:CGPointMake(0, maxoffset)];
    }
    
//如果上一个tableview处于移动状态，当前tableview必须保持0偏移
    if ((lastTable.frame.origin.y < 0)&&(lastTable.frame.origin.y > -SH)) {
        
        [currentTable setContentOffset:CGPointZero];
    }


#pragma mark 开始操作
/*
    1.正常滚动，记录下正常滚动时手势的translation
    2.假如正常滚动到底部后再开始拖动位移,那么必须将记录置为0，
      因为此时再移动并不会触发1中的赋值操作，那么第一下移动会是跳动
*/
    if (currentTable.contentOffset.y<maxoffset&&currentTable.contentOffset.y>0) {
        
        lastDistance=moveDistance;
        if (sender.state == UIGestureRecognizerStateEnded) {
            lastDistance = CGPointZero;
            moveDistance = CGPointZero;
        }
    }
//开始翻页
    else{
        
//手动推回分为上拉推回和下拉推回，两者需要分开判定
        if (moveDistance.y-lastDistance.y >= 0&&turnDirection == TurnPageDirectionUp) {
            
            self.backView.alpha = 1;
            [currentTable setFrame:CGRectMake(0, 0, SW, SH)];
        }else if((moveDistance.y-lastDistance.y <=0)&&turnDirection == TurnPageDirectionDown){
            
            self.backView.alpha = 0;
            [lastTable setFrame:CGRectMake(0, -SH, SW, SH)];
        }
        
/*
    1.开始上拉翻页，首先，需要设置好lasttable和backView以及currentTable的层级
    2.在手松开时根据currentTable的y判定是否翻页
*/
        if (currentTable.contentOffset.y>=maxoffset&&moveDistance.y<0) {
            
            [lastTable setFrame:self.view.bounds];
            [self.view insertSubview:lastTable atIndex:self.view.subviews.count-3];
            [self.view insertSubview:self.backView atIndex:self.view.subviews.count-2];
            [lastTable setContentOffset:CGPointZero];
            turnDirection = TurnPageDirectionUp;
            [currentTable setContentOffset:CGPointMake(0, maxoffset)];
            [self.backView.footerLabel setText:[NSString stringWithFormat:@"上翻至第%d页",pageIndex+1]];
            [currentTable setFrame:CGRectMake(0,moveDistance.y-lastDistance.y, SW, SH)];
            [self.backView setAlpha:(currentTable.frame.origin.y+SH)/SH];
            if (sender.state==UIGestureRecognizerStateEnded) {
                
                lastDistance = CGPointZero;
                if (currentTable.frame.origin.y<-100) {
                    [UIView animateWithDuration:0.5*(currentTable.frame.origin.y+SH)/SH animations:^{
                        [currentTable setFrame:CGRectMake(0,-SH , SW, SH)];
                    }completion:^(BOOL finished) {
                        
                        [self.backView setAlpha:(currentTable.frame.origin.y+SH)/SH];
                        pageIndex++;
                        lastTable=currentTable;
                        currentTable=[self tableWithIndex:pageIndex];
                        return ;
                    }];
                }else{
                    [UIView animateWithDuration:-(currentTable.frame.origin.y)/SH*0.5 animations:^{
                        [self.backView setAlpha:(currentTable.frame.origin.y+SH)/SH];
                        [currentTable setFrame:CGRectMake(0,0 , SW, SH)];
                    }completion:^(BOOL finished) {
                        
                    }];
                }
            }
        }

/*
    1.开始下拉翻页，首先，需要设置好lasttable和backView以及currentTable的层级
    2.如果是首页，则返回
    3.在手松开时根据lastTable的y判定是否翻页

*/
        else if(currentTable.contentOffset.y <= 0&&moveDistance.y >= 0){
           
            [lastTable setFrame:CGRectMake(0, -SH, SW, SH)];
            [self.view insertSubview:lastTable atIndex:self.view.subviews.count-1];
            [self.view insertSubview:self.backView atIndex:self.view.subviews.count-2];
            if (pageIndex == 1)  return;
            
            turnDirection = TurnPageDirectionDown;
            
            [currentTable setContentOffset:CGPointMake(0, 0)];
            [lastTable setFrame:CGRectMake(0,moveDistance.y-SH-lastDistance.y, SW, SH)];
            [self.backView setAlpha:(lastTable.frame.origin.y+SH)/SH];
            [_backView.footerLabel setText:[NSString stringWithFormat:@"下翻至第%d页",pageIndex-1]];
            if (sender.state == UIGestureRecognizerStateEnded) {
                lastDistance = CGPointZero;
                if (lastTable.frame.origin.y > 100-SH) {
                    
                    [UIView animateWithDuration:0.5*(-lastTable.frame.origin.y)/SH animations:^{
                        [lastTable setFrame:CGRectMake(0,0, SW, SH)];
                    }completion:^(BOOL finished) {
                        
                        [self.backView setAlpha:currentTable.frame.origin.y/SH];
                        pageIndex--;
                        lastTable = currentTable;
                        currentTable = [self tableWithIndex:pageIndex];
                        return ;
                    }];
                }else{
                    [UIView animateWithDuration:(SH+currentTable.frame.origin.y)/SH*0.5 animations:^{
                        
                        [self.backView setAlpha:currentTable.frame.origin.y/SH];
                        [lastTable setFrame:CGRectMake(0,-SH, SW, SH)];
                    }completion:^(BOOL finished) {
                      
                        [lastTable setFrame:CGRectMake(0, 0, SW, SH)];
                        [self.view insertSubview:lastTable atIndex:self.view.subviews.count - 3];
                        return ;
                    }];
                }
            }
        }
    }
}


- (UITableView*)tableWithIndex:(int)index{
    if (index%2 == 0) {
        return self.evenTable;
    }
    return self.oddTable;
    
}

#pragma mark life-recycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    pageIndex = 1;
    [self.view addSubview:self.evenTable];
    [self.view addSubview:self.backView];
    [self.view addSubview:self.oddTable];
    currentTable=self.oddTable;
}

@end
