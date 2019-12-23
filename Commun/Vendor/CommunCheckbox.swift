//
//  CommunCheckbox.swift
//  Commun
//
//  Created by Chung Tran on 9/30/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import UIKit

class CommunCheckbox: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        // text
        setTitle(nil, for: .normal)
        setTitle(nil, for: .selected)
        
        // edge inset
        
    }
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = .appMainColor
                borderWidth = 0
                let image = UIImage(named: "checkmark")!.withRenderingMode(.alwaysOriginal)
                setImage(image, for: .selected)
                tintColor = .clear
                imageEdgeInsets = UIEdgeInsets(top: 8, left: 6, bottom: 7, right: 5)
            } else {
                backgroundColor = .white
                borderWidth = 1
                borderColor = .e2e6e8
                setImage(nil, for: .normal)
                imageEdgeInsets = UIEdgeInsets.zero
            }
        }
    }
}