---
Layout: Layout
title: React 系列之 Immutable
date: 2016-09-20 22:10:22
tags: [react, immutable, javascript]
---

### 介绍

什么是 Immutable Data ？
Immutable Data 是指一旦被创建就不可以被改变的数据，通过使用不可变数据可以让我们很方便的去处理数据的状态、变化检测等问题，而且让我们的程序变得更加的可预见

### 使用

安装 `npm install immutable`

```js
var Immutable = require("immutable");
var map1 = Immutable.Map({ a: 1, b: 2, c: 3 });
var map2 = map1.set("b", 50);
map1.get("b"); // 2
map2.get("b"); // 50
```

大体 API

```js
// 深度转换 JS Object 和 Array 为 Immutable Map 和 List
Immutable.fromJS({ a: { b: [10, 20, 30] }, c: 40 });

// Immutable.List 浅转换
const $arr1 = Immutable.List([1, 2, 3]);
$arr1.size;
// => 3

// 给倒数第一个赋值
const $arr2 = $arr1.set(-1, 0);
// => List [ 1, 2, 0 ]

const $arr3 = $arr1.insert(1, 1.5);
// => List [ 1, 1.5, 2, 3 ]

const $arr4 = $arr1.clear();
// => List []

const $arr5 = $arr1.get(0);
// => 1

// Immutable Map
const $map1 = Immutable.fromJS({ a: { b: 1 }, c: 2 });
$map1.size;
// => 2

const $map2 = $map1.update("c", () => 3);
// => Map { "a": Map { "b": 1 }, "c": 3 }

const $map3 = $map1.updateIn("a.b", () => 3);
// => Map { "a": Map { "b": 3 }, "c": 2 }

const $map4 = $map1.merge({ d: 4 });
// => Map { "a": Map { "b": 1 }, "c": 2, "d": 4 }
```

更多可以查看 [immutable-js](https://immutable-js.github.io/immutable-js/)

为什么要用 Immutable
其实从上面的简单例子可以看出来对原数据的操作我们重新生成一个新的而不影响原来的就好了

JQ 有提供 \$.extend 可以实现浅拷贝与深拷贝，另外 ES6 也提供原生的方法 Object. assign (浅拷贝)，但其实我们大多数情况我们的数据都很复杂，浅拷贝满足不了，然而对于深拷贝 Immutable 的性能很高

这是因为一般深拷贝都是把所以节点全都复制一遍，而 Immutable 使用结构共享，及对象树中的一个节点变化则只会修改这个节点和受她影响的父节点，其他节进行共享，可以看下下面这个图感受下

![](https://image-static.segmentfault.com/403/933/4039331718-56cc22613b287_articlex)

配合 React 使用
来看一下上一章留下的问题

```js
import React from "react";
import PureRenderMixin from "react-addons-pure-render-mixin";
import { Map } from "immutable";

var Test = React.createClass({
  mixins: [PureRenderMixin],
  getInitialState: function() {
    return { value: { foo: "bar" } };
  },
  onClick: function() {
    this.setState({
      value: { foo: "bar" }
    });
  },
  render: function() {
    console.log("re-render");
    return <a onClick={this.onClick}>click</a>;
  }
});
```

由于对比的是俩个引用不同的对象，所以每次都会触发 re-render，使用 Immutable 后

```js
var Test = React.createClass({
  mixins: [PureRenderMixin],
  getInitialState: function() {
    return { value: Map({ foo: "bar" }) };
  },
  onClick: function() {
    this.setState(({ value }) => ({
      value: value.set("foo", "bar")
    }));
  },
  render: function() {
    console.log("re-render");
    return <a onClick={this.onClick}>click</a>;
  }
});
```

值相同时 Immutable 会返回同一个引用，所以比对后，不会触发 re-render

对于父组件

```js
React.createClass({
  getInitialState: function() {
    return { value: { foo: "bar" } };
  },

  onClick: function() {
    var value = this.state.value;
    value.foo += "bar"; // ANTI-PATTERN!
    this.setState({ value: value });
  },

  render: function() {
    return (
      <div>
        <InnerComponent value={this.state.value} />
        <a onClick={this.onClick}>Click me</a>
      </div>
    );
  }
});
```

改造后

```js
var Test = React.createClass({
  getInitialState: function() {
    return { value: Map({ foo: "bar" }) };
  },
  onClick: function() {
    this.setState(({ value }) => ({
      value: value.update("foo", v => v + "bar")
    }));
  },
  render: function() {
    return (
      <div>
        <InnerComponent value={this.state.value} />
        <a onClick={this.onClick}>Click me</a>
      </div>
    );
  }
});
```

可以预见的是组件一定会更新，因为每次 Immutable Data 更改都会返回一个新对象，而不影响原来对象~
