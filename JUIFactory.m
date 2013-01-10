//
//  NLJsonedUIFactory.m
//
//  Created by snaiper on 5/24/12.
//  Copyright (c) 2012 snaiper All rights reserved.
//

#import "JUIFactory.h"
#import "JSONKit.h"
#import "NSData+Base64.h"
#import "UIButton+Block.h"

// supported type
typedef enum
{
    NLUITypeLabel = 0,
    NLUITypeImageView,
    NLUITypeButton,
    NLUITypeView,
    NLUITypeUnknown,
    
} NLUIType;

typedef enum 
{
    NLResourceTypeImage = 0,
    NLResourceTypeUnknown,
    
} NLResourceType;

enum AutoCenterType
{
    NLAutoCenterTypeNone       = 1 << 0,
    NLAutoCenterTypeHorizontal = 1 << 1,
    NLAutoCenterTypeVertical   = 1 << 2,
};


// define
#define kImageCacheCost                       (1024 * 1024 * 5)
#define kSupportedVersion                     (1)

#define kVersionKey                           @"version"
#define kViewsKey                             @"views"
#define kResoucesKey                          @"resource"

#define kUITypeStringView                     @"view"
#define kUITypeStringLabel                    @"label"
#define kUITypeStringImageView                @"imageview"
#define kUITypeStringButton                   @"button"

#define kResourceTypeStringImage              @"image"

// common
#define kCommonAttributeIDKey                 @"id"
#define kCommonAttributeTypeKey               @"type"
#define kCommonAttributeFrameKey              @"frame"
#define kCommonAttributeBackgroundColorKey    @"backgroundColor"
#define kCommonAttributeChildrenKey           @"children"
#define kCommonAttributeAutoCenterKey         @"autocenter"

#define kAutoCenterTypeHorizontal             @"h"
#define kAutoCenterTypeVertical               @"v"
#define kAutoCenterTypeSeperator              @"|"

// font
#define kDefaultSystemFontSymbolName          @"system"
#define kDefaultBoldSystemFontSymbolName      @"bold-system"

// label
#define kLabelAttributeShadowColorKey         @"shadowColor"
#define kLabelAttributeShadowOffsetKey        @"shadowOffset"
#define kLabelAttributeFontFamilyKey          @"font"
#define kLabelAttributeFontPointSizeKey       @"fontSize"
#define kLabelAttributeTextKey                @"text"
#define kLabelAttributeTextColorKey           @"textColor"
#define kLabelAttributeMultilineKey           @"multiline"
#define kLabelAttributeAlignmentKey           @"align"

// image
#define kImageAttributeImageSourceKey         @"source"

// button
#define kButtonAttributeTitleKey              @"title"
#define kButtonAttributeTitleFontFamilyKey    @"titleFont"
#define kButtonAtrributeTitleFontPointSizeKey @"titleFontSize"
#define kButtonAttributeTitleColor            @"titleColor"
#define kButtonAttributeTitleShadowColorKey   @"titleShadowColor"
#define kButtonAttributeTitleShadowOffsetKey  @"titleShadowOffset"
#define kButtonAttributeBackgroundImageKey    @"backgroundImage"
#define kButtonAttributeActionURIKey          @"action-uri"
#define kButtonAttributeStateNormalKey        @"normal"
#define kButtonAttributeStateHighlightedKey   @"highlighted"

// resource
#define kResourceTypeKey                      @"type"
#define kResourceFileNameKey                  @"filename"
#define kResourcePathNameKey                  @"path"
#define kResourceDataKey                      @"data"
#define kResourceImageStretchedPointKey       @"stretchedPoint"

@interface JUIFactory ()

- (void)initialize;

@end

@implementation JUIFactory {
@private
    NSArray             *mViews;
    NSDictionary        *mResources;
    NSString            *mCurrentLanguage;
    NSCache             *mImageCache;
}

#pragma mark -
#pragma mark Life Cycle

