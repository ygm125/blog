---
Layout: Layout
title: React 系列之 Redux
date: 2016-11-07 13:30:10
tags: [react, redux, javascript]
---

### 前言

没想到这篇文章这么晚才出，最近发生了太多的事情，已致于心态全无，很多事情只有经历才能感受真实，我们都需要成长

### 介绍

前面看到 Flux 架构相对来说还是比较繁琐，同时社区也涌现了很多第三方的框架模式，而 Redux 则脱颖而出

React 以组件的形式维护了一颗 UI 树，但是对状态数据没有做更多的处理，Redux 则把状态数据也抽象成了一棵树来维护

它本身与 React 没有直接关系，可以与其他框架配合使用，也可以很好的与 React 配合使用

Redux 的代码量非常短小，核心只提供了 5 个 API

- createStore

- combineReducers

- bindActionCreators

- applyMiddleware

- compose

下面先来直观的感受下 Redux

```js
import { createStore } from "redux";

function counter(state = 0, action) {
  switch (action.type) {
    case "INCREMENT":
      return state + 1;
    case "DECREMENT":
      return state - 1;
    default:
      return state;
  }
}

let store = createStore(counter);

store.subscribe(() => console.log(store.getState()));

store.dispatch({ type: "INCREMENT" });
// 1
store.dispatch({ type: "INCREMENT" });
// 2
store.dispatch({ type: "DECREMENT" });
// 1
```

表象可以看出入口是 createStore，接收一个函数（这里叫做 reducer），这个函数接收 state 与 action 俩个参数，然后 dispatch 一个对象（这里叫 action ,要包含一个 type 属性标明行为），reducer 函数就会被触发执行来操作状态，同时也会触发 subscribe 订阅的回调，回调可以通过 store.getState() 获取当前状态数据

到这里都很简单，那么如果我们需要处理的数据和状态越来越多 reducer 函数就会越来越大导致难以维护，所以 Redux 提供了 combineReducers 来处理这种情况，它把这个大的 reducer 分解成一个个小的 reducer ，每个小 reducer 维护自己的状态数据，这样就分解出了一个状态树

做下变种

reducers/todos.js

```js
export default function todos(state = [], action) {
  switch (action.type) {
    case "ADD_TODO":
      return state.concat([action.text]);
    default:
      return state;
  }
}
```

reducers/counter.js

```js
export default function counter(state = 0, action) {
  switch (action.type) {
    case "INCREMENT":
      return state + 1;
    case "DECREMENT":
      return state - 1;
    default:
      return state;
  }
}
```

reducers/index.js

```js
import { combineReducers } from "redux";
import todos from "./todos";
import counter from "./counter";

export default combineReducers({
  todos,
  counter
});
```

App.js

```js
import { createStore } from "redux";
import reducer from "./reducers/index";

let store = createStore(reducer);
console.log(store.getState());
// {
// counter: 0,
// todos: []
// }

store.dispatch({
  type: "ADD_TODO",
  text: "Use Redux"
});
console.log(store.getState());
// {
// counter: 0,
// todos: [ 'Use Redux' ]
// }
```

可以看到我们利用 combineReducers 把 reducer 做了拆分，combineReducers 部分精简源码

```js
export default function combineReducers(reducers) {
  var reducerKeys = Object.keys(reducers);
  var finalReducers = {};
  for (var i = 0; i < reducerKeys.length; i++) {
    var key = reducerKeys[i];
    if (typeof reducers[key] === "function") {
      finalReducers[key] = reducers[key];
    }
  }
  var finalReducerKeys = Object.keys(finalReducers);

  return function combination(state = {}, action) {
    var hasChanged = false;
    var nextState = {};
    for (var i = 0; i < finalReducerKeys.length; i++) {
      var key = finalReducerKeys[i];
      var reducer = finalReducers[key];
      var previousStateForKey = state[key];
      var nextStateForKey = reducer(previousStateForKey, action);
      nextState[key] = nextStateForKey;
      hasChanged = hasChanged || nextStateForKey !== previousStateForKey;
    }
    return hasChanged ? nextState : state;
  };
}
```

可以看到就是把对象中的 reducer 全部执行一遍，把上次的状态传入进去，最新的状态返回回来，当然你也可以提供自己的

combineReducers 方法

前面我们注意到 store.dispatch 都是一个纯对象，也就是说我们的触发都是同步的，如何支持异步？

下面我们来引入 Redux 中间件来增强下

```js
import { createStore, applyMiddleware } from "redux";
import thunk from "redux-thunk";
import rootReducer from "./reducers/index";

function increment() {
  return {
    type: "INCREMENT_COUNTER"
  };
}

function incrementAsync() {
  return dispatch => {
    setTimeout(() => {
      dispatch(increment());
    }, 1000);
  };
}

const store = createStore(rootReducer, applyMiddleware(thunk));

store.dispatch(increment()); // 同步

store.dispatch(incrementAsync()); // 异步
```

同步方式的触发跟以前是一样的，这里的异步支持就是靠 Redux 的 applyMiddleware 中间件模式与 thunk 中间件做增强支持的

来看下 applyMiddleware 与部分 createStore 源码

```js
export default function applyMiddleware(...middlewares) {
  return createStore => (reducer, preloadedState, enhancer) => {
    var store = createStore(reducer, preloadedState, enhancer);
    var dispatch = store.dispatch;
    var chain = [];

    var middlewareAPI = {
      getState: store.getState,
      dispatch: action => dispatch(action)
    };
    chain = middlewares.map(middleware => middleware(middlewareAPI));
    dispatch = compose(...chain)(store.dispatch);

    return {
      ...store,
      dispatch
    };
  };
}
```

