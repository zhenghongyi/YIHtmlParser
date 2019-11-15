//
//  YIHtmlParser.m
//  YIHtmlParser
//
//  Created by 郑洪益 on 2019/1/27.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import "YIHtmlParser.h"

#import "XPathHandler.h"

@interface YIHtmlParser() {
    NSData* _data;
    NSString* _encoding;
    
    xmlDocPtr _doc;
    xmlXPathContextPtr _context;
}

@end

@implementation YIHtmlParser

- (instancetype)initWithData:(NSData *)data encoding:(NSString *)encoding {
    self = [super init];
    if (self) {
        _data = data;
        _encoding = encoding;
    }
    return self;
}

- (void)beginParser {
    const char *encoded = _encoding ? [_encoding cStringUsingEncoding:NSUTF8StringEncoding] : NULL;
    
    _doc = htmlReadMemory([_data bytes], (int)[_data length], "", encoded, HTML_PARSE_NOWARNING | HTML_PARSE_NOERROR);
    if (_doc == NULL) {
        NSLog(@"Unable to parse.");
        return;
    }
    
    _context = xmlXPathNewContext(_doc);
    if(_context == NULL) {
        NSLog(@"Unable to create XPath context.");
        return;
    }
    
    [self completeSelfClosingTags];
}

- (void)endParser {
    xmlXPathFreeContext(_context);
    xmlFreeDoc(_doc);
}

- (void)handleWithXPathQuery:(NSString *)query action:(void(^)(NSArray* elements))action {
    xmlXPathObjectPtr xpathObj = SearchXPathObj(query, _context);
    
    NSMutableArray* elements = [NSMutableArray array];
    xmlNodeSetPtr nodes = xpathObj->nodesetval;
    if (!nodes && nodes != NULL) {
        for (int i = 0; i < nodes->nodeNr; i ++) {
            YIHtmlElement* e = [[YIHtmlElement alloc] initWithNode:nodes->nodeTab[i] encoding:_encoding];
            [elements addObject:e];
        }
    }
    
    if (action) {
        action([elements copy]);
    }
    
    xmlXPathFreeObject(xpathObj);
}

- (NSString *)resultHtml {
    NSString* result;
    
    xmlNodePtr rootNode = xmlDocGetRootElement(_doc);
    xmlBufferPtr buffer = xmlBufferCreate();
    xmlNodeDump(buffer, rootNode->doc, rootNode, 0, 0);
    NSString *htmlContent = [NSString stringWithCString:(const char *)buffer->content encoding:NSUTF8StringEncoding];
    xmlBufferFree(buffer);
    
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    htmlContent = [htmlContent stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
    result = [htmlContent copy];
    
    NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"<!\\[CDATA\\[(.*?)\\]\\]>" options:0 error:nil];
    
    NSArray* matchs = [regex matchesInString:htmlContent options:0 range:NSMakeRange(0, result.length)];
    
    for (NSTextCheckingResult* matchResult in matchs) {
        NSString* matchStr = [htmlContent substringWithRange:matchResult.range];
        NSString* orginStr = [matchStr substringWithRange:NSMakeRange(9, matchStr.length - 12)];
        result = [result stringByReplacingOccurrencesOfString:matchStr withString:orginStr];
    }
    
    result = [result stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    result = [result stringByReplacingOccurrencesOfString:@"\\t" withString:@"\t"];
    
    return result;
}

// 补全自闭合标签
- (void)completeSelfClosingTags {
    [self handleWithXPathQuery:@"//*[not(node())]" action:^(NSArray * _Nonnull elements) {
        for (YIHtmlElement* e in elements) {
            [e addContent:@"\n"];
        }
    }];
}

@end
