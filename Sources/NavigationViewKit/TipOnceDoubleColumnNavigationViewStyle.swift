//
//  TipOnceDoubleColumnNavigationViewStyle.swift
//
//
//  Created by Yang Xu on 2021/8/31.
//

import Foundation
import Introspect
import SwiftUI

/// 当iPad采用双列style时，第一次竖屏显示时，边栏会自动显示提醒用户
public struct TipOnceDoubleColumnNavigationViewStyle: NavigationViewStyle {
    public init() {}

    public func _columnBasedBody(configuration: _NavigationViewStyleConfiguration) -> EmptyView {
        EmptyView()
    }

    @StateObject var orientation = DeviceOrientation()
    @State var show = false
    public func _body(configuration: _NavigationViewStyleConfiguration) -> some View {
        NavigationView {
            configuration.content
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
        .introspectNavigationController { nv in
            if !show {
                if orientation.orientation == .portrait {
                    nv.splitViewController?.preferredDisplayMode = .oneOverSecondary
                    show = true
                }
            } else {
                nv.splitViewController?.preferredDisplayMode = .automatic
            }
        }
    }
}

public extension NavigationViewStyle where Self == TipOnceDoubleColumnNavigationViewStyle {
    static var tipColumns: TipOnceDoubleColumnNavigationViewStyle { TipOnceDoubleColumnNavigationViewStyle() }
}
