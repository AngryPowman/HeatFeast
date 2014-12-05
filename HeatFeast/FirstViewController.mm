//
//  FirstViewController.m
//  HeatFeast
//
//  Created by AngryPowman-Mac on 12/4/14.
//  Copyright (c) 2014 AngryPowman. All rights reserved.
//

#import "FirstViewController.h"
#include <thread>
#include <iostream>
#include <fstream>
#include <vector>
#include <stdlib.h>
#include <sys/sysctl.h>
#include <mach/thread_info.h>
#include <mach/message.h>
#include <mach/task_info.h>
#include <mach/mach_types.h>
#include <mach/mach.h>

@interface FirstViewController ()
@property (strong, nonatomic) IBOutlet UILabel *lblTips;

@end

@implementation FirstViewController

NSTimer *timer;
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

float cpu_usage();
- (IBAction)startHot:(UIButton *)sender {

    
    
    [self start];
}

-(void) TimeElapse:(id)sender
{
    NSString *stringFloat = [NSString stringWithFormat:@"CPU Usage\n%f%%",cpu_usage() * 100];
    _lblTips.text = stringFloat;
}

float cpu_usage()
{
    kern_return_t			kr = {0};
    task_info_data_t		tinfo = {0};
    mach_msg_type_number_t	task_info_count = TASK_INFO_MAX;
    
    kr = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    task_basic_info_t		basic_info = {0};
    thread_array_t			thread_list = {0};
    mach_msg_type_number_t	thread_count = {0};
    
    thread_info_data_t		thinfo = {0};
    thread_basic_info_t		basic_info_th = {0};
    
    basic_info = (task_basic_info_t)tinfo;
    
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (KERN_SUCCESS != kr)
        return 0.0f;
    
    long	tot_sec = 0;
    long	tot_usec = 0;
    float	tot_cpu = 0;
    
    for ( int i = 0; i < thread_count; i++)
    {
        mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
        
        kr = thread_info(thread_list[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (KERN_SUCCESS != kr)
            return 0.0f;
        
        basic_info_th = (thread_basic_info_t)thinfo;
        if (0 == (basic_info_th->flags & TH_FLAGS_IDLE) )
        {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    if (KERN_SUCCESS != kr)
        return 0.0f;
    
    return tot_cpu;
}

const int thread_nums = 100;
std::thread threads_magic[thread_nums];
std::thread threads_cpu_sine[thread_nums];
std::thread threads_mem_alloc[thread_nums];
std::thread mthread;

-(void) start
{
    for (int i = 0; i < thread_nums; ++i)
    {
        threads_magic[i] = std::thread(
                  [&](void* u) -> void
                  {
                      long result = 123456789;
                      while (true)
                      {
                          if (result == 7901234496)
                              result = 123456789;
                          
                          result = result * 2;
                          NSLog(@"result = %ld", result);
                      }
                  }, nullptr);
    }
    
    
    for (int i = 0; i < thread_nums; ++i)
    {
        threads_cpu_sine[i] = std::thread(
                   [&](void* u) -> void
                   {
                       while (true)
                       {
                           struct timeval tv;
                           long long start_time,end_time;
                           long long busy_time[100];
                           long long idle_time[100];
                           int i;
                           for(i = 0; i < 100; i++)
                           {
                               busy_time[i] = 100000 * 0.5 * (sin(i*0.0628) + 1);
                               idle_time[i] = 100000 - busy_time[i];
                           }
                           i = 0;
                           while(1)
                           {
                               gettimeofday(&tv,NULL);
                               start_time = tv.tv_sec * 1000000 + tv.tv_usec;
                               end_time = start_time;
                               
                               while((end_time - start_time) < busy_time[i])
                               {
                                   gettimeofday(&tv,NULL);
                                   end_time = tv.tv_sec * 1000000 + tv.tv_usec;
                               }
                               sleep(idle_time[i]);
                               i = (i+1)%100;
                           }
                       }
                   }, nullptr);
    }
    
    for (int i = 0; i < thread_nums; ++i)
    {
        threads_mem_alloc[i] = std::thread(
                    [&](void* u) -> void
                    {
                        static int size = 1024 * 1024;
                        
                        while (true)
                        {
                            char* chunk = new (std::nothrow)char[size];
                            do
                            {
                                std::ofstream out("./a.out");
                                if (out.is_open() && chunk != nullptr)
                                {
                                    out.write(chunk, size);
                                    out.flush();
                                    out.close();
                                    system("rm -f ./a.out");
                                }
                            } while (0);
                        
                            delete [] chunk;
                        }
                    }, nullptr);
    }
    
    mthread = std::thread(
                        [&](void* u) -> void
                        {
                            timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(TimeElapse:) userInfo:nil repeats:YES];
                            [[NSRunLoop currentRunLoop] run];
                        }, nullptr
                        );
    mthread.join();
    
}

void workerThread(void* userdata)
{
    while (true)
    {
        NSLog(@"NICE JOB!");
    }
}

@end
