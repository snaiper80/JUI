//
//  NLJsonedUIFactory.h
//
//  Created by snaiper on 5/24/12.
//  Copyright (c) 2012 snaiper All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JUIFactory : NSObject

// load from ui script
- (BOOL)load:(NSString *)aFilePath;

// make view
- (UIView *)view;

@end
