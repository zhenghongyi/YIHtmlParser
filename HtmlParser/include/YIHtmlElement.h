//
//  YIHtmlElement.h
//  YIHtmlParser
//
//  Created by 郑洪益 on 2019/1/27.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libxml/tree.h>

NS_ASSUME_NONNULL_BEGIN

@interface YIHtmlElement : NSObject

@property (nonatomic, copy, readonly) NSString* html;

@property (nonatomic, copy, readonly) NSString* innerHtml;

@property (nonatomic, copy, readonly) NSString* nodeName;

@property (nonatomic, copy, readonly) NSDictionary* attribute;

@property (nonatomic, copy, readonly) NSDictionary* style;

@property (nonatomic, copy, readonly) NSArray<YIHtmlElement*>* children;

- (instancetype)initWithNode:(xmlNodePtr)node encoding:(nullable NSString *)encoding;

+ (instancetype)createWithName:(NSString *)name attribute:(nonnull NSDictionary<NSString*, NSString*> *)attribute;

- (void)addContent:(NSString *)content;

- (void)setProperty:(NSDictionary<NSString*, NSString*> *)dictionary;

- (void)addParent:(NSString *)nodeName attribute:(nullable NSDictionary<NSString*, NSString*> *)attribute;

- (void)addNextSibling:(NSString *)nodeName attribute:(nullable NSDictionary<NSString*, NSString*> *)attribute;

- (void)addPrevSibling:(NSString *)nodeName attribute:(nullable NSDictionary<NSString*, NSString*> *)attribute;

- (void)addChild:(YIHtmlElement *)child;

- (void)deleteCurNode;

- (BOOL)isContains:(YIHtmlElement *)element;

@end

NS_ASSUME_NONNULL_END
