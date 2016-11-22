//
//  BackView.m
//  123cw
//
//  Created by 曹文文 on 16/9/15.
//  Copyright © 2016年 com.joey. All rights reserved.
//

#import "BackView.h"
@interface BackView()
@end
@implementation BackView
-(id)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
     
        [self setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:1]];
        _footerLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,[[UIScreen mainScreen]bounds].size.height -50, [[UIScreen mainScreen]bounds].size.width, 40)];
        [_footerLabel setTextColor:[UIColor whiteColor]];
        [_footerLabel setTextAlignment:NSTextAlignmentCenter];
        self.userInteractionEnabled = YES;
        [self addSubview:_footerLabel];
    }
    return self;

}
-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    return NO;
}
@end