```js
export default function createStore(reducer, preloadedState, enhancer) {
  if (typeof preloadedState === "function" && typeof enhancer === "undefined") {
    enhancer = preloadedState;
    preloadedState = undefined;
  }

  if (typeof enhancer !== "undefined") {
    return enhancer(createStore)(reducer, preloadedState);
  }

  //...

  return {
    dispatch,
    subscribe,
    getState,
    replaceReducer,
    [$$observable]: observable
  };
}
```

createStore 里所谓的增强就是 applyMiddleware 一些中间件

`const store = createStore( rootReducer, applyMiddleware(thunk) )`

与下面写法是等效的

`const store = applyMiddleware(thunk)(createStore)(rootReducer)`

看上面 applyMiddleware 的源码可以知道会先用 createStore 创建原始 store，然后把 getState 与 dispatch 传给中间件，中间件处理完后返回扩展后的 store

看下 thunk 中间件源码

```js
function createThunkMiddleware(extraArgument) {
  return ({ dispatch, getState }) => next => action => {
    if (typeof action === "function") {
      return action(dispatch, getState, extraArgument);
    }

    return next(action);
  };
}

const thunk = createThunkMiddleware();
thunk.withExtraArgument = createThunkMiddleware;

export default thunk;
```

很简单传入 dispatch, getState 后返回 next => action = > {...}，然后传入 store.dispatch 返回 action => {...} 即扩展后的 dispatch

这个新的 dispatch 也是接受 action，如果是对象用原始 store.dispatch 直接触发，如果是函数则把 dispatch 传进函数体，把控制权交给函数内部

注意后面执行用到的 dispatch 已是扩展后的能处理函数的 dispatch

回过头来在说下 compose API，applyMiddleware 可以接受一系列中间件，内部调用 compose 来做处理

`compose(...chain)` 等同于 `(...args) => f(g(h(...args)))`

也就是说传入一组函数，它会倒序执行，把前一个的执行结果传给下一个，达到渐进增强效果

说到这里 Redux 和 它的 API 终于介绍差不多了，至于 bindActionCreators 后面介绍

说了这么多可以看到 Redux 自己就可以跑，那如何与 React 结合起来？那就需要 react-redux 这个中间桥梁了

react-redux 提供了俩个 API

- Provider store

- connect([mapStateToProps], [mapDispatchToProps], [mergeProps], [options])

Provider 就是一个 React 组件，它接收一个 store 属性，把 store 挂在 React 的 Context 上，这样它的子组件不需要显示的传递 store 就可以获取到

看个例子

```js
import { Provider } from "react-redux";

const store = createStore(reducer);

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById("root")
);
```

那么问题来了，可以获取到 store 后呢，如何做交互以及 React 与 Redux 的沟通，这时候 connect API 就派上用场了

还是继续看个例子

```js
import { bindActionCreators } from "redux";

const App = ({ todos, actions }) => (
  <div>
    <Header addTodo={actions.addTodo} />
    <MainSection todos={todos} actions={actions} />
  </div>
);

const mapStateToProps = state => ({
  todos: state.todos
});

const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators(TodoActions, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(App);
```

connect 的源码执行大概是这样

```js
export default function connect(
  mapStateToProps,
  mapDispatchToProps,
  mergeProps,
  options = {}
) {
  return function wrapWithConnect(WrappedComponent) {
    class Connect extends Component {
      constructor(props, context) {
        this.store = props.store || context.store;
      }

      render() {
        const mappedState = mapStateToProps(store.getState(), this.props);
        const mappedDispatch = mapDispatchToProps(store.dispatch, this.props);

        const mergedProps = {
          mappedState,
          mappedDispatch
        };

        this.renderedElement = createElement(WrappedComponent, mergedProps);
        return this.renderedElement;
      }
    }
  };
}
```

这里做了适当的简化，从这可以看出 connect 返回了一个 Connect 组件获取到 store，然后把 store.getState() 与 store.dispatch

传递给我们的 mapStateToProps 与 mapDispatchToProps 函数，返回相应的数据与方法通过 props 传递给 React 组件，这样 React 组件就可以获取到相应数据展示，同时也可以通过 dispatch 触发 Redux store 的数据变动，Connect 组件在根据数据对比看是否需要重新渲染~

connect 实际的代码比这复杂的多，内部做了细致的浅数据对比以提升性能

对于 react-redux 这里还有一个潜规则，那就是展示组件与容器组件相分离，就是说只有容器组件处理数据与状态与 Redux 沟通，

展示组件只做正常的 UI 渲染，可以从这里了解更多 [https://redux.js.org/basics/usage-with-react](https://redux.js.org/basics/usage-with-react)

再看下上面的

```js
const mapDispatchToProps = dispatch => ({
  actions: bindActionCreators(TodoActions, dispatch)
});
```

会把传入的函数或对象的每一个方法做下面的变形

```js
function bindActionCreator(actionCreator, dispatch) {
  return (...args) => dispatch(actionCreator(...args));
}
```

这样 React 组件调用对应的 action 时就可以 dispatch 这个 actionCreator 产生的数据

最终不管有没有明白都可以看下 [Redux TodoMVC Example](https://github.com/reduxjs/redux/tree/master/examples/todomvc)

这个例子来加深下理解，以及目录结构的分工，当然有兴趣多了解一些例子就更好了

这篇到这里终于算是写完了，最后大家加油！
