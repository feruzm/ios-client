//
//  CMActionSheet.swift
//  Commun
//
//  Created by Chung Tran on 8/12/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation

class CMActionSheet: CMBottomSheet {
    // MARK: - Nested type
    struct Action {
        var id: String?
        var dismissActionSheetOnCompleted = true
        var view: UIView
        var handle: (() -> Void)?
        var bottomMargin: CGFloat? = 0
        var associatedValue: Any?
        
        var iconImageView: UIImageView? {
            (view.subviews.first(where: {$0 is UIStackView}) as? UIStackView)?.arrangedSubviews.first(where: {$0 is UIImageView}) as? UIImageView
        }
        var titleLabel: UILabel? {
            (view.subviews.first(where: {$0 is UIStackView}) as? UIStackView)?.arrangedSubviews.first(where: {$0 is UILabel}) as? UILabel
        }
    }
    
    class TapGesture: UITapGestureRecognizer {
        var action: Action?
    }
    
    // MARK: - Subviews
    var headerView: UIView {
        didSet { configureHeader() }
    }
    lazy var actionStackView = UIStackView(axis: .vertical, spacing: 0, alignment: .fill, distribution: .fill)
    var actions: [Action] {
        didSet { setUpActions() }
    }
    
    // MARK: - Initializer
    init(headerView: UIView?, title: String?, actions: [Action]) {
        self.actions = actions
        self.headerView = headerView ?? UILabel.with(text: title ?? "options".localized().uppercaseFirst, textSize: 15, weight: .bold)
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    override func setUp() {
        super.setUp()
        
        configureHeader()
        
        // set up action
        scrollView.contentView.addSubview(actionStackView)
        actionStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 10, bottom: 16, right: 10))
        
        setUpActions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for (index, action) in actions.enumerated() {
            var roundingCorners = UIRectCorner()
            
            if index == 0 {
                roundingCorners.insert([.topLeft, .topRight])
            }
            
            if index == actions.count - 1 {
                roundingCorners.insert([.bottomLeft, .bottomRight])
            }
            
            if action.bottomMargin != nil {
                roundingCorners.insert([.bottomLeft, .bottomRight])
            }
            
            if let previousAction = actions[safe: index - 1], previousAction.bottomMargin != nil {
                roundingCorners.insert([.topLeft, .topRight])
            }
            
            action.view.roundCorners(roundingCorners, radius: 10)
        }
    }
    
    private func configureHeader() {
        headerStackView.removeArrangedSubviews()
        headerStackView.addArrangedSubviews([headerView, closeButton])
    }
    
    private func setUpActions() {
        actionStackView.removeArrangedSubviews()
        let views = actions.map {$0.view}
        actionStackView.addArrangedSubviews(views)
        
        for action in actions {
            actionStackView.setCustomSpacing(action.bottomMargin ?? 2, after: action.view)
        }
        
        actions.forEach { action in
            action.view.isUserInteractionEnabled = true
            let tapGesture = TapGesture(target: self, action: #selector(actionDidSelect(_:)))
            tapGesture.action = action
            action.view.addGestureRecognizer(tapGesture)
        }
    }
    
    // MARK: - Actions
    
    @objc func actionDidSelect(_ gesture: TapGesture) {
        guard let action = gesture.action else {return}
        if action.dismissActionSheetOnCompleted {
            dismiss(animated: true) {
                action.handle?()
            }
        } else {
            action.handle?()
        }
    }
    
    // MARK: - Helper
    func actionWithId(_ id: String) -> Action? {
        actions.first(where: {$0.id == id})
    }
}
