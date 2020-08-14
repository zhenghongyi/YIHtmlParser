//
//  YIHtmlSimpleTests.m
//  YIHtmlParserTests
//
//  Created by 郑洪益 on 2019/4/17.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "YIHtmlParser.h"

@interface YIHtmlSimpleTests : XCTestCase

@end

@implementation YIHtmlSimpleTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

// 测试结果中不包含无法识别字符
- (void)testResultHtml {
    NSString* html = @"\
    <style type=\"text/css\">\
    pre{\
        max-width: 100%;\
    }\
    </style>\
    <pre>haha</pre>";
    
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    
    NSString* result = [parser resultHtml];
    
    [parser endParser];
    
    XCTAssertFalse([result containsString:@"<![CDATA["]);
}

// 测试自闭合标签处理
- (void)testResult_SelfClosingTags {
    NSString* html = @"<style type=\"text/css\"></style><img src=''/>";
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    
    NSString* result = [parser resultHtml];
    
    [parser endParser];
    
    XCTAssertTrue([result isEqualToString:@"<html><head><style type=\"text/css\">\n</style></head><body><img src=\"\">\n</img></body></html>"]);
}

// 测试添加前置标签
- (void)testNextSibling {
    NSString* html = @"<div><table></table></div>";
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    
    [parser handleWithXPathQuery:@"//table" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* e = elements.firstObject;
        [e addNextSibling:@"div" attribute:@{@"color":@"blue"}];
        [e addPrevSibling:@"pre" attribute:nil];
    }];
    
    NSString* result = [parser resultHtml];
    
    [parser endParser];
    
    XCTAssertTrue([result isEqualToString:@"<html><body><div><pre>\n</pre><table>\n</table><div color=\"blue\">\n</div></div></body></html>"]);
}

// 测试初始内容包含转义字符
- (void)testSpecialCharacters {
    NSString* html = @"<div>\\n</div><br>\\t<br/>哈哈<br/><br/>";
    
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    
    NSString* result = [parser resultHtml];
    
    [parser endParser];
    
    XCTAssertTrue([result isEqualToString:@"<html><body><div>\\n</div><br/>\\t<br/>哈哈<br/><br/></body></html>"]);
}

// 测试自闭合标签
- (void)testSelfClosedTags {
    NSString* html = @"<div>\\n</div><br/><br>对对对<br/>哈哈<br/><br/>";
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    NSString* result = [parser resultHtml];
    [parser endParser];
    XCTAssertTrue([result isEqualToString:@"<html><body><div>\\n</div><br/><br/>对对对<br/>哈哈<br/><br/></body></html>"]);
    
    html = @"<div>哈哈哈<p></p>哈<p>但是\nowi</p>快递</div>";
    data = [html dataUsingEncoding:NSUTF8StringEncoding];
    parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    result = [parser resultHtml];
    [parser endParser];
    XCTAssertTrue([result isEqualToString:@"<html><body><div>哈哈哈<p/>哈<p>但是\nowi</p>快递</div></body></html>"]);
}

// 测试设置style属性
- (void)testSetStyle {
    NSString* html = @"<p>This is a paragraph</p>";
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    
    [parser handleWithXPathQuery:@"//p" action:^(NSArray<YIHtmlElement *> * _Nonnull elements) {
        for (YIHtmlElement* e in elements) {
            [e setProperty:@{@"style":@"color:red; margin-left:20px"}];
        }
    }];
    
    NSString* result = [parser resultHtml];
    result = [parser resultHtml];
    [parser endParser];
    
    XCTAssertTrue([result isEqualToString:@"<html><body><p style=\"color:red; margin-left:20px\">This is a paragraph</p></body></html>"]);
}

@end
