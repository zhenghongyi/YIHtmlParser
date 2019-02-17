//
//  YIHtmlParser.h
//  YIHtmlParser
//
//  Created by 郑洪益 on 2019/1/27.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "YIHtmlElement.h"

NS_ASSUME_NONNULL_BEGIN

@interface YIHtmlParser : NSObject

- (instancetype)initWithData:(NSData *)data encoding:(nullable NSString *)encoding;

- (void)beginParser;
- (void)endParser;

- (void)handleWithXPathQuery:(NSString *)query action:(nullable void(^)(NSArray* elements))action;

- (NSString *)resultHtml;

@end

NS_ASSUME_NONNULL_END
