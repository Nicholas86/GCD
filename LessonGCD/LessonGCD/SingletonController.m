//
//  SingletonController.m
//  LessonGCD
//
//  Created by lanouhn on 15/8/19.
//  Copyright (c) 2015年 Lanou. All rights reserved.
//

#import "SingletonController.h"

@interface SingletonController ()

@end

@implementation SingletonController
+ (id)sharedController {
    //为了保证多线程访问获取到同一个对象,加同步锁
    /*
    @synchronized(self) {
        static SingletonController *ton = nil;
        if (ton == nil) {
            ton = [[self alloc] init];
        }
        return ton;
    }
     */
    //使用GCD方式创建单例
    static SingletonController *ton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ton = [[self alloc] init];
    });
    return ton;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
