//
//  XPathHandler.m
//  YIHtmlParser
//
//  Created by 郑洪益 on 2019/1/27.
//  Copyright © 2019 郑洪益. All rights reserved.
//

#import "XPathHandler.h"

// 查
NSString* HtmlForNode(xmlNodePtr node) {
    xmlBufferPtr buffer = xmlBufferCreate();
    xmlNodeDump(buffer, node->doc, node, 0, 0);
    NSString *htmlContent = [NSString stringWithCString:(const char *)buffer->content encoding:NSUTF8StringEncoding];
    xmlBufferFree(buffer);
    return htmlContent;
}

NSDictionary* DictionaryForNode(xmlNodePtr currentNode) {
    NSMutableDictionary *resultForNode = [NSMutableDictionary dictionary];
    if (currentNode->name) {
        NSString *currentNodeContent = [NSString stringWithCString:(const char *)currentNode->name
                                                          encoding:NSUTF8StringEncoding];
        resultForNode[@"nodeName"] = currentNodeContent;
    }
    
    xmlChar *nodeContent = xmlNodeGetContent(currentNode);
    if (nodeContent != NULL) {
        NSString *currentNodeContent = [NSString stringWithCString:(const char *)nodeContent
                                                          encoding:NSUTF8StringEncoding];
        resultForNode[@"nodeContent"] = currentNodeContent;
        xmlFree(nodeContent);
    }
    
    return resultForNode;
}

NSDictionary* AttributeForNode(xmlNodePtr currentNode) {
    xmlAttr *attribute = currentNode->properties;
    if (attribute) {
        NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
        while (attribute) {
            NSString *attributeName = [NSString stringWithCString:(const char *)attribute->name
                                                         encoding:NSUTF8StringEncoding];
            
            if (attribute->children) {
                NSDictionary *childDictionary = DictionaryForNode(attribute->children);
                NSString* attributeContent = @"";
                if (childDictionary) {
                    attributeContent = childDictionary[@"nodeContent"];
                }
                
                if (attributeName && attributeContent) {
                    attributeDictionary[attributeName] = attributeContent;
                }
            }
            
            attribute = attribute->next;
        }
        
        return attributeDictionary;
    }
    return nil;
}

xmlXPathObjectPtr SearchXPathObj(NSString* query, xmlXPathContextPtr xpathCtx) {
    if(xpathCtx == NULL) {
        NSLog(@"Unable to create XPath context.");
        return nil;
    }
    
    xmlXPathObjectPtr xpathObj;
    /* Evaluate xpath expression */
    xpathObj = xmlXPathEvalExpression((xmlChar *)[query cStringUsingEncoding:NSUTF8StringEncoding], xpathCtx);
    if(xpathObj == NULL) {
        NSLog(@"Unable to evaluate XPath.");
        xmlXPathFreeContext(xpathCtx);
        return nil;
    }
    
    return xpathObj;
}

// 增/改
xmlNodePtr CreateNode(NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute) {
    xmlNodePtr newNode = xmlNewNode(NULL, BAD_CAST [nodeName cStringUsingEncoding:NSUTF8StringEncoding]);
    AddContent(newNode, @"\n");
    SetPropertyForNode(newNode, attribute);
    return newNode;
}

void AddContent(xmlNodePtr node, NSString* content) {
    xmlNodeAddContent(node, BAD_CAST [content cStringUsingEncoding:NSUTF8StringEncoding]);
}

void SetPropertyForNode(xmlNodePtr node, NSDictionary<NSString*, NSString*>*dictionary) {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        xmlSetProp(node, (xmlChar*)[key cStringUsingEncoding:NSUTF8StringEncoding], (xmlChar *)[obj cStringUsingEncoding:NSUTF8StringEncoding]);
    }];
}

void AddParent(xmlNodePtr curNode, NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute) {
    xmlNodePtr newNode = xmlNewNode(NULL, BAD_CAST [nodeName cStringUsingEncoding:NSUTF8StringEncoding]);
    xmlReplaceNode(curNode, newNode);
    xmlAddChild(newNode, curNode);
    SetPropertyForNode(newNode, attribute);
}

void AddNextSibling(xmlNodePtr curNode, NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute) {
    xmlNodePtr newNode = CreateNode(nodeName, attribute);
    xmlAddNextSibling(curNode, newNode);
}

void AddPrevSibling(xmlNodePtr curNode, NSString* nodeName, NSDictionary<NSString*, NSString*>* attribute) {
    xmlNodePtr newNode = CreateNode(nodeName, attribute);
    xmlAddPrevSibling(curNode, newNode);
}

// 删
void DeleteNode(xmlNodePtr node) {
    xmlUnlinkNode(node);
}
