//
//  UIButton+Block.h
//
//  Created by snaiper on 5/24/12.
//  Copyright (c) 2012 snaiper All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ActionBlock)();

@interface UIButton (Block)

- (void)handleControlEvent:(UIControlEvents)event withBlock:(ActionBlock)block;
- (void)callActionBlock:(id)sender;

@end
