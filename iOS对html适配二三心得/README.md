## 问题

使用webView对html进行展示，很多时候会碰上html不能正确的适配当前界面。如果用的是UIWebView，可以使用`webView.scaleToFit = true`属性，做些调整。但不幸的是，苹果已经在禁止用UIWebView，而推广WKWebView，但WKWebView没有这样的属性。并且`scaleToFit`属性也不是完美的，对于某些html，还是会有不适配的情况存在。

比如这种：

```
<html>
	<head>
	</head>
	<body>
	<table border="1" width=500>
	  <tr>
	    <th>Month</th>
	    <th>Savings</th>
	  </tr>
	  <tr>
	    <td>January</td>
	    <td>$100</td>
	  </tr>
	</table>
	</body>
</html>
```

<center><font size=2 color=#a2a2a2>例1</font></center>

iOS没有提供其他适配html的api，所以只能转而从js方面入手，js中有一个设置全局缩放适配到当前设备尺寸的方法

`<meta name=viewport content="width=device-width,initial-scale=1,minimum-scale=1">`

`initial-scale`和`minimum-scale`的值可以根据需要设置。

这个缩放方式和`scaleToFit`作用类似，都是对整体针对设备进行了缩放，所以两者都会有一个问题：**如果存在html本身设置的宽度超长，那么进行缩放后，会导致其他元素被严重缩小挤压。**

比如html中常见的`img`和`table`标签，经常会设置宽度，超宽大图和超宽表格是不少见的。被设置整体缩放后，这两个标签被适配了，但其他部分被挤压了。

```
<html>
	<head>
	    <meta charset="utf-8">
	    <meta name=viewport content="width=device-width,initial-scale=0.8,minimum-scale=0.8">
	</head>
	<body>
	<table border="1" width=500>
	  <tr>
	    <th>Month</th>
	    <th>Savings</th>
	  </tr>
	  <tr>
	    <td>January</td>
	    <td>$100</td>
	  </tr>
	</table>
	<div>1234567890</div>
	</body>
</html>
```
<center><font size=2 color=#a2a2a2>例2</font></center>

例2是从例1的基础上底部扩展多一行div，运行在iPhone 11 Pro Max模拟器上，效果是比较合适的，但是一旦head里scale缩的更小，div里的文字也跟着缩小。

## 解析

这种情况要适配，需要对html进行修改。

* 整体缩放

`<meta name=viewport content="width=device-width,initial-scale=1,minimum-scale=1">`

html的渲染，会根据html的指定样式和执行的js，最终才会去确定怎么缩放。

* `img`自适应

`img`标签在没有指定宽高的情况下，会是图片原有的尺寸；但经常会有指定宽高的情况，所以需要将指定的宽高去掉，同时给`img`一个宽度最大值，让它自适应。

* `table`缩放

`table`标签要尽量等比例缩放，毕竟`table`有时候就是开发人员精心制作出来的好看的样式。所以，我们需要找出所有的`table`标签，用js将这些表格针对屏幕进行等比例缩放。


```
伪代码：
var tableWidth = table.scrollWidth
var scale = 屏幕宽度 / tableWidth

if (scale < 1) {
	var tableHeight = table.scrollHeight
	var distance = tableHeight - (tableHeight * scale)
	
	// 设置缩放原点
	table.style.transformOrigin = '0 0'
	// 缩放
	table.style.transform = 'scale3d(' + scale + ',' + scale + ',' + '1)'
	// 去掉缩放后的空余底部空间
	table.style.marginBottom = '-' + distance + 'px'
	
	// 父元素也跟着改变大小
	let parentHeight = table.parentElement.scrollHeight
	table.parentElement.style.height = height * scale + 'px'
}
```

但有的html里会有`table`多层嵌套的情况，如果每个table都做上面这样的缩放，那就可能会出现，父table刚缩放完，子table又要执行这样的缩放，显得多余又有可能导致过度缩放。

