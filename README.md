# YIHtmlParser

[![SPM supported](https://img.shields.io/badge/SPM-supported-4BC51D.svg?style=flat)](https://github.com/apple/swift-package-manager)
[![podversion](https://img.shields.io/cocoapods/v/YIHtmlParser.svg?style=flat)](https://cocoapods.org/pods/YIHtmlParser)

参考[Hpple](https://github.com/topfunky/hpple)而来，对比Hpple增加了可对html进行增删改查。

## 背景

项目中一个主要功能是展示html，并且进行屏幕适配。但html各式各样，标签或者样式中设置了宽高属性，会导致展示不能适配屏幕，所以需要对html进行修改。


网上对html进行解析的Hpple库，只能进行解析，无法修改，但看了下代码，主要是使用libxml，libxml本身其实不只解析的功能，于是有了这个库。

## 安装

pod: `pod 'YIHtmlParser'`

SPM: `package(url: "https://github.com/zhenghongyi/YIHtmlParser.git", .upToNextMajor(from: "1.0.4"))`

## 使用范例

主要都是在YIHtmlSimpleTests和YIHtmlParserTests两个测试用例文件里有展示，这里贴一下YIHtmlSimpleTests。

```
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
```

* 先将html转为data，然后生成YIHtmlParser实例，beginParser和endParser必须配对使用，在两者之间可以通过handleWithXPathQuery进行各种操作。