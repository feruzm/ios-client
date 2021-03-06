//
//  UIEdgeInsets+Extensions.swift
//  Commun
//
//  Created by Chung Tran on 9/28/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation

extension UIEdgeInsets {
    enum RectEdge {
        case top, leading, bottom, trailing
    }
    static func only(_ edge: RectEdge, inset: CGFloat) -> Self {
        Self(top: (edge == .top) ? inset : 0, left: (edge == .leading) ? inset : 0, bottom: (edge == .bottom) ? inset : 0, right: (edge == .trailing) ? inset : 0)
    }
}
