//
//  FixDoubleColumnNavigationViewStyle.swift
//
//
//  Created by Yang Xu on 2021/8/31.
//

import Combine
import Foundation
import Introspect
import SwiftUI

/// 一个让iPad设备在何种状态下均保持双列的NavigationViewStyle
/// 可以分别设置横向或竖向显示时主栏的宽度
/// ```swift
///     NavigationView{
///         ...
///     }
///     .navigationViewStyle(FixDoubleColumnNavigationViewStyle(widthForLandscape: 350, widthForPortrait:250))
/// ```
public struct FixDoubleColumnNavigationViewStyle: NavigationViewStyle {
    let widthForLandscape: CGFloat
    let widthForPortrait: CGFloat
    @StateObject var orientation = DeviceOrientation()
    public init(widthForLandscape: CGFloat = 350, widthForPortrait: CGFloat = 350) {
        self.widthForLandscape = widthForLandscape
        self.widthForPortrait = widthForPortrait
    }

    // iOS 15新添加的方法，用不到，直接返回空视图
    public func _columnBasedBody(configuration: _NavigationViewStyleConfiguration) -> EmptyView {
        EmptyView()
    }

    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        NavigationView {
            configuration.content
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .introspectNavigationController { nv in
            nv.splitViewController?.preferredDisplayMode = .oneBesideSecondary
            nv.splitViewController?.presentsWithGesture = false // 这是关键
            withAnimation {
                if orientation.orientation == .landscape {
                    withAnimation {
                        nv.splitViewController?.maximumPrimaryColumnWidth = widthForLandscape
                        nv.splitViewController?.preferredPrimaryColumnWidth = widthForLandscape
                    }
                } else {
                    nv.splitViewController?.maximumPrimaryColumnWidth = widthForPortrait
                    nv.splitViewController?.preferredPrimaryColumnWidth = widthForPortrait
                }
            }
        }
    }
}

/// 监控设备旋转
final class DeviceOrientation: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }

    @Published var orientation: Orientation
    private var listener: AnyCancellable?
    init() {
        orientation = UIDevice.current.orientation.isLandscape ? .landscape : .portrait
        listener = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .compactMap { ($0.object as? UIDevice)?.orientation }
            .compactMap { deviceOrientation -> Orientation? in
                if deviceOrientation.isPortrait {
                    return .portrait
                } else if deviceOrientation.isLandscape {
                    return .landscape
                } else {
                    return nil
                }
            }
            .assign(to: \.orientation, on: self)
    }

    deinit {
        listener?.cancel()
    }
}
