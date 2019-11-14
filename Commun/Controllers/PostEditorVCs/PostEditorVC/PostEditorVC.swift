//
//  PostEditorVC.swift
//  Commun
//
//  Created by Chung Tran on 10/4/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class PostEditorVC: EditorVC {
    // MARK: - Properties
    
    // MARK: - Computed properties
    var contentLettersLimit: UInt {30000}
    var contentCombined: Observable<Void> {
        fatalError("Must override")
    }
    var isContentValid: Bool {
        fatalError("Must override")
    }
    
    var viewModel: PostEditorViewModel {
        fatalError("Must override")
    }
    
    var postTitle: String? {
        fatalError("Must override")
    }
    
    // MARK: - Subviews
    // community
    lazy var communityView = UIView(forAutoLayout: ())
    lazy var communityAvatarImage = MyAvatarImageView(size: 40)
    lazy var communityNameLabel = UILabel.with(text: "choose a community".localized().uppercaseFirst, textSize: 15, weight: .semibold, numberOfLines: 0)
    lazy var contentTextViewCountLabel = UILabel.descriptionLabel("0/30000")
    
    var contentTextView: ContentTextView {
        fatalError("Must override")
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // if editing post
        if let post = viewModel.postForEdit {
            setUp(with: post)
        }
        else {
            // parse draft
            if hasDraft {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // your code here
                    self.retrieveDraft()
                }
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        actionButton.setTitle("send post".localized().uppercaseFirst, for: .normal)
        actionButton.backgroundColor = .appMainColor
        
        // common contentTextView
        contentTextView.placeholder = "write text placeholder".localized().uppercaseFirst + "..."
        headerLabel.text = (viewModel.postForEdit != nil ? "edit post" : "create post").localized().uppercaseFirst
        
        contentTextView.textContainerInset = UIEdgeInsets(top: 0, left: 16, bottom: 100, right: 16)
        
        contentTextView.addLinkDidTouch = {[weak self] in
            self?.addLink()
        }
        // add default tool
        appendTool(EditorToolbarItem.addPhoto)
    }
    
    override func bind() {
        super.bind()
        bindKeyboardHeight()
        
        bindSendPostButton()
        
        bindContentTextView()
        
        bindCommunity()
    }
    
    override func didSelectTool(_ item: EditorToolbarItem) {
        super.didSelectTool(item)
        guard item.isEnabled else {return}
        
        if item == .setBold {
            contentTextView.toggleBold()
        }
        
        if item == .setItalic {
            contentTextView.toggleItalic()
        }
        
        if item == .clearFormatting {
            contentTextView.clearFormatting()
        }
        
        if item == .addArticle {
            addArticle()
        }
        
        if item == .addPhoto {
            addImage()
        }
        
        if item == .addLink {
            addLink()
        }
    }
    
    // MARK: - action for overriding
    func setUp(with post: ResponseAPIContentGetPost) {
        guard let document = post.document else {return}
        contentTextView.parseContentBlock(document)
    }
    
    func getContentBlock() -> Single<ResponseAPIContentBlock> {
        contentTextView.getContentBlock()
    }
}
