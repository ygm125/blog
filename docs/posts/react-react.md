---
Layout: Layout
title: React 系列之 React
date: 2016-09-08 22:35:59
tags: [react, javascript, mvvm]
---

### 概述

React 是一个 JS 库，主要是通过操作数据的方式去操纵 DOM，为什么要重造轮子呢，因为 FB 觉的目前市面上的 MV\* 框架对于创建大型应用程序不够直观，不能满足需求，所以诞生了 React。

React 现在官方的介绍是 Declarative、Component-Based、Learn Once, Write Anywhere，其实开始推出时主要的特色是 Virtual DOM，因为 DOM 操作总是很慢的，而 JS 的性能日趋向上，所以 React 内部用 JS 维护一颗 DOM 树，每次数据变了从新生成一颗树与之前的做对比，把实际变化的地方应用到真实的 DOM 上。其实说它性能高，只不过是用 JS 的方式计算出最小的 DOM 操作，所以性能就上来了。

### 演练

说到这里我们实际操作下吧，这里假设你熟悉 node、babel、webpack 方式，当然你也可以选择你喜好的方式 [传送门](https://reactjs.org/docs/getting-started.html)

首先创建目录结构

```
react-demo
    .babelrc
    index.html
    src
        app.js
```

index.html

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>React App</title>
  </head>
  <body>
    <div id="app"></div>
    <script src="bundle.js"></script>
  </body>
</html>
```

app.js

```js
var React = require("react");
var ReactDOM = require("react-dom");

var HelloMessage = React.createClass({
  render: function() {
    return <div>Hello {this.props.name}</div>;
  }
});

ReactDOM.render(<HelloMessage name="John" />, document.getElementById("app"));
```

.babelrc

```js
{ "presets": ["es2015","react"] }
```

安装依赖

`npm install --save react react-dom babel-preset-react babel-loader babel-core`

编译监听

`webpack src/app.js bundle.js -w --module-bind 'js=babel'`

打开 index.html 查看效果

先说下 jsx 语法，React 让你不需要再写 html 拼接字符等操作，而是直接写 html，js 处理放到 { } 里书写，官方提供 jsx 语法非必要，也可以脱离写纯 js 的，如上面的经过编译后

```js
"use strict";

var HelloMessage = React.createClass({
  displayName: "HelloMessage",

  render: function render() {
    return React.createElement("div", null, "Hello ", this.props.name);
  }
});

ReactDOM.render(
  React.createElement(HelloMessage, { name: "John" }),
  document.getElementById("app")
);
```

但是可以看出这么麻烦没人去手写的

再来说下组件，React 的概念就是给应用分层，创建一个个组件，最后拼出一个页面，组件方便后期的维护、扩展、以及再重用，随着组件的越多后面写的代码越少，来个例子

```js
var Avatar = React.createClass({
  render: function() {
    return (
      <div>
        <PagePic pagename={this.props.pagename} />
        <PageLink pagename={this.props.pagename} />
      </div>
    );
  }
});

var PagePic = React.createClass({
  render: function() {
    return (
      <img
        src={"https://graph.facebook.com/" + this.props.pagename + "/picture"}
      />
    );
  }
});

var PageLink = React.createClass({
  render: function() {
    return (
      <a href={"https://www.facebook.com/" + this.props.pagename}>
        {this.props.pagename}
      </a>
    );
  }
});

ReactDOM.render(
  <Avatar pagename="Engineering" />,
  document.getElementById("app")
);
```

可以看到组件要提供自己的 render 方法，组件可以相互嵌套，数据通过 this.props 单向传递

同时需要注意，属性 class 要写成 className，for 写成 htmlFor，因为它们是 js 的保留字

对于 render 返回的内容只能有一个顶级标签，如果标签超过多行要用 ( ) 包含

关于 props 不要去改变它，会导致一些不可预知的问题，另外官方推荐用 es6 的 ... 操作符去挂载属性

```js
var props = { foo: "default", bar: "bar" };
var component = <Component {...props} foo={"override"} />;
console.log(component.props.bar); // 'bar'
console.log(component.props.foo); // 'override'
```

这里有个特殊属性 this.props.children，来个例子

```js
var NotesList = React.createClass({
  propTypes: {
    children: React.PropTypes.array.isRequired
  },
  render: function() {
    return (
      <ol>
        {React.Children.map(this.props.children, function(child) {
          return <li>{child}</li>;
        })}
      </ol>
    );
  }
});

ReactDOM.render(
  <NotesList>
    <span>hello</span>
    <span>world</span>
  </NotesList>,
  document.getElementById("app")
);
```

同时可以看到这里提供了 propTypes 可以给属性做检查，验证说明 children 必须提供且是一个数组(多个)，更多的类型验证可以 看这里

前面创建组件都是通过 React.createClass ，可以通过 es6 class 语法

```js
class HelloMessage extends React.Component {
  render() {
    return <div>Hello {this.props.name}</div>;
  }
}
ReactDOM.render(
  <HelloMessage name="Sebastian" />,
  document.getElementById("app")
);
```

还有 Stateless Functions 方式

```js
function HelloMessage(props) {
  return <div>Hello {props.name}</div>;
}
ReactDOM.render(
  <HelloMessage name="Sebastian" />,
  document.getElementById("app")
);
```

官方推荐尽量写 stateless functions ，因为未来会优化这些来避免无用的检查和内存分配

下面看下如何写事件

```js
var Input = React.createClass({
  getInitialState: function() {
    return { value: "Hello!" };
  },
  handleChange: function(event) {
    this.setState({ value: event.target.value });
  },
  render: function() {
    var value = this.state.value;
    return (
      <div>
        <input type="text" value={value} onChange={this.handleChange} />
        <p>{value}</p>
      </div>
    );
  }
});

ReactDOM.render(<Input />, document.getElementById("app"));
```

骆驼式的 on 语法即可监听事件，事件是标准的跨浏览器的事件，虽然内联写法，但是是委托实现的~

说到了事件交互可能就要设及获取真实的 dom 节点，React 通过 ref 设置，来个例子

```js
var React = require("react");
var ReactDOM = require("react-dom");

var MyComponent = React.createClass({
  handleClick: function() {
    this.refs["myinput"].focus();
  },
  render: function() {
    return (
      <div>
        <input type="text" ref="myinput" />
        <input
          type="button"
          value="Focus the text input"
          onClick={this.handleClick}
        />
      </div>
    );
  }
});

ReactDOM.render(<MyComponent />, document.getElementById("app"));
```

ref 字符属性的方式未来会被废弃，官方推荐使用 ref callback 方式

```js
var MyComponent = React.createClass({
  handleClick: function() {
    if (this.myTextInput !== null) {
      this.myTextInput.focus();
    }
  },
  render: function() {
    return (
      <div>
        <input type="text" ref={ref => (this.myTextInput = ref)} />
        <input
          type="button"
          value="Focus the text input"
          onClick={this.handleClick}
        />
      </div>
    );
  }
});

ReactDOM.render(<MyComponent />, document.getElementById("app"));
```

说到这里看下组件的生命周期与如何更新，还是来个例子

```js
var Timer = React.createClass({
  getInitialState: function() {
    return { secondsElapsed: 0 };
  },
  tick: function() {
    this.setState({ secondsElapsed: this.state.secondsElapsed + 1 });
  },
  componentDidMount: function() {
    this.interval = setInterval(this.tick, 1000);
  },
  componentWillUnmount: function() {
    clearInterval(this.interval);
  },
  render: function() {
    return <div>Seconds Elapsed: {this.state.secondsElapsed}</div>;
  }
});

ReactDOM.render(<Timer />, document.getElementById("app"));
```

生命周期有三个主要部分

Mounting 插入 dom

- getInitialState()

- componentWillMount()

- componentDidMount ()

Updating 重新渲染

- componentWillReceiveProps(object nextProps)

- shouldComponentUpdate(object nextProps, object nextState)

- componentWillUpdate(object nextProps, object nextState)

- componentDidUpdate(object prevProps, object prevState)

Unmounting 移除 dom

- componentWillUnmount()

周期提供了 will 方法在事情发生之前调用， did 方法在事情法神之后调用，具体查看这里

对于更新，上面的例子在组件 componentDidMount (插入 dom 后) hook 中定时更新组件的 state，state 变更会导致 render 重新渲染页面

对于这里说下性能问题，虽然虚拟 dom 计算过程很快，但是很多时候我们可以避免它的计算以更好的优化处理

例如：一个组件的更新可能会导致它的子组件一起跟着更新，子组件很可能没有变化，但同样会进行一次 diff 运算，白白浪费了时间，所以 React 提供了 shouldComponentUpdate 钩子函数，默认是直接返回 true，也及是每次都运算比较，所以我们可以在这里优化，来个例子

```js
React.createClass({
  propTypes: {
    value: React.PropTypes.string.isRequired
  },
  shouldComponentUpdate: function(nextProps, nextState) {
    return this.props.value !== nextProps.value;
  },
  render: function() {
    return <div>{this.props.value}</div>;
  }
});
```

这里只有 value 变化的时候在重新渲染计算，否则直接跳过

对于上面的浅对比，React 提供了通用解决方案 PureRenderMixin 扩展，应用 React 的 mixins 功能即可自动实现处理比对

```js
var PureRenderMixin = require("react-addons-pure-render-mixin");
React.createClass({
  mixins: [PureRenderMixin],

  render: function() {
    return <div>{this.props.value}</div>;
  }
});
```

但是如果有深层结构，上面的处理可能不会按预期工作，例如

```
// this.props.value 的值为 { foo: 'bar' }
// nextProps.value 的值为 { foo: 'bar' }
// 但是对象的引用不同，导致不会相等
this.props.value !== nextProps.value; // true
```

而且如果我们不小心管理引用的话也会引发另一些问题，例如这个组件有一个父组件

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

首先内部组件得到 { foo: 'bar' }，点击后出发 value 更新 { foo: 'barbar' },触发 re-rendering 程序，内部组件将会得到 { foo: 'barbar' }，但是 this.props.value 与 nextProps.value 指向同一个引用，导致任何时候比对都是 true，而导致页面不更新

而且如果父组件应用 PureRenderMixin 的话，由于改动相同引用所以也会导致父组件的 re-rendering 不触发

那最后该如何处理呢？请看下一篇 Immutable-js 来解救你~
