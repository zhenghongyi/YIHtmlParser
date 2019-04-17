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
void AddContent(xmlNodePtr node, NSString* content) {
    xmlNodeAddContent(node, BAD_CAST [content cStringUsingEncoding:NSUTF8StringEncoding]);
}

void SetPropertyForNode(xmlNodePtr node, NSDictionary<NSString*, NSString*>*dictionary) {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        xmlSetProp(node, (xmlChar*)[key cStringUsingEncoding:NSUTF8StringEncoding], (xmlChar *)[obj cStringUsingEncoding:NSUTF8StringEncoding]);
    }];
}

void SurroundNode(xmlNodePtr node, NSString* nodeName, NSString* nodeAttribute) {
    xmlBufferPtr buffer = xmlBufferCreate();
    xmlNodeDump(buffer, node->doc, node, 0, 0);
    
    char* nodeHeadStr = (char *)[[NSString stringWithFormat:@"<%@ %@>", nodeName, nodeAttribute] cStringUsingEncoding:NSUTF8StringEncoding];
    char* nodeEndStr = (char *)[[NSString stringWithFormat:@"</%@>", nodeName] cStringUsingEncoding:NSUTF8StringEncoding];
    
    char* content = (char *)buffer->content;
    xmlChar* newNodeStr = calloc(strlen(content) + strlen(nodeHeadStr) + strlen(nodeEndStr), 1);
    if (!newNodeStr) {
        return;
    }
    
    strcat((char *)newNodeStr, nodeHeadStr);
    strcat((char *)newNodeStr, content);
    strcat((char *)newNodeStr, nodeEndStr);
    
    xmlDocPtr newDoc = xmlReadMemory((char *)newNodeStr, (int)strlen((char *)newNodeStr), NULL, NULL, 0);
    xmlFree(newNodeStr);
    
    if (!newDoc) {
        return;
    }
    
    xmlNodePtr newNode = xmlDocGetRootElement(newDoc);
    xmlNodePtr copyNode = xmlCopyNode(newNode, 1);
    xmlReplaceNode(node, copyNode);
    
    xmlFreeDoc(newDoc);
}

// 删
void DeleteNode(xmlNodePtr node) {
    xmlUnlinkNode(node);
}
