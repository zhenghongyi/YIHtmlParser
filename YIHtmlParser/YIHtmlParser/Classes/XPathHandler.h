//
//  XPathHandler.h
//  YIHtmlParser
//
//  Created by 郑洪益 on 2019/1/27.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

NSString* HtmlForNode(xmlNodePtr node);

NSDictionary* DictionaryForNode(xmlNodePtr currentNode);

NSDictionary* AttributeForNode(xmlNodePtr currentNode);

xmlXPathObjectPtr SearchXPathObj(NSString* query, xmlXPathContextPtr xpathCtx);

void AddContent(xmlNodePtr node, NSString* content);

void SetPropertyForNode(xmlNodePtr node, NSDictionary<NSString*, NSString*>*dictionary);

void AddParent(xmlNodePtr curNode, NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute);

void AddNextSibling(xmlNodePtr curNode, NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute);

void AddPrevSibling(xmlNodePtr curNode, NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute);

void DeleteNode(xmlNodePtr node);
