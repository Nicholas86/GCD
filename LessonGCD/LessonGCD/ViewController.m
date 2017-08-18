//
//  ViewController.m
//  LessonGCD
//
//  Created by Frank on 15/8/19.
//  Copyright (c) 2015年 Lanou. All rights reserved.
//

#import "ViewController.h"
#import "SingletonController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
//串行队列 -- 可以实现线程同步 -- 让多个任务顺序执行
- (IBAction)handleSerialQueue:(id)sender {
    //如果是main_queue,则添加的多个任务顺序执行,而且都是在主线程中完成
    //如果是自己创建的串行队列,添加的多个任务依然是顺序执行,只不过任务是在子线程中完成
    //1.获取串行队列 -- 添加多个任务 com.lanou3g.frank 反域名
    //dispatch_queue_t queue1 = dispatch_get_main_queue();
    dispatch_queue_t queue2 = dispatch_queue_create("com.lanou3g.frank", DISPATCH_QUEUE_SERIAL);
    //2.往队列中添加任务
    dispatch_async(queue2, ^{
        NSLog(@"任务1,%@", [NSThread currentThread]);
    });
    dispatch_async(queue2, ^{
        NSLog(@"任务2,%@", [NSThread currentThread]);
    });
    dispatch_async(queue2, ^{
        NSLog(@"任务3,%@", [NSThread currentThread]);
    });
    dispatch_async(queue2, ^{
        NSLog(@"任务4,%@", [NSThread currentThread]);
    });
    dispatch_release(queue2); //释放掉自己创建的队列
}
//并行队列 -- 实现线程并发 -- 多个任务同时执行
- (IBAction)handleConcurrentQueue:(id)sender {
    //1.获取并行队列 01:并行队列优先级 02:预留参数,0
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //2.往队列中添加任务
    dispatch_async(queue, ^{
        NSLog(@"任务1,%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务2,%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务3,%@", [NSThread currentThread]);
    });
    dispatch_async(queue, ^{
        NSLog(@"任务4,%@", [NSThread currentThread]);
        //当前任务在子线程中完成,如果涉及到界面刷新,则由子线程跳转到主线程执行,主界面的执行优先级更高
        dispatch_async(dispatch_get_main_queue(), ^{
            //在主线程中完成
        });
    });
}
//分组任务 -- 将任务分组 -- 并发执行
- (IBAction)handleGroup:(id)sender {
    //1.获取并发队列
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    //2.创建分组
    dispatch_group_t group = dispatch_group_create();
    //3.把任务以分组形式添加到并行队列中.
    dispatch_group_async(group, queue, ^{
        NSLog(@"请求0~10M数据");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"请求10~20M数据");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"请求20~30M数据");
    });
    dispatch_group_async(group, queue, ^{
        NSLog(@"请求30~40M数据");
    });
    //当分组内的任务全部执行结束之后触发
    dispatch_group_notify(group, queue, ^{
        NSLog(@"数据的拼接,得到完整资源");
    });
    dispatch_release(group);
}
//障碍队列 -- 队列中的任务并发执行,但是有一些任务必须要依赖于之前任务结束
- (IBAction)handleBarrier:(id)sender {
    //1.获取并存队列 -- 如果要加障碍任务,必须得是自己创建的队列
    dispatch_queue_t queue = dispatch_queue_create("com.lanou.3g.henan", DISPATCH_QUEUE_CONCURRENT);
    //2.往队列中添加任务
    dispatch_async(queue, ^{
        NSLog(@"任务A写入文件");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务B写入文件");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务C写入文件");
    });
    //在写入和读取之间添加障碍任务,间隔写入和读取
    dispatch_barrier_async(queue, ^{
        NSLog(@"我是障碍任务");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务D读取文件");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务E读取文件");
    });
    dispatch_async(queue, ^{
        NSLog(@"任务F读取文件");
    });
    dispatch_release(queue);

}
//执行一次操作
- (IBAction)handleOnce:(id)sender {
    SingletonController *c1 = [SingletonController sharedController];
    SingletonController *c2 = [SingletonController sharedController];
    NSLog(@"%@,  %@", c1, c2);
}
//反复执行 -- 反复执行多次
- (IBAction)handleApply:(id)sender {
    //01:反复执行的次数 02:在那个队列中执行 03:任务
    dispatch_apply(5, dispatch_queue_create("aa", DISPATCH_QUEUE_SERIAL), ^(size_t index) {
        NSLog(@"执行第%ld次任务", index);
    });
}
//延迟执行 -- 让任务延迟执行
- (IBAction)handleDelay:(id)sender {
    //main_queue是在主线程中执行任务
    //如果想在子线程中完成,需要将队列换成自己创建的串行队列或者并行队列
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"延迟执行的代码");
    });
}





//在GDC中一个操作是多线程执行还是单线程执行取决于当前队列类型和执行方法，只有队列类型为并行队列并且使用异步方法执行时才能在多个线程中执行。
//串行队列可以按顺序执行，并行队列的异步方法无法确定执行顺序。
//UI界面的更新最好采用同步方法，其他操作采用异步方法。
//GCD中多线程操作方法不需要使用@autoreleasepool，GCD会管理内存。

@end










