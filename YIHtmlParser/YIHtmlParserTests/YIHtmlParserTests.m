//
//  YIHtmlParserTests.m
//  YIHtmlParserTests
//
//  Created by 郑洪益 on 2019/2/17.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "YIHtmlParser.h"

@interface YIHtmlParserTests : XCTestCase

@property (nonatomic, strong) YIHtmlParser* parser;

@end

@implementation YIHtmlParserTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSURL *testFileUrl = [testBundle URLForResource:@"index" withExtension:@"html"];
    NSData * data = [NSData dataWithContentsOfURL:testFileUrl];
    self.parser = [[YIHtmlParser alloc] initWithData:data encoding:nil];
    [self.parser beginParser];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    [self.parser endParser];
}

- (void)testSearchesWithXPath
{
    [self.parser handleWithXPathQuery:@"//a[@class='sponsor']" action:^(NSArray * _Nonnull elements) {
        XCTAssertEqual([elements count], 2);
        XCTAssertTrue([elements.firstObject isMemberOfClass:[YIHtmlElement class]]);
    }];
}

- (void)testFindsFirstElementAtXPath
{
    [self.parser handleWithXPathQuery:@"//a[@class='sponsor']" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.firstObject;
        XCTAssertEqualObjects(element.nodeName, @"a");
    }];
}

- (void)testSearchesByNestedXPath
{
    [self.parser handleWithXPathQuery:@"//div[@class='column']//strong" action:^(NSArray * _Nonnull elements) {
        XCTAssertEqual(elements.count, 5);
    }];
}

- (void)testPopulatesAttributes
{
    [self.parser handleWithXPathQuery:@"//a[@class='sponsor']" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.firstObject;
        
        XCTAssertTrue([element.attribute isKindOfClass:[NSDictionary class]]);
        XCTAssertEqualObjects([element.attribute objectForKey:@"href"], @"http://railsmachine.com/");
    }];
}

- (void)testStyle {
    [self.parser handleWithXPathQuery:@"//table" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.lastObject;
        
        XCTAssertNotNil(element.style);
        NSDictionary* style = @{@"color":@"blue",@"width":@"100px",@"height":@"100px"};
        XCTAssertEqualObjects(element.style, style);
    }];
}

- (void)testSetProperty {
    [self.parser handleWithXPathQuery:@"//table" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.lastObject;
        
        NSDictionary* style = @{@"border":@"1px"};
        [element setProperty:style];
    }];
    
    [self.parser handleWithXPathQuery:@"//table" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.lastObject;
        
        XCTAssertNotNil(element.attribute);
        XCTAssertEqualObjects([element.attribute objectForKey:@"border"], @"1px");
    }];
}

- (void)testSurround {
    [self.parser handleWithXPathQuery:@"//table" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.lastObject;
        
        [element addSurround:@"pre" attribute:@"color='blue'"];
    }];
    
    [self.parser handleWithXPathQuery:@"//pre" action:^(NSArray * _Nonnull elements) {
        YIHtmlElement* element = elements.firstObject;
        
        XCTAssertEqualObjects(element.html, @"<pre color=\"blue\"><table style=\"color:blue;width:100px;height:100px\">This is a table</table></pre>");
    }];
}

- (void)testContains {
    __block YIHtmlElement* e1;
    __block YIHtmlElement* e2;
    
    [self.parser handleWithXPathQuery:@"//body" action:^(NSArray * _Nonnull elements) {
        e1 = [elements firstObject];
    }];
    [self.parser handleWithXPathQuery:@"//div[@class='vcard']" action:^(NSArray * _Nonnull elements) {
        e2 = [elements firstObject];
    }];
    XCTAssertTrue([e1 isContains:e2]);
    XCTAssertFalse([e2 isContains:e1]);
    
    [self.parser handleWithXPathQuery:@"//div[@class='adr']" action:^(NSArray * _Nonnull elements) {
        e1 = [elements firstObject];
    }];
    [self.parser handleWithXPathQuery:@"//div[@class='org']" action:^(NSArray * _Nonnull elements) {
        e2 = [elements firstObject];
    }];
    XCTAssertFalse([e1 isContains:e2]);
    XCTAssertFalse([e2 isContains:e1]);
}

@end