- (id)init
{
    self = [super init];
    if (self != nil)
    {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    // initialize
    mCurrentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    mImageCache      = [[NSCache alloc] init];
    [mImageCache setTotalCostLimit:kImageCacheCost];
}

- (void)reset
{
    mViews     = nil;
    mResources = nil;
    [mImageCache removeAllObjects];
}

#pragma mark -
#pragma mark Conversion

- (NLUIType)uiTypeFromString:(NSString *)aString
{
    aString = [[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    
    if ([aString caseInsensitiveCompare:kUITypeStringLabel] == NSOrderedSame)
        return NLUITypeLabel;
    else if ([aString caseInsensitiveCompare:kUITypeStringImageView] == NSOrderedSame)
        return NLUITypeImageView;
    else if ([aString caseInsensitiveCompare:kUITypeStringButton] == NSOrderedSame)
        return NLUITypeButton;
    else if ([aString caseInsensitiveCompare:kUITypeStringView] == NSOrderedSame)
        return NLUITypeView;
    else
        return NLUITypeUnknown;
}

- (NLResourceType)resourceTypeFromString:(NSString *)aString
{
    aString = [[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    
    if ([aString caseInsensitiveCompare:kResourceTypeStringImage] == NSOrderedSame)
        return NLResourceTypeImage;
    else
        return NLResourceTypeUnknown;
}

- (UITextAlignment)textAlignmentFromString:(NSString *)aString
{
    aString = [[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    
    if ([aString caseInsensitiveCompare:@"center"] == NSOrderedSame)
        return UITextAlignmentCenter;
    else if ([aString caseInsensitiveCompare:@"right"] == NSOrderedSame)
        return UITextAlignmentRight;
    else
        return UITextAlignmentLeft;
}

- (NSInteger)autoCenterTypeFromString:(NSString *)aString
{
    if ([aString length] == 0)
        return NLAutoCenterTypeNone;
    
    aString = [[aString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];
    
    NSInteger sType = 0;
    
    NSArray *sComponents = [aString componentsSeparatedByString:kAutoCenterTypeSeperator];
    for (NSString *sTypeString in sComponents)
    {
        if ([sTypeString isEqualToString:kAutoCenterTypeHorizontal] == YES)
        {
            sType |= NLAutoCenterTypeHorizontal;
        }
        else if ([sTypeString isEqualToString:kAutoCenterTypeVertical] == YES)
        {
            sType |= NLAutoCenterTypeVertical;
        }
        else
        {
            continue;
        }
    }

    return sType;
}

#pragma mark -
#pragma mark Image Cache

- (void)setImage:(UIImage *)anImage forKey:(NSString *)aKey dataSize:(NSUInteger)aDataSize
{
    if (anImage != nil && aKey != nil && aDataSize != 0) 
        [mImageCache setObject:anImage forKey:aKey cost:aDataSize];
}

- (void)removeImageForURL:(NSURL *)aURL
{
    if (aURL != nil) 
        [mImageCache removeObjectForKey:[aURL absoluteString]];
}

- (void)clearImageCache
{
    [mImageCache removeAllObjects];
}

- (UIImage *)imageForKey:(NSString *)aKey
{
    return [mImageCache objectForKey:aKey];
}

#pragma mark -
#pragma mark Parse Logics

- (BOOL)parse:(NSDictionary *)aParsedResult
{
    NSLog(@"%@", aParsedResult);
    
    NSNumber     *sVersion   = [aParsedResult objectForKey:kVersionKey];
    NSArray      *sViews     = [aParsedResult objectForKey:kViewsKey];
    NSDictionary *sResources = [aParsedResult objectForKey:kResoucesKey];
    
    if (sVersion == nil || sViews == nil || sResources == nil)
    {
        NSLog(@"Required attributes is not existed");
        return NO;
    }
    
    if ([sVersion integerValue] > kSupportedVersion)
        return NO;
    
    mViews     = sViews;
    mResources = sResources;
    
    return YES;
}

- (UIColor *)colorFromHTMLStyleString:(NSString *)aColorCode
{
    NSString *sTrimmed = [[aColorCode stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    if ([sTrimmed length] < 6)  
        return [UIColor blackColor];
    
    if ([sTrimmed hasPrefix:@"0X"])
        sTrimmed = [sTrimmed substringFromIndex:2];
    
    if ([sTrimmed hasPrefix:@"#"])
        sTrimmed = [sTrimmed substringFromIndex:1];
    
    if ([sTrimmed length] != 6)
        return [UIColor blackColor];
    
    NSRange sRange;
    sRange.location = 0;
    sRange.length   = 2;
    
    NSString *rcolorString = [sTrimmed substringWithRange:sRange];
    
    sRange.location = 2;
    NSString *gcolorString = [sTrimmed substringWithRange:sRange];
    
    sRange.location = 4;
    NSString *bcolorString = [sTrimmed substringWithRange:sRange];
    
    unsigned int sRed = 0, sGreen = 0, sBlue = 0;
    [[NSScanner scannerWithString:rcolorString] scanHexInt:&sRed];
    [[NSScanner scannerWithString:gcolorString] scanHexInt:&sGreen];
    [[NSScanner scannerWithString:bcolorString] scanHexInt:&sBlue];
    
    return [UIColor colorWithRed:((float) sRed   / 255.0f)
                           green:((float) sGreen / 255.0f)
                            blue:((float) sBlue  / 255.0f)
                           alpha:1.0f];
}

- (NSInteger)tagForControlIDString:(NSString *)aIDString
{
    return [aIDString hash];
}

- (UIFont *)fontWithFontFamilyString:(NSString *)aFontFamily fontSize:(NSNumber *)aFontSize
{
    if ([aFontFamily caseInsensitiveCompare:kDefaultSystemFontSymbolName] == NSOrderedSame)
        return [UIFont systemFontOfSize:[aFontSize floatValue]];
    else if ([aFontFamily caseInsensitiveCompare:kDefaultBoldSystemFontSymbolName] == NSOrderedSame)
        return [UIFont boldSystemFontOfSize:[aFontSize floatValue]];
    else
        return [UIFont fontWithName:aFontFamily size:[aFontSize floatValue]];
}

- (NSString *)textForCurrentLanguage:(NSDictionary *)aTextDictionary
{
    if (aTextDictionary == nil)
        return @"";
    
    NSString *sCurrentLanguageText = [aTextDictionary objectForKey:mCurrentLanguage];
    if (sCurrentLanguageText == nil)
        sCurrentLanguageText = [aTextDictionary objectForKey:@"en"];
    
    if (sCurrentLanguageText != nil)
        return sCurrentLanguageText;
    else 
        return @"";
}

- (UIImage *)imageForResourceIDString:(NSString *)aResourceID
{
    UIImage  *sCachedImage = [self imageForKey:aResourceID];
    if (sCachedImage != nil)
        return sCachedImage;
    
    NSDictionary *sInfo = [mResources objectForKey:aResourceID];
    if (sInfo == nil)
        return nil;
    
    NSString *sType = [sInfo objectForKey:kResourceTypeKey];
    if (sType == nil)
        return nil;
    
    NLResourceType sResourceType = [self resourceTypeFromString:sType];
    if (sResourceType != NLResourceTypeImage)
        return nil;
    
    NSString *sImageDataString = [sInfo objectForKey:kResourceDataKey];
    NSString *sPath            = [sInfo objectForKey:kResourcePathNameKey];
    NSString *sFileName        = [sInfo objectForKey:kResourceFileNameKey];
    NSString *sStrechedPoint   = [sInfo objectForKey:kResourceImageStretchedPointKey];

    UIImage *sImage = nil;
    
    if (sImageDataString != nil)
    {
        sImage = [UIImage imageWithData:[NSData dataWithBase64EncodedString:sImageDataString]];
    }
    else if (sPath != nil)
    {
        NSData *sImageData = nil;
        
        // TODO: do asynchronous
        if ([sPath hasPrefix:@"http://"] == YES || [sPath hasPrefix:@"https://"] == YES)
        {
            sImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:sPath]];
            
        }
        else
        {
            sImageData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:sPath]];
        }
        
        sImage = [UIImage imageWithData:sImageData];
    }
    else
    {
        if ([sFileName length] == 0)
            return nil;
        
        sImage = [UIImage imageNamed:sFileName];
    }
    
    if (sImage == nil)
        return nil;
    
    if (sStrechedPoint != nil)
    {
        CGPoint sPoint = CGPointFromString(sStrechedPoint);
        sImage = [sImage stretchableImageWithLeftCapWidth:sPoint.x topCapHeight:sPoint.y];
    }
    
    NSData *sData = UIImagePNGRepresentation(sImage);
    [self setImage:sImage forKey:aResourceID dataSize:[sData length]];
    
    return sImage;
}

#pragma mark -
#pragma mark making UI Controls

- (UILabel *)labelWithFrame:(CGRect)aFrame attributes:(NSDictionary *)aViewInfo
{
    NSString     *sFontFamily   = [aViewInfo objectForKey:kLabelAttributeFontFamilyKey];
    NSNumber     *sFontSize     = [aViewInfo objectForKey:kLabelAttributeFontPointSizeKey];
    NSDictionary *sText         = [aViewInfo objectForKey:kLabelAttributeTextKey];
    NSString     *sTextColor    = [aViewInfo objectForKey:kLabelAttributeTextColorKey];
    NSString     *sShadowColor  = [aViewInfo objectForKey:kLabelAttributeShadowColorKey];
    NSString     *sShadowOffset = [aViewInfo objectForKey:kLabelAttributeShadowOffsetKey];
    NSNumber     *sMultiline    = [aViewInfo objectForKey:kLabelAttributeMultilineKey];
    NSString     *sAlignment    = [aViewInfo objectForKey:kLabelAttributeAlignmentKey];
    
    UILabel *sLabel = [[UILabel alloc] initWithFrame:aFrame];
    [sLabel setFont:[self fontWithFontFamilyString:sFontFamily fontSize:sFontSize]];
    [sLabel setTextColor:[self colorFromHTMLStyleString:sTextColor]];
    
    if (sAlignment != nil)
    {
        [sLabel setTextAlignment:[self textAlignmentFromString:sAlignment]];
    }

    if (sShadowColor != nil)
    {
        [sLabel setShadowColor:[self colorFromHTMLStyleString:sShadowColor]]; 
    }
    
    if (sShadowOffset != nil)
    {
        CGSize sOffsetSize = CGSizeFromString(sShadowOffset);
        [sLabel setShadowOffset:sOffsetSize];
    }
    
    if (sMultiline != nil && [sMultiline boolValue] == YES)
    {
        [sLabel setNumberOfLines:0];
    }
    
    [sLabel setText:[self textForCurrentLanguage:sText]];
    
    return sLabel;
}

- (UIImageView *)imageViewWithFrame:(CGRect)aFrame attributes:(NSDictionary *)aViewInfo
{
    NSString *sImageID = [aViewInfo objectForKey:kImageAttributeImageSourceKey];
    if ([sImageID length] == 0)
        return nil;
    
    UIImage *sImage = [self imageForResourceIDString:sImageID];
    if (sImage == nil)
        return nil;
    
    UIImageView *sImageView = [[UIImageView alloc] initWithFrame:aFrame];
    [sImageView setImage:sImage];
    
    return sImageView;
}

- (UIButton *)buttonWithFrame:(CGRect)aFrame attributes:(NSDictionary *)aViewInfo
{
    NSDictionary *sTitle                      = [aViewInfo        objectForKey:kButtonAttributeTitleKey];
    NSDictionary *sTitleNormal                = [sTitle           objectForKey:kButtonAttributeStateNormalKey];
    NSDictionary *sTitleHighlighted           = [sTitle           objectForKey:kButtonAttributeStateHighlightedKey];
    
    NSString     *sTitleFontFamily            = [aViewInfo        objectForKey:kButtonAttributeTitleFontFamilyKey];
    NSNumber     *sTitleFontSize              = [aViewInfo        objectForKey:kButtonAtrributeTitleFontPointSizeKey];

    NSDictionary *sTitleColor                 = [aViewInfo        objectForKey:kButtonAttributeTitleColor];
    NSString     *sNormalTitleColor           = [sTitleColor      objectForKey:kButtonAttributeStateNormalKey];
    NSString     *sHighlightedTitleColor      = [sTitleColor      objectForKey:kButtonAttributeStateHighlightedKey];
    
    NSString     *sTitleShadowColor           = [aViewInfo        objectForKey:kButtonAttributeTitleShadowColorKey];
    NSString     *sTitleShadowOffset          = [aViewInfo        objectForKey:kButtonAttributeTitleShadowOffsetKey];
    
    NSDictionary *sBackgroundImage            = [aViewInfo        objectForKey:kButtonAttributeBackgroundImageKey];
    NSString     *sNormalBackgroundImage      = [sBackgroundImage objectForKey:kButtonAttributeStateNormalKey];
    NSString     *sHighlightedBackgroundImage = [sBackgroundImage objectForKey:kButtonAttributeStateHighlightedKey];
    
    NSString     *sActionUri                  = [aViewInfo        objectForKey:kButtonAttributeActionURIKey];
    
    if (sTitle == nil || sTitleNormal == nil || sTitleFontFamily == nil || sTitleFontSize == nil || sNormalBackgroundImage == nil)
        return nil;
    
    UIButton *sButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sButton setFrame:aFrame];
                        
    [sButton setAdjustsImageWhenDisabled:NO];
	[sButton setAdjustsImageWhenHighlighted:NO];
    
    [sButton setTitle:[self textForCurrentLanguage:sTitleNormal] forState:UIControlStateNormal];
    
    if (sTitleHighlighted != nil)
        [sButton setTitle:[self textForCurrentLanguage:sTitleHighlighted] forState:UIControlStateHighlighted];
    
    [sButton.titleLabel setFont:[self fontWithFontFamilyString:sTitleFontFamily fontSize:sTitleFontSize]];
    
    UIColor *sButtonTitleColor = [UIColor blackColor];
    if (sButtonTitleColor != nil)
        sButtonTitleColor = [self colorFromHTMLStyleString:sNormalTitleColor];
        
    [sButton setTitleColor:sButtonTitleColor forState:UIControlStateNormal];
    
    if (sHighlightedTitleColor != nil)
       [sButton setBackgroundImage:[self imageForResourceIDString:sNormalBackgroundImage] forState:UIControlStateNormal];
    
    if (sHighlightedBackgroundImage != nil)
       [sButton setBackgroundImage:[self imageForResourceIDString:sHighlightedBackgroundImage] forState:UIControlStateHighlighted];
    
    if (sTitleShadowColor != nil)
    {
        UIColor *sColor = [self colorFromHTMLStyleString:sTitleShadowColor];
        [sButton setTitleShadowColor:sColor forState:UIControlStateNormal];
        [sButton setTitleShadowColor:sColor forState:UIControlStateHighlighted];
    }
    
    if (sTitleShadowOffset != nil)
    {
        CGSize sSize = CGSizeFromString(sTitleShadowOffset);
        [sButton.titleLabel setShadowOffset:sSize];
    }
    
    [sButton setExclusiveTouch:YES];
    [sButton handleControlEvent:UIControlEventTouchUpInside withBlock:^{
        
        NSURL *aURL = [NSURL URLWithString:sActionUri];
        if ([[UIApplication sharedApplication] canOpenURL:aURL] == YES)
            [[UIApplication sharedApplication] openURL:aURL];
    }];
    
    return sButton;
}

- (UIView *)generalViewWithFrame:(CGRect)aFrame attributes:(NSDictionary *)aViewInfo
{
    UIView *sView = [[UIView alloc] initWithFrame:aFrame];
    return sView;
}

- (UIView *)viewForUIType:(NLUIType)aUIType withFrame:(CGRect)aViewFrame attributes:(NSDictionary *)aViewInfo
{
    switch (aUIType)
    {
        case NLUITypeLabel:
            return [self labelWithFrame:aViewFrame attributes:aViewInfo];
            
        case NLUITypeImageView:
            return [self imageViewWithFrame:aViewFrame attributes:aViewInfo];
            
        case NLUITypeButton:
            return [self buttonWithFrame:aViewFrame attributes:aViewInfo];
            
        case NLUITypeView:
            return [self generalViewWithFrame:aViewFrame attributes:aViewInfo];
            
        default:
            return nil;
    }
}

- (UIView *)makeChildViewFromInfo:(NSDictionary *)aViewInfo
{
    UIView  *sView = nil;
    
    NSString *sViewID              = [aViewInfo objectForKey:kCommonAttributeIDKey];
    NSString *sViewType            = [aViewInfo objectForKey:kCommonAttributeTypeKey];
    NSString *sViewFrame           = [aViewInfo objectForKey:kCommonAttributeFrameKey];
    NSString *sViewBackgroundColor = [aViewInfo objectForKey:kCommonAttributeBackgroundColorKey];
    NSString *sViewAutoCenter      = [aViewInfo objectForKey:kCommonAttributeAutoCenterKey];
    NSArray  *sViewsChildren       = [aViewInfo objectForKey:kCommonAttributeChildrenKey];
    
    if ([sViewID length] == 0 || [sViewType length] == 0 || [sViewFrame length] == 0)
        return nil;
    
    CGRect    sFrame  = CGRectFromString(sViewFrame);
    NLUIType  sUIType = [self uiTypeFromString:sViewType];
    NSInteger sTag    = [self tagForControlIDString:sViewID];
    
    sView = [self viewForUIType:sUIType withFrame:sFrame attributes:aViewInfo];
    if (sView == nil)
        return nil;
    
    if ([sViewsChildren count] > 0)
    {
        UIView *sChildView = [self makeChildViewFromInfo:aViewInfo];
        [sView addSubview:sChildView];
    }
    
    UIColor *sBackgroundColor = nil;
    if (sViewBackgroundColor != nil)
        sBackgroundColor = [self colorFromHTMLStyleString:sViewBackgroundColor];
    else
        sBackgroundColor  = [UIColor clearColor];
    
    if (sViewAutoCenter != nil)
    {
        NSInteger sAutoCenterType = [self autoCenterTypeFromString:sViewAutoCenter];
        if (sAutoCenterType & NLAutoCenterTypeHorizontal)
            [sView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        else if (sAutoCenterType & NLAutoCenterTypeVertical)
            [sView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin];
    }
    
    [sView setBackgroundColor:sBackgroundColor]; 
    [sView setTag:sTag];
    
    return sView;
}

- (UIView *)makeRootView
{
    CGRect  sRootFrame = CGRectZero; 
    UIView *sRootView  = [[UIView alloc] init]; 
    
    for (NSDictionary *sViewInfo in mViews)
    {
        UIView *sInnerView = [self makeChildViewFromInfo:sViewInfo];
        if (sInnerView == nil)
            continue;
        
        sRootFrame = CGRectUnion(sRootFrame, [sInnerView frame]);
        [sRootView addSubview:sInnerView];
    }
    
    [sRootView setFrame:sRootFrame];
    
    return sRootView;
}

#pragma mark -
#pragma mark Public Operation

- (BOOL)load:(NSString *)aFilePath
{
    if ([aFilePath length] == 0)
        return NO;
    
    [self reset];
    
    NSError  *sError     = nil;
    NSString *sContents  = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:aFilePath] 
                                                    encoding:NSUTF8StringEncoding 
                                                       error:&sError];
    if (sError != nil)
    {
        NSLog(@"%@", sError);
        return NO;
    }
    
    NSDictionary *sParsingResult = [sContents objectFromJSONString];
    if (sParsingResult != nil)
    {
        return [self parse:sParsingResult];
    }
    else
    {
        return NO;
    }
}

- (UIView *)view
{
    if ([mViews count] != 0)
        return [self makeRootView];
    else 
        return nil;
}

@end
