//
//  UIButton+Block.m
//
//  Created by snaiper on 5/24/12.
//  Copyright (c) 2012 snaiper All rights reserved.
//

#import "UIButton+Block.h"
#import <objc/runtime.h>

static char UIButtonBlockKey;

@implementation UIButton (Block)

- (void)handleControlEvent:(UIControlEvents)event withBlock:(ActionBlock)block 
{
    objc_setAssociatedObject(self, &UIButtonBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [self addTarget:self action:@selector(callActionBlock:) forControlEvents:event];
}

- (void)callActionBlock:(id)sender 
{
    ActionBlock block = (ActionBlock)objc_getAssociatedObject(self, &UIButtonBlockKey);
    if (block != nil)
        block();
}

@end