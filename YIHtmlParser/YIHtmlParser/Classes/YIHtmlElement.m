//
//  YIHtmlElement.m
//  YIHtmlParser
//
//  Created by 郑洪益 on 2019/1/27.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import "YIHtmlElement.h"

#import "XPathHandler.h"

@interface YIHtmlElement() {
    xmlNodePtr _node;
    NSString* _encoding;
}

@property (nonatomic, copy, readwrite) NSString* html;

@property (nonatomic, copy, readwrite) NSString* innerHtml;

@property (nonatomic, copy, readwrite) NSString* nodeName;

@property (nonatomic, copy, readwrite) NSDictionary* attribute;

@end

@implementation YIHtmlElement

- (instancetype)initWithNode:(xmlNodePtr)node encoding:(NSString *)encoding {
    self = [super init];
    if (self) {
        _node = node;
        _encoding = encoding;
    }
    return self;
}

- (NSString *)html {
    if (!_html) {
        _html = HtmlForNode(_node);
    }
    return _html;
}

- (NSString *)innerHtml {
    if (!_innerHtml) {
        NSUInteger beginLocation = [self.html rangeOfString:@">"].location;
        NSUInteger endLocation = [self.html rangeOfString:@"<" options:NSBackwardsSearch].location;
        if (beginLocation != NSNotFound && endLocation != NSNotFound) {
            return [self.html substringWithRange:NSMakeRange(beginLocation + 1, endLocation - beginLocation)];
        }
    }
    return _innerHtml;
}

- (NSString *)nodeName {
    if (!_nodeName) {
        NSDictionary* dic = DictionaryForNode(_node);
        _nodeName = [dic objectForKey:@"nodeName"];
    }
    return _nodeName;
}

- (NSDictionary *)attribute {
    if (!_attribute) {
        _attribute = AttributeForNode(_node);
    }
    return _attribute;
}

- (NSDictionary *)style {
    NSString* styleStr = [self.attribute objectForKey:@"style"];
    if (styleStr) {
        NSMutableDictionary* styleDic = [NSMutableDictionary dictionary];
        NSArray* array = [styleStr componentsSeparatedByString:@";"];
        for (NSString* item in array) {
            NSArray* itemArr = [item componentsSeparatedByString:@":"];
            if (itemArr.count < 2) {
                continue;
            }
            if ([itemArr.firstObject isEqualToString:@""]) {
                continue;
            }
            [styleDic setObject:itemArr.lastObject forKey:itemArr.firstObject];
        }
        return styleDic;
    }
    return nil;
}

- (NSArray<YIHtmlElement *> *)children {
    NSMutableArray* array = [NSMutableArray array];
    xmlNodePtr childNode = _node->children;
    while (childNode) {
        YIHtmlElement* childElement = [[YIHtmlElement alloc] initWithNode:childNode encoding:_encoding];
        [array addObject:childElement];
        
        childNode = childNode->next;
    }
    
    return array;
}

- (void)addContent:(NSString *)content {
    AddContent(_node, content);
}

- (void)setProperty:(NSDictionary<NSString*, NSString*> *)dictionary {
    SetPropertyForNode(_node, dictionary);
}

- (void)addParent:(NSString *)nodeName attribute:(NSDictionary<NSString*, NSString*> *)attribute {
    AddParent(_node, nodeName, attribute);
}

- (void)addNextSibling:(NSString *)nodeName attribute:(NSDictionary<NSString*, NSString*> *)attribute {
    AddNextSibling(_node, nodeName, attribute);
}

- (void)addPrevSibling:(NSString *)nodeName attribute:(NSDictionary<NSString*, NSString*> *)attribute {
    AddPrevSibling(_node, nodeName, attribute);
}

- (void)deleteCurNode {
    DeleteNode(_node);
}

- (BOOL)isContains:(YIHtmlElement *)element {
    if (element == nil) {
        return false;
    }
    xmlNodePtr parentNode = element->_node->parent;
    while (parentNode) {
        if (parentNode == _node) {
            return true;
        }
        parentNode = parentNode->parent;
    }
    return false;
}

@end