所以最好是找到每一个最顶级的table，针对它进行缩放就可以了。但为了不破坏table原有的属性，特别是id和class之类的，所以最好是在外面包一层div来作缩放。

## 行动

分析完问题和有了各个问题点的解决方法，可以开始动手。

`img`去除宽高和找出顶级`table`并用div进行包含，这两个可以在html渲染前进。

这两步的改造，我采用了自己写的一个库[YIHtmlParser](https://github.com/zhenghongyi/YIHtmlParser)，作用主要是解析html，并对html进行修改。

```
guard mailHtml.isEmpty == false, let data = mailHtml.data(using: String.Encoding.utf8) else {
    return mailHtml
}
    
var result = mailHtml
    
let parser = YIHtmlParser(data: data, encoding: nil)
parser.begin()
    
// img标签
/// 去除宽高
parser.handle(withXPathQuery: "//img") {[weak self] (elements) in
    guard let elements = elements else {
        return
    }
    
    for item in elements {
        item.setProperty(["width":"", "height":""])
        if var style = item.style as? [String:String] {
            style.removeValue(forKey: "height")
            style.removeValue(forKey: "width")
            item.setStyle(style)
        }
    }
}
    
// table标签
/// iOS11以上border-collapse:collapse导致分隔线消失
/// 1.改border-collapse:collapse为默认值separate，使用cellspacing:0为替换效果
/// 2.找出最顶层table标签，使用div包含
parser.handle(withXPathQuery: "//table") { (elements) in
    guard let elements = elements else {
        return
    }
    
    var innerTableE = [YIHtmlElement]()
    for e1 in elements {
        if let tmp = e1.style?["border-collapse"] as? String, tmp == "collapse" {
            e1.setStyle(["border-collapse":"separate"])
            e1.setProperty(["cellspacing":"0"])
        }
        
        for e2 in elements {
            if e2.contains(e1) {
                innerTableE.append(e1)
                break
            }
        }
    }
    
    for e in elements where innerTableE.contains(e) == false {
        e.addSurround("div", attribute: ["class":"TopTable"])
    }
}
    
parser.handle(withXPathQuery: "//div[@class='TopTable']") { (elements) in
    guard let elements = elements else {
        return
    }
    
    for e in elements {
        e.addSurround("div", attribute: nil)
    }
}
    
result = parser.resultHtml() ?? ""
parser.end()
    
return result
```

剩下的步骤，我们可以由css或者js去完成，所以我们可以有一个模板，将上面两步处理完的html嵌套进去就可以了。

模板：

```
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta name=viewport content="width=device-width,initial-scale=1,minimum-scale=1,maximum-scale=2">
        <style type="text/css">
            blockquote{margin-right: 0 !important}
            img {
                max-width: 100%%;
            }
            pre {
                white-space: pre-wrap;
                word-break: keep-all;
            }
        </style>
        <script>
			function load() {
			    loadTableScale()
			}
			
			function loadTableScale() {
			    var topTables = document.getElementsByClassName('TopTable')
			    for (var i = 0; i < topTables.length; i++) {
			      var container = topTables[i]
			      var containWidth = container.scrollWidth
			      var scale = %f / containWidth // %f 为屏幕宽度
			
			      if (scale < 1) {
			          var containHeight = container.scrollHeight
			          var distance = containHeight - (containHeight * scale)
			
			          container.style.transform = 'scale3d(' + scale + ',' + scale + ',' + '1)'
			          container.style.transformOrigin = '0 0'
			          container.style.marginBottom = '-' + distance + 'px'
			
			          let height = topTables[i].parentElement.scrollHeight
			          topTables[i].parentElement.style.height = height * scale + 'px'
			      }
			    }
			}
        </script>
    </head>
    <body style="word-break: break-all;word-wrap: break-word;border-width: 0px; margin: 15px; cursor: auto;" onload="load()">
        %@ // 改造后的html
    </body>
</html>
```

## 总结

上面是在工作中对html适配的一些心得总结，当然html花样百出，还有许多要适配的问题，如果有好的适配方法，欢迎交流学习。
