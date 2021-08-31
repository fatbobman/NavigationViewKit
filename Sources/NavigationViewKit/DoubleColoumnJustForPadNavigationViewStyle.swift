//
//  DoubleColoumnJustForPadNavigationViewStyle.swift
//
//
//  Created by Yang Xu on 2021/8/31.
//

import Foundation
import SwiftUI

public struct DeviceKey: EnvironmentKey {
    public static var defaultValue = UIDevice.current.userInterfaceIdiom
}

public extension EnvironmentValues {
    var device: UIUserInterfaceIdiom { self[DeviceKey.self] }
}

/// 屏蔽掉iPhoneMax在横屏状态下的双列显示。只在iPad上支持双列显示
public struct DoubleColoumnJustForPadNavigationViewStyle: NavigationViewStyle {
    @Environment(\.device) var device
    public init() {}

    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        if device == .pad {
            NavigationView {
                configuration.content
            }
            .navigationViewStyle(DoubleColumnNavigationViewStyle())
        } else {
            NavigationView {
                configuration.content
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    public func _columnBasedBody(configuration: _NavigationViewStyleConfiguration) -> EmptyView {
        EmptyView()
    }
}

public extension NavigationViewStyle where Self == DoubleColoumnJustForPadNavigationViewStyle {
    static var columnsForPad: DoubleColoumnJustForPadNavigationViewStyle { DoubleColoumnJustForPadNavigationViewStyle() }
}

public extension View {
    func doubleColoumnJustForPadNavigationView() -> some View {
        modifier(DoubleColoumnJustForPadNavigationViewModifier())
    }
}

struct DoubleColoumnJustForPadNavigationViewModifier: ViewModifier {
    @Environment(\.device) var device
    public func body(content: Content) -> some View {
        if device == .pad {
            content
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
        } else {
            content
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
