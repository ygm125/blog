---
Layout: Layout
title: React 系列之 Flux
date: 2016-09-28 13:15:20
tags: [react, flux, javascript]
---

### 概述

由于 React 只涉及 UI 层的处理，所以构建大型应用应该搭配一个框架模式才能使后期维护成本相对较小~

Flux 正是 FB 官方给出的应用架构，他推崇一种单向的数据流动模式，看下图感受下

![](https://image-static.segmentfault.com/148/213/1482139906-57c5356ee7a2a_articlex)

整个流程是

- 用户与 View 层交互，触发 Action

- Action 使用 Dispatcher 进行分发

- Dispatcher 触发 Store 回调进行更新

- Store 更新触发 View 层事件

- View 层 收到信号进行更新

相对传统 MV\* 模式，Flux 一个最大的特色就是单向的数据流让事情变的可预见，看下面大型应用图感受下不同

MV\*

![](http://cc.cocimg.com/api/uploads/20150930/1443597860689661.jpg)

Flux

![](http://cc.cocimg.com/api/uploads/20150930/1443597957408505.jpg)

其实概念说了一堆还是比较难理解，大家可以配合 flux-todomvc 官方示例来直观感受理解下

app.js 渲染的是 TodoApp.react.js 这个组件，组件内部从 TodoStore 获取数据传递给子组件，同时监听了 TodoStore 的数据变化，FB 管这种顶层 View 叫做 Controller-View

TodoApp.react.js

```js
var TodoStore = require("../stores/TodoStore");

function getTodoState() {
  return {
    allTodos: TodoStore.getAll(),
    areAllComplete: TodoStore.areAllComplete()
  };
}

var TodoApp = React.createClass({
  getInitialState: function() {
    // 获取初始数据
    return getTodoState();
  },

  componentDidMount: function() {
    // 监听数据变化
    TodoStore.addChangeListener(this._onChange);
  },

  render: function() {
    return (
      <div>
        <Header />
        <MainSection
          allTodos={this.state.allTodos}
          areAllComplete={this.state.areAllComplete}
        />
        <Footer allTodos={this.state.allTodos} />
      </div>
    );
  },

  _onChange: function() {
    this.setState(getTodoState());
  }
});
```

TodoApp.react.js 又嵌套了几个子组件，这里我们关注下 Header.react.js 这个子组件感受一下整个流程就好了

Header.react.js 的子组件 TodoTextInput.react.js 监听 dom 输入框的各种事件，触发父组件传递给他的 Action 方法

Header.react.js

```js
var TodoTextInput = require("./TodoTextInput.react");

var Header = React.createClass({
  render: function() {
    return (
      <header id="header">
        <h1>todos</h1>
        <TodoTextInput
          id="new-todo"
          placeholder="What needs to be done?"
          onSave={this._onSave}
        />
      </header>
    );
  },
  _onSave: function(text) {
    if (text.trim()) {
      TodoActions.create(text);
    }
  }
});
```

TodoTextInput.react.js

```js
var TodoTextInput = React.createClass({
  getInitialState: function() {
    return {
      value: this.props.value || ""
    };
  },

  render: function() {
    return (
      <input
        className={this.props.className}
        id={this.props.id}
        placeholder={this.props.placeholder}
        onBlur={this._save}
        onChange={this._onChange}
        onKeyDown={this._onKeyDown}
        value={this.state.value}
        autoFocus={true}
      />
    );
  },

  _save: function() {
    this.props.onSave(this.state.value);
    this.setState({
      value: ""
    });
  },

  _onChange: function(event) {
    this.setState({
      value: event.target.value
    });
  },

  _onKeyDown: function(event) {
    if (event.keyCode === ENTER_KEY_CODE) {
      this._save();
    }
  }
});
```

Action 执行 Dispatcher 进行行为分发，这里的 Dispatcher 是 FB 实现的一个事情分发系统

TodoActions.js

```js
var TodoActions = {
create: function(text) {
AppDispatcher.dispatch({
actionType: TodoConstants.TODO_CREATE,
text: text
});
},
...
}
```

Dispatcher 的分发会触发 Store 中注册的回调，执行对应的行为更新数据，同时触发 Store Change 事件，那么 TodoApp.react.js 中监听的 Store Change 事件就会触发，重新设置组件的 state 数据，致使 View 重新 render

TodoStore.js

```js
AppDispatcher.register(function(action) {
  var text;

  switch (action.actionType) {
    case TodoConstants.TODO_CREATE:
      text = action.text.trim();
      if (text !== "") {
        create(text);
        TodoStore.emitChange();
      }
      break;
    default:
    // no op
  }
});
```

这样就形成了 Flux 架构的单向闭环更新流，但是写起来还是有些繁琐和复杂性，下一节我们来看更简洁和优雅的方式 Redux ~
