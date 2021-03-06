//
//  TransactionCompletedVC.swift
//  Commun
//
//  Created by Chung Tran on 4/9/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation

class TransactionCompletedVC: TransactionInfoVC {
    override var prefersNavigationBarStype: BaseViewController.NavigationBarStyle {
        .normal(translucent: true, backgroundColor: .appMainColor, textColor: .white)
    }
    
    override var shouldHideTabBar: Bool {true}
    override var backgroundColor: UIColor {.appMainColor}
    
    lazy var homeButton = UIButton(height: 56 * Config.heightRatio, label: "home".localized().uppercaseFirst, labelFont: .systemFont(ofSize: 15, weight: .bold), backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1), textColor: .white, cornerRadius: 28 * Config.heightRatio)
    
    lazy var backToWalletButton = UIButton(height: 56 * Config.heightRatio, label: "back to wallet".localized().uppercaseFirst, labelFont: .systemFont(ofSize: 15, weight: .bold), backgroundColor: .appWhiteColor, textColor: .appMainColor, cornerRadius: 28 * Config.heightRatio)
    
    override func setUp() {
        super.setUp()
        title = "send points".localized().uppercaseFirst
    }
    
    override func setUpButtonStackView() {
        buttonStackView.addArrangedSubviews([homeButton, backToWalletButton])
    }
    
    override func viewDidSetUpButtonStackView() {
        homeButton.addTarget(self, action: #selector(homeButtonDidTouch), for: .touchUpInside)
        backToWalletButton.addTarget(self, action: #selector(backToWalletButtonDidTouch), for: .touchUpInside)
    }
    
    override func configureNavigationBar() {
        super.configureNavigationBar()
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(stopBarButtonTapped))
    }
    
    @objc func homeButtonDidTouch() {
        // Return to `Feed` page
        if let tabBarVC = tabBarController as? TabBarVC {
            tabBarVC.setTabBarHiden(false)
            tabBarVC.switchTab(index: 0)
            navigationController?.popToRootViewController(animated: false)
            tabBarVC.appLiked()
        }
    }
    
    @objc func backToWalletButtonDidTouch() {
        backToWallet()
    }
}
