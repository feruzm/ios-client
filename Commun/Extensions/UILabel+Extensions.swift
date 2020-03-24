//
//  UILabel+Extensions.swift
//  Golos
//
//  Created by msm72 on 09.06.2018.
//  Copyright © 2018 Commun Limited. All rights reserved.
//

import UIKit

extension UILabel {
    public func tune(withText text: String, textColor: UIColor?) {
        self.text = text.localized()
        self.textColor = textColor
    }

    public func tune(withText text: String, textColor: UIColor?, font: UIFont?, alignment: NSTextAlignment, isMultiLines: Bool) {
        self.text = text.localized()
        self.font = font
        self.textColor = textColor
        self.numberOfLines = isMultiLines ? 0 : 1
        self.textAlignment = alignment
    }

    public func tune(withAttributedText text: String,
                     textColor: UIColor?,
                     alpha: CGFloat? = 1.0,
                     font: UIFont?,
                     alignment: NSTextAlignment,
                     isMultiLines: Bool,
                     lineHeight: CGFloat = 26.0,
                     lineSpacing: CGFloat = 0.0,
                     baselineOffset: CGFloat = 0.0,
                     lineHeightMultiple: CGFloat = 1.0) {

        let attributedString = NSMutableAttributedString(string: text.localized().uppercaseFirst,
                attributes: [NSAttributedString.Key.font: font!])

        let style = NSMutableParagraphStyle()
        style.lineSpacing = .adaptive(height: lineSpacing)
        style.minimumLineHeight = .adaptive(height: lineHeight)

        if lineHeightMultiple != 1.0 {
            style.lineHeightMultiple = .adaptive(height: lineHeightMultiple)
        }

        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle: style,
                                        .baselineOffset: baselineOffset], range: NSRange(location: 0, length: text.localized().count))
        self.attributedText = attributedString

        self.font = font
        self.textColor = textColor
        self.alpha = alpha ?? 1.0
        self.numberOfLines = isMultiLines ? 0 : 1
        self.textAlignment = alignment
    }
}