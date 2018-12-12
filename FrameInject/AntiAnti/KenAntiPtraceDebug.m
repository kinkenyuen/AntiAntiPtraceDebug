//
//  KenAntiPtraceDebug.m
//  DoubleAntiDebug
//
//  Created by kinken on 2018/12/12.
//  Copyright © 2018 kinkenyuen. All rights reserved.
//

#import "KenAntiPtraceDebug.h"
#import "fishhook.h"
#import "MyPtrace.h"

@implementation KenAntiPtraceDebug
//保存原函数地址
static int (*orig_ptrace)(int , pid_t , caddr_t , int ) = NULL;
static void* (*orig_dlsym)(void * __handle, const char* __symbol);

int my_ptrace(int _request, pid_t _pid, caddr_t _addr, int _data) {
    if (_request != PT_DENY_ATTACH) {
        return orig_ptrace(_request,_pid,_addr,_data);
    }
    NSLog(@"源程序做了反调试----已hook！");
    return 0;
}

void* my_dlsym(void * __handle, const char* __symbol) {
    if (strcmp(__symbol, "ptrace") != 0) {
        //如果不是"ptrace"符号
        return orig_dlsym(__handle,__symbol);
    }
    return my_ptrace;
}

+ (void)load {
    //使用fishhook
    struct rebinding ptraceRebind;
    //需要hook的函数
    ptraceRebind.name = "ptrace";
    //传入替换函数地址
    ptraceRebind.replacement = my_ptrace;
    //保存原函数调用地址
    ptraceRebind.replaced = (void *)&orig_ptrace;
    
    struct rebinding dlsym;
    dlsym.name = "dlsym";
    dlsym.replacement = my_dlsym;
    dlsym.replaced = (void *)&orig_dlsym;
    
    //重新绑定符号表
    rebind_symbols((struct rebinding[2]){ptraceRebind,dlsym}, 2);
}

@end
