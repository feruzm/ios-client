//
//  EditorPageTextView.swift
//  Commun
//
//  Created by Chung Tran on 8/23/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import RTViewAttachment
import RxSwift
import RxCocoa

class EditorPageTextView: RTViewAttachmentTextView {
    // MARK: - Properties
    let bag = DisposeBag()
    var heightConstraint: NSLayoutConstraint!
    @IBInspectable var maxHeight: CGFloat = 0
    
    
    // MARK: - Class Initialization
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUpExpandable()
        textContainerInset = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
    }
    
    func setUpExpandable() {
        textView.isScrollEnabled = false
        textView.rx.text
            .skip(1)
            .distinctUntilChanged()
            .subscribe(onNext: {_ in
                var newFrame = self.textView.frame
                let width = newFrame.size.width
                let newSize = self.textView.sizeThatFits(CGSize(width:   width,
                                                       height:  CGFloat.greatestFiniteMagnitude))
                
                newFrame.size = CGSize(width: max(newSize.width, width), height: newSize.height)
                
                if (self.maxHeight > 0 && newFrame.size.height > self.maxHeight) {return}
                
                self.textView.frame = newFrame
                self.heightConstraint.constant = newSize.height
                self.layoutIfNeeded()
            })
            .disposed(by: bag)
        
        heightConstraint = constraints.first {$0.firstAttribute == .height}
    }
}
