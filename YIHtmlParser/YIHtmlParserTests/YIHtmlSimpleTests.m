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

- (void)testResult_SelfClosingTags {
    NSString* html = @"<style type=\"text/css\"></style><img src=''/>";
    NSData* data = [html dataUsingEncoding:NSUTF8StringEncoding];
    YIHtmlParser* parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [parser beginParser];
    
    NSString* result = [parser resultHtml];
    
    [parser endParser];
    
    XCTAssertTrue([result isEqualToString:@"<html><head><style type=\"text/css\">\n</style></head><body><img src=\"\">\n</img></body></html>"]);
}

@end
