//
//  File.swift
//  File
//
//  Created by Yang Xu on 2021/9/1.
//

import Foundation
import SwiftUI

public extension NavigationViewManager{
    /// 返回按钮显示方式
    /// - Parameters:
    ///   - tag: NavigationView的名字（自定义）。用于分辨同一app中的多个NavigationView
    ///   - mode: 显示模式
    ///
    ///  在需要设置的视图中调用本方法，该设置仅对本视图有效。
    ///  ```swift
    ///  @Environment(\.navigationManager) var nvmanager
    ///
    ///  .onAppear{
    ///           nvmanager.wrappedValue.backButtonDisplayMode(for: "nv1", mode: .minimal)
    ///        }
    ///  ```
    func backButtonDisplayMode(for tag:String,mode:UINavigationItem.BackButtonDisplayMode) {
        contorllers[tag]?.controller.navigationBar.topItem?.backButtonDisplayMode = mode
    }
}
