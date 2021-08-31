# NavigationViewKit #

NavigationViewKit是一个SwiftUI的NavigationView扩展库。

更详细的文档和演示，请访问[用NavigationViewKit增强SwiftUI的导航视图](https://www.fatbobman.com/posts/NavigationViewKit/)

该扩展遵循以下几个原则：

* 非破坏性

  任何新添加的功能都不能影响当前SwiftUI提供的原生功能，尤其是不能影响例如`Toolbar`、`NavigationLink`在NavigationView中的表现

* 尽可能便于使用

  仅需极少的代码便可使用新增功能

* SwiftUI原生风格

  扩展功能的调用方法尽可能同原生SwiftUI方式类似



## NavigationViewManager #

### 简介 ###

开发者对NavigationView最大抱怨之一就是不支持便捷的返回根视图手段。目前常用的解决方案有两种：

* 重新包装`UINavigationController`

  好的包装确实可以使用到`UINavigationController`提供的众多功能，不过非常容易同SwiftUI中的原生方法相冲突，鱼和熊掌不可兼得

* 使用程序化的`NavigationLink`

  通过撤销根视图的程序化的`NavigationLink`（通常是`isActive`）来返回。此种手段将限制`NavigationLink`的种类选择，另外不利于从非视图代码中实现。

`NavigationViewManager`是NavigationViewKit中提供的导航视图管理器，它提供如下功能：

* 可以管理应用程序中全部的NavigationView
* 支持从NavigationView下的任意视图通过代码直接返回根视图
* 在NavigationView下的任意视图中通过代码直接跳转到新视图（无需在视图中描述`NavigationLink`）
* 通过`NotificatiionCenter`，指定应用程序中的任意NavigationView返回根视图
* 通过`NotificatiionCenter`，让应用程序中任意的NavigationView跳转到新视图
* 支持转场动画的开启关闭

### 注册NavigationView ###

由于`NavigationgViewManager`支持多导航视图管理，因此需要为每个受管理的导航视图进行注册。

```swift 
import NavigationViewKit
NavigationView {
            List(0..<10) { _ in
                NavigationLink("abc", destination: DetailView())
            }
        }
        .navigationViewManager(for: "nv1", afterBackDo: {print("back to root") })
```

`navigationViewManager`是一个View扩展，定义如下：

```swift
extension View {
    public func navigationViewManager(for tag: String, afterBackDo cleanAction: @escaping () -> Void = {}) -> some View
}
```

`for`为当前注册的`NavigationView`的名称（或tag），`afterBackDo`为当转到根视图后执行的代码段。

应用程序中每个被管理的`NavigationView`的tag需唯一。

### 从视图中返回根视图 ###

在注册过的`NavigationView`的任意子视图中，可以通过下面的代码实现返回根视图：

```swift
@Environment(\.navigationManager) var nvmanager         

Button("back to root view") {
    nvmanager.wrappedValue.popToRoot(tag:"nv1"){
          	 print("other back")
           }
}
```

`popToRoot`定义如下：

```swift
func popToRoot(tag: String, animated: Bool = true, action: @escaping () -> Void = {})
```

`tag`为当前NavigationView的注册Tag，`animated`设置返回根视图时是否显示转场动画，`action`为进一步的善后代码段。该段代码将执行在注册代码段（`afterBackDo`）之后，主要用于传递当前视图中的数据。

可以通过

```swift
@Environment(\.currentNaviationViewName) var tag
```

获取到当前NavigationView的注册Tag，便于视图在不同的NavigtionView中复用

```swift
struct DetailView: View {
    @Environment(\.navigationManager) var nvmanager
    @Environment(\.currentNaviationViewName) var tag
    var body: some View {
        VStack {
            Button("back to root view") {
                if let tag = tag {
                    nvmanager.wrappedValue.popToRoot(tag:tag,animated: false) {
                        print("other back")
                    }
                }
            }
        }
    }
}
```

### 使用NotificationCenter返回根视图 ###

由于NavigationViewManager在我的app中主要的用途是处理`Deep Link`，绝大多数的时间都不是在视图代码中调用的。因此NavigationViewManager提供了基于`NotificationCenter`的类似方法。

在代码中使用:

```swift
let backToRootItem = NavigationViewManager.BackToRootItem(tag: "nv1", animated: false, action: {})
NotificationCenter.default.post(name: .NavigationViewManagerBackToRoot, object: backToRootItem)
```

让指定的NavigationView返回到根视图。


### 从视图中跳转到新视图 ###

在视图代码中使用:

```swift
@Environment(\.navigationManager) var nvmanager

Button("go to new View"){
        nvmanager.wrappedValue.pushView(tag:"nv1",animated: true){
            Text("New View")
                .navigationTitle("new view")
        }
}
```

`pushView`的定义如下：

```swift
func pushView<V: View>(tag: String, animated: Bool = true, @ViewBuilder view: () -> V)
```

`tag`为NavigationView的注册Tag，`animation`设置是否显示转场动画，`view`为新视图。视图中支持SwiftUI原生的所有定义，例如`toolbar`、`navigationTitle`等。

目前在启用转场动画时，title和toolbar会在转场动画后才显示，观感稍有不足。日后尝试解决。

### 使用NotificationCenter跳转到新视图 ###

在代码中：

```swift
let pushViewItem = NavigationViewManager.PushViewItem(tag: "nv1", animated: false) {
                    AnyView(
                        Text("New View")
                            .navigationTitle("第四级视图")
                    )
                }
NotificationCenter.default.post(name:.NavigationViewManagerPushView, object: pushViewItem)
```

通过NotificationCenter跳转视图时，视图需转换为`AnyView`。


## DoubleColoumnJustForPadNavigationViewStyle ##

`DoubleColoumnJustForPadNavigationViewStyle`是`DoubleColoumnNavigationViewStyle`的修改版，其目改善iPhone和iPad使用同一套代码时，`DoubleColoumnNavigationViewStyle`在iPhone Max上横屏时的表现同其他iPhone机型不同。

当iPhone Max横屏时，NavigationView的表现会同iPad一样双列显示，让应用程序在不同iPhone上的表现不一致。

使用`DoubleColoumnJustForPadNavigationViewStyle`时，iPhone Max在横屏时仍呈现`StackNavigationViewStyle`的式样。

使用方法：

```swift
NavigationView{
   ...
}
.navigationViewStyle(DoubleColoumnJustForPadNavigationViewStyle())
```

在swift 5.5下可以直接使用

```swift
.navigationViewStyle(.columnsForPad)
```

## TipOnceDoubleColumnNavigationViewStyle ##

当前`DoubleColumnNavigationViewStyle`在iPad上横竖屏的表现不同。当竖屏时，左侧栏默认会隐藏，容易让新用户无所适从。

`TipOnceDoubleColumnNavigationViewStyle`会在iPad首次进入竖屏状态时，将左侧栏显示在右侧栏上方，提醒使用者。该提醒只会进行一次。提醒后旋转了方向，再次进入竖屏状态则不会二次触发提醒。

```swift
NavigationView{
   ...
}
.navigationViewStyle(TipOnceDoubleColumnNavigationViewStyle())
```

在Swift 5.5下可以直接使用

```swift
.navigationViewStyle(.tipColumns)
```


## FixDoubleColumnNavigationViewStyle ##

在[健康笔记](https://www.fatbobman.com/healthnotes/)中，我希望iPad版本无论在横屏或竖屏时，都始终能够保持两栏显示的状态，且左侧栏不可隐藏。

我之前使用了HStack套两个NavigationView来达到这个效果

现在，可以直接NavigationViewKit中的`FixDoubleColumnNavigationViewStyle`轻松实现上述效果。

```swift
NavigationView{
   ...
}
.navigationViewStyle(FixDoubleColumnNavigationViewStyle(widthForLandscape: 350, widthForPortrait:250))
```

并且可以为横屏竖屏两种状态分别设置左侧栏宽度。

更详细的文档和演示，请访问[用NavigationViewKit增强SwiftUI的导航视图](https://www.fatbobman.com/posts/NavigationViewKit/)

