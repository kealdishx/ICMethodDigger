//
//  ICIMPBridge.m
//  ICMethodDigger
//
//  Created by kealdish on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICIMPBridge.h"
#import <objc/message.h>
#import <AssertMacros.h>

#import <mach/vm_types.h>
#import <mach/vm_map.h>
#import <mach/mach_init.h>

typedef struct {
	SEL selector;
} ICBridgeBlock;

#if defined(__arm64__)
id ic_forwarding_bridge_page(id, SEL);
// 因为是无参，只有两个参数，id、SEL
typedef int32_t ICForwardingBridgeEntryPointBlock[2];
static const int32_t ICForwardingBridgeInstructionCount = 6;
#else
/// It's fake to pass build.
typedef int32_t ICForwardingBridgeEntryPointBlock[2];
static const int32_t ICForwardingBridgeInstructionCount = 1;
#endif

static const size_t numberOfBridgePerPage = (16384 - ICForwardingBridgeInstructionCount * sizeof(int32_t)) / sizeof(ICForwardingBridgeEntryPointBlock);

typedef struct {

	union {
		struct {
            // 记录 msgsend 指针
			IMP msgSend;
            // 索引表示当前的 bridge 索引
			int32_t nextAvailableIndex;
		};
		int32_t bridgeSize[ICForwardingBridgeInstructionCount];
	};

    // 记录所有转发的 SEL
	ICBridgeBlock bridgeData[numberOfBridgePerPage];

	int32_t bridgeInstructions[ICForwardingBridgeInstructionCount];
    // 转发的 SEL 对应的 IMP 入口
	ICForwardingBridgeEntryPointBlock bridgeEntryPoints[numberOfBridgePerPage];

} ICBridgePage;

static ICBridgePage *ICBridgePageAlloc() {

  #if defined(__arm64__)
  vm_address_t bridgeTemplatePage = (vm_address_t)&ic_forwarding_bridge_page;
  #else
  vm_address_t bridgeTemplatePage = 0;
  #endif

    // 蹦床通常利用可写代码页（即具有可写、可执行权限）来实现。
    // 将指令写入 PROT_EXEC | PROT_WRITE 页面，需要的上下文信息直接包含在生成的代码中。
    // 但是 iOS 中不允许 PROT_EXEC、 PROT_WRITE 这两种权限同时出现在页面中，也就是说不存在可写代码页（在我的测试中，ARMv7是可以的）。
    // 那么就需要使用一种替代机制来是实现 trampoline 中特定的上下文数据以及代码。
    // 这种机制就是 vm_remap() + PC 相对寻址的组合。
    // vm_remap() 函数可以在新的地址中映射现有的代码页，并会同时保留页面保护权限
    // （如果映射范围内的内存权限相同，则返回该权限；如果不同，则返回最大限制值）。
    // 也就是说，我们可以通过 vm_remap() 函数映射可执行的代码页面，或者可写的数据页面到新的页面地址处。
    // PC（程序计数器）寄存器指示当前正在执行的指令的地址。我们将可写的数据页映射到可执行的代码页（trampoline page）旁边，然后使用 PC 相对寻址从相邻的可写数据页面加载 trampoline data，这样就达到了“可写”代码页的目的。
    // 先通过 vm_allocate() 分配两页内存（0x8000），然后通过 vm_deallocate 释放第二页，作为 trampoline page，
    // 调用 vm_remap() 将 ic_forwarding_bridge_page 映射到已释放的第二页，
    // 最后在第一页（可写数据页）中填充需要的数据，返回第二页（可执行代码页）的首地址。
	vm_address_t newBridgePage = 0;
	kern_return_t kernReturn = KERN_SUCCESS;

    // 分配 2 页虚拟内存页
	kernReturn = vm_allocate(mach_task_self(), &newBridgePage, PAGE_SIZE * 2, VM_FLAGS_ANYWHERE);
	NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_allocate failed", kernReturn);

    // 释放虚拟内存第二页
	vm_address_t new_bridge_page = newBridgePage + PAGE_SIZE;
	kernReturn = vm_deallocate(mach_task_self(), new_bridge_page, PAGE_SIZE);
	NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_deallocate failed", kernReturn);

	vm_prot_t cur_protection, max_protection;
	kernReturn = vm_remap(mach_task_self(), &new_bridge_page, PAGE_SIZE, 0, 0, mach_task_self(), bridgeTemplatePage, FALSE, &cur_protection, &max_protection, VM_INHERIT_SHARE);
	NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_remap failed", kernReturn);

	return (void *)newBridgePage;
}

static ICBridgePage *nextBridgePage() {
    // 在很多时候，我们并不能直接执行我们想要的代码，而需要一个跳转代码或者跳转页面，
    // 经过一次或多次的跳转，最后跳到目的代码处执行。生成的这个跳转的代码或者页面就称之为 trampoline。
	static NSMutableArray *normalTrampolinePages = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		normalTrampolinePages = [NSMutableArray array];
	});

	NSMutableArray *thisArray = normalTrampolinePages;

	ICBridgePage *bridgePage = [thisArray.lastObject pointerValue];

    // 没有内存页，则申请
	if (!bridgePage) {
		bridgePage = ICBridgePageAlloc();
		[thisArray addObject:[NSValue valueWithPointer:bridgePage]];
	}

    // 桥的数目已满，则申请新的内存页
	if (bridgePage->nextAvailableIndex == numberOfBridgePerPage) {
		bridgePage = ICBridgePageAlloc();
		[thisArray addObject:[NSValue valueWithPointer:bridgePage]];
	}

	bridgePage->msgSend = objc_msgSend;
	return bridgePage;
}

// 返回 sel 对应的桥上的 IMP
IMP imp_selector_bridge(SEL forwardingSelector) {

	ICBridgePage *dataPageLayout = nextBridgePage();

	int32_t nextAvailableIndex = dataPageLayout->nextAvailableIndex;

	dataPageLayout->bridgeData[nextAvailableIndex].selector = forwardingSelector;

	IMP implementation = (IMP)&dataPageLayout->bridgeEntryPoints[nextAvailableIndex];

	return implementation;

}
