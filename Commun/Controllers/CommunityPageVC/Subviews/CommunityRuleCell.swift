//
//  CommunityRuleCell.swift
//  Commun
//
//  Created by Chung Tran on 10/31/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation

class CommunityRuleCell: CommunityPageCell {
    // MARK: - Properties
    var rowIndex: Int?
    var expanded = false
    var rule: ResponseAPIContentGetCommunityRule?
    
    // MARK: - Subviews
    lazy var titleLabel = UILabel.with(text: "2. Content should be Safe for Work", textSize: 15, weight: .bold)
    lazy var contentLabel = UILabel.with(text: "All content (title, articles, video, image, website, etc.) must be SFW: Safe For Work. Content that is NSFW: Not Safe For Work, is banned. This rule applies to all posts and comments.", textSize: 15, numberOfLines: 0)
    lazy var expandButton = UIButton.circleGray(imageName: "rule_expand")
    
    override func setUpViews() {
        super.setUpViews()
        // background color
        contentView.backgroundColor = #colorLiteral(red: 0.9599978328, green: 0.966491878, blue: 0.9829974771, alpha: 1)
        
        let containerView = UIView(backgroundColor: .white, cornerRadius: 10)
        contentView.addSubview(containerView)
        containerView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10))
        
        containerView.addSubview(titleLabel)
        titleLabel.autoPinTopAndLeadingToSuperView(inset: 16)
        
        containerView.addSubview(expandButton)
        expandButton.autoPinTopAndTrailingToSuperView(inset: 16)
        expandButton.autoPinEdge(.leading, to: .trailing, of: titleLabel, withOffset: 8)
        expandButton.addTarget(self, action: #selector(expandButtonDidTouch(_:)), for: .touchUpInside)
        
        containerView.addSubview(contentLabel)
        contentLabel.autoPinEdge(.top, to: .bottom, of: expandButton, withOffset: 0)
        contentLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(inset: 16), excludingEdge: .top)
    }
    
    func setUp(with newRule: ResponseAPIContentGetCommunityRule?) {
        rule = newRule
        titleLabel.text = "\((rowIndex ?? 0) + 1). " + (rule?.title ?? "")
        setExpanded()
    }
    
    func setExpanded() {
        guard let rule = rule else {return}
        if expanded {
            contentLabel.text = rule.text
            expandButton.setImage(UIImage(named: "rule_collapse"), for: .normal)
        }
        else {
            contentLabel.text = nil
            expandButton.setImage(UIImage(named: "rule_expand"), for: .normal)
        }
    }
    
    @objc func expandButtonDidTouch(_ sender: UIButton) {
        expanded = !expanded
        setExpanded()
        tableView?.beginUpdates()
        tableView?.endUpdates()
    }
}
