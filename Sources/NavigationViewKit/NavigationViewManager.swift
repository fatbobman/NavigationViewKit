//
//  NavigationViewManager.swift
//  NavigationViewManager
//
//  Created by Yang Xu on 2021/8/31.
//  www.fatbobman.com
//

import Combine
import SwiftUI

/// NavigationView管理器，支持直接返回根视图和直接push新视图
/// 在视图中使用NavigationViewManager范例：
/// ```swift
///     NavigationView{
///         ...
///     }
///     .allowPopToRoot(tag: "nv1", cleanAction: { print("back to root") })
///
/// //在任意视图中使用
///     @Environment(\.navigationManager) var nvmanager
/// // 返回根视图
///     nvmanager.wrappedValue.popToRoot(tag: "nv1", animated: true, action: { print("back from view") })
/// // 添加新视图
///     nvmanager.wrappedValue.pushView(tag: "test2"){
///                 Text("abc")
///                     .navigationTitle("hello world")
///                     .toolbar{
///                         ToolbarItem{
///                                 Button("test2"){}
///                                     }
///                             }
///                       }
/// ```
public class NavigationViewManager {
    private var contorllers: [String: ControllerItem] = [:]
    private var cancllables: Set<AnyCancellable> = []

    public init() {
        NotificationCenter.default.publisher(for: .NavigationViewManagerBackToRoot, object: nil)
            .sink(receiveValue: { notification in
                self.backToRootObsever(notification: notification)
            })
            .store(in: &cancllables)

        NotificationCenter.default.publisher(for: .NavigationViewManagerPushView, object: nil)
            .sink(receiveValue: { notification in
                self.pushViewObsever(notification: notification)
            })
            .store(in: &cancllables)
    }

    /// 注册UINavigationController
    /// - Parameters:
    ///   - controller: UINavigationController
    ///   - tag: NavigationView的名字（自定义）。用于分辨同一app中的多个NavigationView
    ///   - cleanAction: 返回根目录后执行的代码段
    func addController(controller: UINavigationController, tag: String, cleanAction: @escaping () -> Void = {}) {
        contorllers[tag] = ControllerItem(controller: controller, cleanAction: cleanAction)
        print(contorllers)
    }

    /// 返回根视图
    /// - Parameters:
    ///   - tag: NavigationView的名字（自定义）。用于分辨同一app中的多个NavigationView
    ///   - animated: 是否在返回时使用动画
    ///   - action: 返回后执行的代码段。该代码段的执行顺序在cleanAction之后
    public func popToRoot(tag: String, animated: Bool = true, action: @escaping () -> Void = {}) {
        contorllers[tag]?.controller.popToRootViewController(animated: animated)
        contorllers[tag]?.cleanAction()
        action()
    }

    /// 直接添加一个新视图到指定的NavigationView中
    /// - Parameters:
    ///   - tag: NavigationView的名字（自定义）。用于分辨同一app中的多个NavigationView
    ///   - animated: 转换至新视图是否使用动画
    ///   - view: 视图内容
    public func pushView<V: View>(tag: String, animated: Bool = true, @ViewBuilder view: () -> V) {
        guard let controllerItem = contorllers[tag] else { return }
        controllerItem.controller.pushViewController(UIHostingController(rootView: view()), animated: animated)
    }

    /// 删除已注册的NavigationView，除非在app中NavigationView会很多且动态出现，否则无需使用
    /// - Parameter tag: NavigationView的名字（自定义）。用于分辨同一app中的多个NavigationView
    public func delController(tag: String) {
        contorllers[tag] = nil
    }

    private func backToRootObsever(notification: Notification) {
        if let backToRootItem = notification.object as? BackToRootItem {
            popToRoot(tag: backToRootItem.tag, animated: backToRootItem.animated, action: backToRootItem.action)
        }
    }

    private func pushViewObsever(notification: Notification) {
        guard let pushViewItem = notification.object as? PushViewItem else { return }
        pushView(tag: pushViewItem.tag, animated: pushViewItem.animated, view: pushViewItem.view)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public struct ControllerItem {
        let controller: UINavigationController
        var cleanAction: () -> Void
    }

    /// 使用Notification来添加视图时，将需要的信息包装成PushViewItemi
    /// ```swift
    ///   NotificationCenter.default.post(
    ///        name: .NavigationViewManagerPushView,
    ///        object: NavigationViewManager.PushViewItem(tag: "test2", animated: false){
    ///             AnyView(
    ///                        Text("abcd")
    ///                    )
    ///               } )
    /// ```
    public struct PushViewItem {
        public init(tag: String, animated: Bool, view: @escaping () -> AnyView) {
            self.tag = tag
            self.animated = animated
            self.view = view
        }

        let tag: String
        let animated: Bool
        @ViewBuilder var view: () -> AnyView
    }

    /// 使用Notification来返回根视图，将所需信息包装成BackToRootItem
    /// ```swift
    /// NotificationCenter.default.post(
    ///     name: .NavigationViewManagerBackToRoot,
    ///     object: NavigationViewManager.BackToRootItem(tag: "test2", animated: true,
    ///     action: {
    ///        print("other action")
    ///           }))
    /// ```
    public struct BackToRootItem {
        public init(tag: String, animated: Bool, action: @escaping () -> Void) {
            self.tag = tag
            self.animated = animated
            self.action = action
        }

        let tag: String
        let animated: Bool
        var action: () -> Void
    }
}

public extension Notification.Name {
    static let NavigationViewManagerBackToRoot = Notification.Name(rawValue: "NavigationViewManagerBackToRoot")
    static let NavigationViewManagerPushView = Notification.Name(rawValue: "NavigationViewManagerPushView")
}

public struct NavigationgViewManagerKey: EnvironmentKey {
    public static var defaultValue: Binding<NavigationViewManager> = .constant(NavigationViewManager())
}

public extension EnvironmentValues {
    var navigationManager: Binding<NavigationViewManager> {
        get { self[NavigationgViewManagerKey.self] }
        set { self[NavigationgViewManagerKey.self] = newValue }
    }
}

// -MARK: NavigationViewManager
public struct AllowPopToRoot: ViewModifier {
    let tag: String
    var cleanAction: () -> Void
    init(tag: String, cleanAction: @escaping () -> Void = {}) {
        self.tag = tag
        self.cleanAction = cleanAction
    }

    @Environment(\.navigationManager) var nvManager
    public func body(content: Content) -> some View {
        content
            .introspectNavigationController { nv in
                nvManager.wrappedValue.addController(controller: nv, tag: tag, cleanAction: cleanAction)
            }
    }
}

public extension View {
    func allowPopToRoot(tag: String, cleanAction: @escaping () -> Void = {}) -> some View {
        modifier(AllowPopToRoot(tag: tag, cleanAction: cleanAction))
    }
}
