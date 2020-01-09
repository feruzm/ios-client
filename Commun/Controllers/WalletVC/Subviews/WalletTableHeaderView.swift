//
//  WalletHeaderView.swift
//  Commun
//
//  Created by Chung Tran on 12/19/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation
import RxSwift
import CircularCarousel

class WalletTableHeaderView: MyTableHeaderView {
    // MARK: - Properties
    var sendPointsTopConstraint: NSLayoutConstraint?
    
    // MARK: - Subviews
    lazy var myPointsContainerView = UIView(forAutoLayout: ())
    lazy var myPointsSeeAllButton = UIButton(label: "see all".localized().uppercaseFirst, labelFont: .systemFont(ofSize: 15, weight: .medium), textColor: .appMainColor, contentInsets: .zero)
    
    lazy var myPointsCollectionView: UICollectionView = {
        let collectionView = UICollectionView.horizontalFlow(
            cellType: MyPointCollectionCell.self,
            height: MyPointCollectionCell.height,
            contentInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        )
        collectionView.layer.masksToBounds = false
        return collectionView
    }()
    
    // MARK: - Send points
    lazy var sendPointsContainerView = UIView(forAutoLayout: ())
    lazy var sendPointsSeeAllButton = UIButton(label: "see all".localized().uppercaseFirst, labelFont: .systemFont(ofSize: 15, weight: .medium), textColor: .appMainColor, contentInsets: .zero)
    
    lazy var sendPointsCollectionView: UICollectionView = {
        let collectionView = UICollectionView.horizontalFlow(
            cellType: SendPointCollectionCell.self,
            height: SendPointCollectionCell.height,
            contentInsets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        )
        collectionView.layer.masksToBounds = false
        return collectionView
    }()
    
    // MARK: - Filter
    lazy var filterContainerView = UIView(backgroundColor: .white)
    lazy var filterButton: LeftAlignedIconButton = {
        let button = LeftAlignedIconButton(height: 35, label: "filter".localized().uppercaseFirst, labelFont: .systemFont(ofSize: 15, weight: .semibold), backgroundColor: .f3f5fa, textColor: .a5a7bd, cornerRadius: 10, contentInsets: UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 16))
        button.setImage(UIImage(named: "Filter"), for: .normal)
        button.tintColor = .a5a7bd
        return button
    }()
    
    // MARK: - Methods
    override func commonInit() {
        super.commonInit()
        // my points
        addSubview(myPointsContainerView)
        myPointsContainerView.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
        myPointsContainerView.autoPinEdge(toSuperviewEdge: .leading)
        myPointsContainerView.autoPinEdge(toSuperviewEdge: .trailing)
        
        let myPointsLabel = UILabel.with(text: "my points".localized().uppercaseFirst, textSize: 17, weight: .bold)
        myPointsContainerView.addSubview(myPointsLabel)
        myPointsLabel.autoPinEdge(toSuperviewEdge: .top)
        myPointsLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        
        myPointsContainerView.addSubview(myPointsSeeAllButton)
        myPointsSeeAllButton.autoPinEdge(toSuperviewEdge: .top)
        myPointsSeeAllButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        
        myPointsContainerView.addSubview(myPointsCollectionView)
        myPointsCollectionView.autoPinEdge(.top, to: .bottom, of: myPointsLabel, withOffset: 20)
        myPointsCollectionView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        // send points
        addSubview(sendPointsContainerView)
        sendPointsTopConstraint = sendPointsContainerView.autoPinEdge(.top, to: .bottom, of: myPointsContainerView, withOffset: 30 * Config.heightRatio)
        sendPointsContainerView.autoPinEdge(toSuperviewEdge: .leading)
        sendPointsContainerView.autoPinEdge(toSuperviewEdge: .trailing)
        
        sendPointsContainerView.addSubview(sendPointsSeeAllButton)
        sendPointsSeeAllButton.autoPinEdge(toSuperviewEdge: .top)
        sendPointsSeeAllButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        
        let sendPointsLabel = UILabel.with(text: "send points".localized().uppercaseFirst, textSize: 17, weight: .bold)
        sendPointsContainerView.addSubview(sendPointsLabel)
        sendPointsLabel.autoPinEdge(toSuperviewEdge: .top)
        sendPointsLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        
        sendPointsContainerView.addSubview(sendPointsCollectionView)
        sendPointsCollectionView.autoPinEdge(.top, to: .bottom, of: sendPointsLabel, withOffset: 20)
        sendPointsCollectionView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        
        // filter
        addSubview(filterContainerView)
        filterContainerView.autoPinEdge(.top, to: .bottom, of: sendPointsContainerView, withOffset: 32)
        filterContainerView.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)
        filterContainerView.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        
        let historyLabel = UILabel.with(text: "history".localized().uppercaseFirst, textSize: 17, weight: .bold)
        filterContainerView.addSubview(historyLabel)
        historyLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        historyLabel.autoAlignAxis(toSuperviewAxis: .horizontal)
        
        filterContainerView.addSubview(filterButton)
        filterButton.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        filterButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 10)
        filterButton.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16)
        
        // pin bottom
        filterContainerView.autoPinEdge(toSuperviewEdge: .bottom)
        
        // initial setup
        setMyPointHidden(false)
    }
    
    func setMyPointHidden(_ hidden: Bool) {
        if !hidden {
            // add my point
            if !myPointsContainerView.isDescendant(of: self) {
                addSubview(myPointsContainerView)
                myPointsContainerView.autoPinEdge(toSuperviewEdge: .top, withInset: 20)
                myPointsContainerView.autoPinEdge(toSuperviewEdge: .leading)
                myPointsContainerView.autoPinEdge(toSuperviewEdge: .trailing)
                
                sendPointsTopConstraint?.isActive = false
                sendPointsTopConstraint = sendPointsContainerView.autoPinEdge(.top, to: .bottom, of: myPointsContainerView, withOffset: 30 * Config.heightRatio)
                UIView.animate(withDuration: 0.3) {
                    self.layoutIfNeeded()
                }
            }
        } else {
            // remove my point
            if myPointsContainerView.isDescendant(of: self) {
                myPointsContainerView.removeFromSuperview()
                
                sendPointsTopConstraint?.isActive = false
                sendPointsTopConstraint = sendPointsContainerView.autoPinEdge(toSuperviewEdge: .top)
                UIView.animate(withDuration: 0.3) {
                    self.layoutIfNeeded()
                }
            }
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        filterContainerView.roundCorners(UIRectCorner(arrayLiteral: .topLeft, .topRight), radius: 16)
    }
}
