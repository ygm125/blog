---
Layout: Layout
title: Evo 一个类 Vue 的 MVVM 框架
date: 2017-01-22 11:35:59
tags: [vue, javascript, mvvm]
---

### 概述

Vue 一个 MVVM 框架、一个响应式的组件系统，通过把页面抽象成一个个组件来增加复用性、降低复杂性，主要特色就是数据操纵视图变化，一旦数据变化自动更新所有关联组件~

所以它的一大特性就是一个数据响应系统，当然有了数据还需要一个模板解析系统，即 HTMLParse 帮我们把数据模板生成最终的页面，但每次数据变动都重新生成 HTML 片段挂载到 DOM 性能肯定慢的没法说,所以还需要 Virtual DOM 把最少的变动应用到 DOM 上，以提升性能

基本上述三项组装到一起也就出来了我们自己的 Vue 框架 Evo

### Virtual DOM

下面先说下 Virtual DOM

所谓的 Virtual DOM 就是用 JS 来模拟 DOM 树（因为 JS 操作比 DOM 快很多）

每次数据变动用新生成的树与之前的树做比对，计算出最终的差异补丁到真正的 DOM 树上

Vue 2.0 底层基于 Snabbdom 这个 Virtual DOM 做了优化与整合

具体可以到这里查看 [https://github.com/snabbdom/snabbdom](https://github.com/snabbdom/snabbdom)

这个库的主要特色是简单、模块化方便扩展与出色的性能

简单例子

```js
var snabbdom = require("snabbdom");
var patch = snabbdom.init([
  // Init patch function with chosen modules
  require("snabbdom/modules/class").default, // makes it easy to toggle classes
  require("snabbdom/modules/props").default, // for setting properties on DOM elements
  require("snabbdom/modules/style").default, // handles styling on elements with support for animations
  require("snabbdom/modules/eventlisteners").default // attaches event listeners
]);
var h = require("snabbdom/h").default; // helper function for creating vnodes

var container = document.getElementById("container");

var vnode = h("div#container.two.classes", { on: { click: someFn } }, [
  h("span", { style: { fontWeight: "bold" } }, "This is bold"),
  " and this is just normal text",
  h("a", { props: { href: "/foo" } }, "I'll take you places!")
]);
// Patch into empty DOM element – this modifies the DOM as a side effect
patch(container, vnode);

var newVnode = h(
  "div#container.two.classes",
  { on: { click: anotherEventHandler } },
  [
    h(
      "span",
      { style: { fontWeight: "normal", fontStyle: "italic" } },
      "This is now italic type"
    ),
    " and this is still just normal text",
    h("a", { props: { href: "/bar" } }, "I'll take you places!")
  ]
);
// Second `patch` invocation
patch(vnode, newVnode); // Snabbdom efficiently updates the old view to the new state
```

不难看出 patch 就是一个模块化的功能聚合，你也可以根据核心的 Hook 机制来提供自己的功能模块

然后通过 snabbdom/h 来创建 vnodes，最后用 patch 做更新处理

这个库的代码量不大，实现的非常灵活，有兴趣的可以读读源码，另外也建议读读这篇文章 [深度剖析：如何实现一个 Virtual DOM 算法 #](https://github.com/livoras/blog/issues/13) 以更好的了解内部原理

不过从上面的语法可以看出使用起来相当麻烦，所以我们需要一种简单的书写方式来帮我们解析成对应的语法规则

也就是要说的 HTML Parse

### HTML Parser

Vue 2.0 的 Parse 原型基于 John Resig 的 HTML Parser，这个 Parser 写的很小巧，可以到这里了解 [http://ejohn.org/blog/pure-javascript-html-parser/](http://ejohn.org/blog/pure-javascript-html-parser/)

基本的 HTML 解析用法

```js
var results = "";

HTMLParser(html, {
  start: function(tag, attrs, unary) {
    results += "<" + tag;

    for (var i = 0; i < attrs.length; i++)
      results += " " + attrs[i].name + '="' + attrs[i].escaped + '"';

    results += (unary ? "/" : "") + ">";
  },
  end: function(tag) {
    results += "</" + tag + ">";
  },
  chars: function(text) {
    results += text;
  },
  comment: function(text) {
    results += "<!--" + text + "-->";
  }
});

return results;
```

可以看出它把 HTML 解析后对应的节点数据都传入了处理函数，Vue 在它的基础上做了升级与优化处理，在拿到对应的节点数据后做一些自己的解析处理，如 分析 v-if、v-for、v-on 等属性做指令处理，也就出来了 Vue 的模板系统~

### 响应式系统

下面在说下响应系统

数据响应主要是依据 ES5 的 getter 与 setter 来做数据变化的钩子处理，比如下面

```js
Object.defineProperty(obj, key, {
  enumerable: true,
  configurable: true,
  get: () => {
    // some handle
    return val;
  },
  set: newVal => {
    if (newVal === val) return;
    val = newVal;
    //some handle
  }
});
```

这样取值与赋值的过程中都可以做一些我们自己的处理，比如 set 的时候我们可以判断值是否真的发生了变化，变化了可以触发我们的重新渲染函数，做虚拟 DOM 比对处理更新界面

不过说明下并不是一旦有数据变动我们就要做重新渲染，看这个例子

```js
new Vue({
  template: `
        <div>
          <section>
            <span>name:</span> {{name}}
          </section>
          <section>
            <span>age:</span> {{age}}
          </section>
        <div>`,
  data: {
    name: "js",
    age: 24,
    height: 180
  }
});

setTimeout(function() {
  demo.height = 181;
}, 3000);
```

可以看到 height 的变动与我们的模板完全无关，如果做重渲染会造成浪费，所以 Vue 做了一个收集依赖

Vue 在第一次渲染的时候会读取需要的数据，所以它在 get 的时候做了手脚（依赖收集），后面只有依赖的数据变动才会触发重渲染

想更详细的了解数据响应的可以看看这个 [vue2.0 源码分析之理解响应式架构](https://segmentfault.com/a/1190000007334535)

不过 ES5 的 setter、getter，使用与处理起来还是有些麻烦与不便

所以数据方面我选择了这个 [https://github.com/nx-js/observer-util](https://github.com/nx-js/observer-util) 使用 Proxy 的库做响应处理（毕竟现在不考虑兼容性~）

实现原理与上面的差不多，只不过更简单，功能更强一些~

### 总结

上面就是我们主要参考的技能点，让我们加些代码把它们连起来，这样自己的框架就出来了

最终的实现代码在这里 [https://github.com/ygm125/evo](https://github.com/ygm125/evo)

evo = easy + vue + o，快来帮我 star 吧！

下面来个例子，跑起来

```js
<div id="app">
    <div :message="message">{{ message }}</div>

    <a v-for="(item,index) in list" @click="popMsg(item.text)">{{index}}、{{item.text}}</a>

    <my-component :message="message"></my-component>

    <div v-if="first">first</div>
    <div v-else>not</div>
</div>
<script src="../dist/evo.js"></script>
<script>

    var Child = {
        data: {
            text: 'component'
        },
        template: '<div>A custom {{text}} {{message}}!</div>'
    }

    var app = new Evo({
        components: {
            'my-component': Child
        },
        el: "#app",
        data: {
            first: true,
            message: "Hello Evo!",
            list: [{
                text: "Im one"
            }, {
                text: "Im two"
            }]
        },
        methods: {
            popMsg(msg) {
                alert(msg)
            }
        }
    })

    setTimeout(function(){
        app.message = 'HI'
    },1000)

</script>
```

当然实现一个完整的东西还是有很多路要走的，这是一个精雕细琢、不断升华的过程~
