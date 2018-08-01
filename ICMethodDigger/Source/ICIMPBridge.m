//
//  ICIMPBridge.m
//  ICMethodDigger
//
//  Created by zakariyyasv on 2018/7/30.
//  Copyright © 2018年 Lingyue. All rights reserved.
//

#import "ICIMPBridge.h"
#import <objc/message.h>
#import <AssertMacros.h>

#import <mach/vm_types.h>
#import <mach/vm_map.h>
#import <mach/mach_init.h>

id ic_forwarding_bridge_page(id, SEL);

typedef struct {
	SEL selector;
} ICBridgeBlock;

#if defined(__arm64__)
typedef int32_t ICForwardingBridgeEntryPointBlock[2];
static const int32_t ICForwardingBridgeInstructionCount = 6;
#else
/// It's fake.
typedef int32_t ICForwardingBridgeEntryPointBlock[2];
static const int32_t ICForwardingBridgeInstructionCount = 1;
#endif

static const size_t numberOfBridgePerPage = (16384 - ICForwardingBridgeInstructionCount * sizeof(int32_t)) / sizeof(ICForwardingBridgeEntryPointBlock);

typedef struct {

	union {
		struct {
			IMP msgSend;
			int32_t nextAvailableIndex;
		};
		int32_t bridgeSize[ICForwardingBridgeInstructionCount];
	};

	ICBridgeBlock bridgeData[numberOfBridgePerPage];

	int32_t bridgeInstructions[ICForwardingBridgeInstructionCount];
	ICForwardingBridgeEntryPointBlock bridgeEntryPoints[numberOfBridgePerPage];

} ICBridgePage;

static ICBridgePage *ICBridgePageAlloc() {

	vm_address_t bridgeTemplatePage = (vm_address_t)&ic_forwarding_bridge_page;

	vm_address_t newBridgePage = 0;
	kern_return_t kernReturn = KERN_SUCCESS;

	kernReturn = vm_allocate(mach_task_self(), &newBridgePage, PAGE_SIZE * 2, VM_FLAGS_ANYWHERE);
	NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_allocate failed", kernReturn);

	vm_address_t new_bridge_page = newBridgePage + PAGE_SIZE;
	kernReturn = vm_deallocate(mach_task_self(), new_bridge_page, PAGE_SIZE);
	NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_deallocate failed", kernReturn);

	vm_prot_t cur_protection, max_protection;
	kernReturn = vm_remap(mach_task_self(), &new_bridge_page, PAGE_SIZE, 0, 0, mach_task_self(), bridgeTemplatePage, FALSE, &cur_protection, &max_protection, VM_INHERIT_SHARE);
	NSCAssert1(kernReturn == KERN_SUCCESS, @"vm_remap failed", kernReturn);

	return (void *)newBridgePage;
}

static ICBridgePage *nextBridgePage() {

	static NSMutableArray *normalTrampolinePages = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		normalTrampolinePages = [NSMutableArray array];
	});

	NSMutableArray *thisArray = normalTrampolinePages;

	ICBridgePage *bridgePage = [thisArray.lastObject pointerValue];

	if (!bridgePage) {
		bridgePage = ICBridgePageAlloc();
		[thisArray addObject:[NSValue valueWithPointer:bridgePage]];
	}

	if (bridgePage->nextAvailableIndex == numberOfBridgePerPage) {
		bridgePage = ICBridgePageAlloc();
		[thisArray addObject:[NSValue valueWithPointer:bridgePage]];
	}

	bridgePage->msgSend = objc_msgSend;
	return bridgePage;
}

IMP imp_selector_bridge(SEL forwardingSelector) {

	ICBridgePage *dataPageLayout = nextBridgePage();

	int32_t nextAvailableIndex = dataPageLayout->nextAvailableIndex;

	dataPageLayout->bridgeData[nextAvailableIndex].selector = forwardingSelector;

	IMP implementation = (IMP)&dataPageLayout->bridgeEntryPoints[nextAvailableIndex];

	return implementation;

}
