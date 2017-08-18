//
//  AppDelegate.m
//  LessonThread
//
//  Created by lanouhn on 15/8/19.
//  Copyright (c) 2015年 LiYang. All rights reserved.
//

#import "AppDelegate.h"
#define kURL @"http://image.hnol.net/c/2015-08/19/11/201508191111283581-4217076.jpg"
/*
 程序:安装在移动设备上每一个应用,都是一个程序(应用)
 进程:正在运行的程序,叫做进程,每一个进程相当于一个任务
 线程:执行任务的单元片段叫做线程,系统默认每一个进程执行时只开辟一个线程来执行任务,这个线程叫做主线程
 
 线程并发:队列中的任务按照FIFO原则分配子线程,但是一旦任务都分配了子线程之后,多个任务同时执行,最晚分配线程的任务可能最早执行完. -- 适用于多个任务之间没有依赖关系
 线程同步:队列中的任务存在先后依赖关系,后一个任务的开始要依赖于前一个任务的结束.
 
 线程互斥:当多个线程在访问临界资源时.一个线程在访问时,其他线程应处于等待状态.加锁 -- 解锁
 线程死锁:如果资源缺少解锁过程,就容易形成线程死锁,其他线程一直等待释放资源,而资源始终无法释放
 */
@interface AppDelegate ()
{
NSUInteger _totalTickets; //存储票数
}
@property (retain, nonatomic) NSLock *lock;
@end

@implementation AppDelegate

- (void)sellTickets:(NSString *)name {
    @autoreleasepool {
        while (YES) {
            [self.lock lock];//加锁
            if (_totalTickets > 0) {
                _totalTickets--;
                NSLog(@"%@卖了, 剩余%ld张票", name, _totalTickets);
            } else {
                NSLog(@"%@发现票已经卖完了", name);
                break;
            }
            [self.lock unlock]; //解锁
        }
    }
}
- (void)dealloc {
    [_lock release];
    [_window release];
    [super dealloc];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _totalTickets = 20; //初始化票数
    //创建锁对象
    self.lock = [[[NSLock alloc] init] autorelease];
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    //打印执行当前任务的线程,以及是否是主线程
    NSLog(@"%@ %d", [NSThread currentThread], [[NSThread currentThread] isMainThread]);
    //将耗时操作交由子线程处理,而主线程依然处理界面显示和用户交互
    
    //1.创建子线程的第一种方式 -- NSThread -- 自动执行任务
    [NSThread detachNewThreadSelector:@selector(test1) toTarget:self withObject:nil];
    //2.创建子线程的第二种方式 -- NSThread -- 手动执行任务
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(test1) object:nil];
    [thread start]; //开启线程
    [thread release];
    
    //3.创建子线程的第三种方式 -- 使用NSObject分类提供的创建子线程的方法
    //让子线程去执行startTimer任务
    [self performSelectorInBackground:@selector(startTimer) withObject:nil];
    
    [self performSelectorInBackground:@selector(downloadImage) withObject:nil];
     
    //4.创建多个任务对象,添加到任务队列中,由任务队列分配子线程执行任务.
    NSInvocationOperation *op1 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(test3) object:nil];
    NSInvocationOperation *op2 = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(test4) object:nil];
    //创建任务队列对象 -- 存储多个任务 -- 合理安排子线程
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    //实现线程同步的第一种方式 -- 设置线程最大并发数
    //[queue setMaxConcurrentOperationCount:1]; //任务分配有先后顺序只有一个线程去执行
    //实现线程同步的第二种方法 -- 任务之间添加依赖关系 -- 添加依赖一定要在将任务添加到队列中之前
    [op2 addDependency:op1];
    [queue addOperation:op1];
    [queue addOperation:op2];
    [op1 release];
    [op2 release];
    [queue release];
     
    //开启两个子线程,模拟两个售票窗口
    [NSThread detachNewThreadSelector:@selector(sellTickets:) toTarget:self withObject:@"鸿博"];
    [NSThread detachNewThreadSelector:@selector(sellTickets:) toTarget:self withObject:@"龙飞"];
     
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(30, 200, 300, 300)];
    imageView.tag = 100;
    imageView.backgroundColor = [UIColor orangeColor];
    [self.window addSubview:imageView];
    [imageView release];
    
    self.window.backgroundColor = [UIColor yellowColor];
    
    [self.window makeKeyAndVisible];
    return YES;
}
/*
 子线程的问题:
 1.子线程中没有自动释放池.需要在子线程执行的任务中手动添加自动释放池
 2.子线程没有权利去刷新界面,刷新界面的操作全部由主线程完成
 3.子线程中没有开启事件循环,无法实时进行更新操作
 
 主线程和子线程的跳转:
 1.从主线程跳转到子线程:直接使用创建子线程的方式
 2.如何从子线程跳转到主线程执行任务,使用performSelectorOnMainThread:跳转回主线程
 
 */
//子线程执行下载图片
- (void)downloadImage {
    @autoreleasepool {
        NSURL *url = [NSURL URLWithString:kURL];
        NSData *data = [NSData dataWithContentsOfURL:url];
        UIImage *image = [UIImage imageWithData:data];
        //当前任务是由子线程完成,但是请求到图片之后,对于图片的显示,界面的刷新要交给主线程完成
        //从子线程跳转到主线程中执行任务
        [self performSelectorOnMainThread:@selector(refreshUI:) withObject:image waitUntilDone:YES];
    }
}
//子线程中执行定时器
- (void)startTimer {
    @autoreleasepool {
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(test2) userInfo:nil repeats:YES];
        //开启事件循环 -- 及时处理事件
        [[NSRunLoop currentRunLoop] run];
    }
}
- (void)test1 {
    NSLog(@"test1:%@ %d", [NSThread currentThread], [[NSThread currentThread] isMainThread]);
    for (long i = 0; i < 100; i++) {
        NSLog(@"%ld", i);
    }
}
- (void)test2 {
    NSLog(@"蓝鸥");
}
//子线程执行 -- 打印20遍lanou
- (void)test3 {
    @autoreleasepool {
        NSLog(@"test3:%@", [NSThread currentThread]);
        for (int i = 0; i < 20; i++) {
            NSLog(@"lanou");
        }
    }
}
//子线程执行 -- 打印5遍henan
- (void)test4 {
    @autoreleasepool {
        NSLog(@"test4:%@", [NSThread currentThread]);
        for (int i = 0; i < 5; i++) {
            NSLog(@"henan");
        }
    }
}
//刷新界面 -- 显示图片 -- 主线程完成
- (void)refreshUI:(UIImage *)image {
    NSLog(@"refreshUI:%@ %d", [NSThread currentThread], [[NSThread currentThread] isMainThread]);
    UIImageView *newImageView = (UIImageView *)[self.window viewWithTag:100];
    newImageView.image = image;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end







