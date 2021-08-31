# NavigationViewKit #

[中文版说明](READMECN.md)

NavigationViewKit is a NavigationView extension library for SwiftUI.

For more detailed documentation and demo, please visit [用NavigationViewKit增强SwiftUI的导航视图](https://www.fatbobman.com/posts/NavigationViewKit/)

The extension follows several principles.

* Non-disruptive

Any new feature does not affect the native functionality provided by Swiftui, especially if it does not affect the performance of Toolbar, NavigationLink in NavigationView

* Be as easy to use as possible

  Add new features with minimal code

* SwiftUI native style

  Extensions should be called in the same way as the native SwiftUI as much as possible


## NavigationViewManager ##

### Introduction ###

One of the biggest complaints from developers about NavigationView is that it does not support a convenient means of returning to the root view. There are two commonly used solutions.

* Repackage the `UINavigationController`

  A good wrapper can indeed use the many functions provided by `UINavigationController`, but it is very easy to conflict with the native methods in SwiftUI, so you can't have both.

* Use procedural `NavigationLink

  Return the programmed `NavigationLink` (usually `isActive`) by undoing the root view. This means will limit the variety of `NavigationLink` options, plus is not conducive to implementation from non-view code.

`NavigationViewManager` is the navigation view manager provided in NavigationViewKit, it provides the following functions.

* Can manage all the NavigationView in the application
* Support to return the root view directly from any view under NavigationView by code
* Jump to a new view via code from any view under NavigationView (no need to describe `NavigationLink` in the view)
* Return to the root view via `NotificatiionCenter` for any NavigationView in the specified application
* By `NotificatiionCenter`, let any NavigationView in the application jump to the new view
* Support transition animation on and off

### Register NavigationView ###

Since `NavigationgViewManager` supports multiple navigation views management, you need to register for each managed navigation view.


```swift 
import NavigationViewKit
NavigationView {
            List(0..<10) { _ in
                NavigationLink("abc", destination: DetailView())
            }
        }
        .navigationViewManager(for: "nv1", afterBackDo: {print("back to root") })
```

`navigationViewManager` is a View extension, defined as follows.

```swift
extension View {
    public func navigationViewManager(for tag: String, afterBackDo cleanAction: @escaping () -> Void = {}) -> some View
}
```

`for` is the name (or tag) of the currently registered `NavigationView`, `afterBackDo` is the code segment executed when going to the root view.

The tag of each managed `NavigationView` in the application needs to be unique.

### Returning to the root view from a view ###

In any sub-view of a registered `NavigationView`, the return to the root view can be achieved with the following code.

```swift
@Environment(\.navigationManager) var nvmanager         

Button("back to root view") {
    nvmanager.wrappedValue.popToRoot(tag:"nv1"){
          	 print("other back")
           }
}
```

`popToRoot` is defined as follows.

```swift
func popToRoot(tag: String, animated: Bool = true, action: @escaping () -> Void = {})
```

`tag` is the registered Tag of the current NavigationView, `animated` sets whether to show the transition animation when returning to the root view, and `action` is the further after-back code segment. This code will be executed after the registration code segment (`afterBackDo`) and is mainly used to pass the data in the current view.

This can be done via the

```swift
@Environment(\.currentNaviationViewName) var tag
```

Get the registered Tag of the current NavigationView, so that the view can be reused in different NavigtionViews.

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

### Using NotificationCenter to return to the root view ###

Since the main use of NavigationViewManager in my app is to handle `Deep Link`, the vast majority of the time it is not called in the view code. So NavigationViewManager provides a similar method based on `NotificationCenter`.

In the code using :

```swift
let backToRootItem = NavigationViewManager.BackToRootItem(tag: "nv1", animated: false, action: {})
NotificationCenter.default.post(name: .NavigationViewManagerBackToRoot, object: backToRootItem)
```


Returns the specified NavigationView to the root view.


### Jump from a view to a new view ###

Use :


```swift
@Environment(\.navigationManager) var nvmanager

Button("go to new View"){
        nvmanager.wrappedValue.pushView(tag:"nv1",animated: true){
            Text("New View")
                .navigationTitle("new view")
        }
}
```

The definition of `pushView` is as follows.

```swift
func pushView<V: View>(tag: String, animated: Bool = true, @ViewBuilder view: () -> V)
```

`tag` is the registered Tag of NavigationView, `animation` sets whether to show the transition animation, `view` is the new view. The view supports all definitions native to SwiftUI, such as `toolbar`, `navigationTitle`, etc.

At the moment, when transition animation is enabled, title and toolbar will be shown after the transition animation, so the view is a little bit short. I will try to fix it in the future.

### Use NotificationCenter to jump to new view ###

In the code.

```swift
let pushViewItem = NavigationViewManager.PushViewItem(tag: "nv1", animated: false) {
                    AnyView(
                        Text("New View")
                            .navigationTitle("第四级视图")
                    )
                }
NotificationCenter.default.post(name:.NavigationViewManagerPushView, object: pushViewItem)
```

`tag` is the registered Tag of NavigationView, `animation` sets whether to show the transition animation, `view` is the new view. The view supports all definitions native to SwiftUI, such as `toolbar`, `navigationTitle`, etc.

At the moment, when transition animation is enabled, title and toolbar will be shown after the transition animation, so the view is a little bit short. I will try to fix it in the future.

### Use NotificationCenter to jump to new view ###

In the code.


## DoubleColoumnJustForPadNavigationViewStyle ##

`DoubleColoumnJustForPadNavigationViewStyle` is a modified version of `DoubleColoumnNavigationViewStyle`, its purpose is to improve the performance of `DoubleColoumnNavigationViewStyle` in landscape on iPhone Max when iPhone and iPad use the same set of code, and different from other iPhone models.

When iPhone Max is in landscape, the NavigationView will behave like iPad with double columns, which makes the application behave inconsistently on different iPhones.

When using `DoubleColoumnJustForPadNavigationViewStyle`, iPhone Max will still show `StackNavigationViewStyle` in landscape.

Usage.

```swift
NavigationView{
   ...
}
.navigationViewStyle(DoubleColoumnJustForPadNavigationViewStyle())
```

It can be used directly under swift 5.5

```swift
.navigationViewStyle(.columnsForPad)
```

## TipOnceDoubleColumnNavigationViewStyle ##

The current `DoubleColumnNavigationViewStyle` behaves differently on iPad in both horizontal and vertical screens. When the screen is vertical, the left column is hidden by default, making it easy for new users to get confused.

`TipOnceDoubleColumnNavigationViewStyle` will show the left column above the right column to remind the user when the iPad is in vertical screen for the first time. This reminder will only happen once. If you rotate the orientation after the reminder, the reminder will not be triggered again when you enter the vertical screen again.


```swift
NavigationView{
   ...
}
.navigationViewStyle(TipOnceDoubleColumnNavigationViewStyle())
```

It can be used directly under swift 5.5

```swift
.navigationViewStyle(.tipColumns)
```


## FixDoubleColumnNavigationViewStyle ##

In [Health Notes](https://www.fatbobman.com/healthnotes/), I want the iPad version to always keep two columns displayed no matter in landscape or portrait, and the left column cannot be hidden.

I previously used HStack set of two NavigationView to achieve this effect

Now, the above effect can be easily achieved by `FixDoubleColumnNavigationViewStyle` in NavigationViewKit directly.

```swift
NavigationView{
   ...
}
.navigationViewStyle(FixDoubleColumnNavigationViewStyle(widthForLandscape: 350, widthForPortrait:250))
```

And you can set the left column width separately for both landscape and portrait states.

For more detailed documentation and demo, please visit [My Blog](https://www.fatbobman.com/)

