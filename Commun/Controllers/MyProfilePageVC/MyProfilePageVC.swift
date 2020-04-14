//
//  MyProfilePageVC.swift
//  Commun
//
//  Created by Chung Tran on 10/29/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation

class MyProfilePageVC: UserProfilePageVC {
    // MARK: - Properties
    var shouldHideBackButton = true
    
    // MARK: - Subviews
    lazy var changeCoverButton: UIButton = {
        let button = UIButton(width: 24, height: 24, backgroundColor: UIColor.black.withAlphaComponent(0.3), cornerRadius: 12, contentInsets: UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6))
        button.tintColor = .white
        button.setImage(UIImage(named: "photo_solid")!, for: .normal)
        button.touchAreaEdgeInsets = UIEdgeInsets(inset: -10)
        return button
    }()
    
    // MARK: - Initializers
    override func createViewModel() -> ProfileViewModel<ResponseAPIContentGetProfile> {
        MyProfilePageViewModel(userId: userId)
    }
    
    init() {
        super.init(userId: Config.currentUser?.id ?? "")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // MARK: - Custom Functions
    override func setUp() {
        super.setUp()
        
        // hide back button
        if shouldHideBackButton {
            backButton.alpha = 0
            backButton.isUserInteractionEnabled = false
        }
        
        // layout subview
        view.addSubview(changeCoverButton)
        changeCoverButton.autoPinEdge(.bottom, to: .bottom, of: coverImageView, withOffset: -60)
        changeCoverButton.autoPinEdge(.trailing, to: .trailing, of: coverImageView, withOffset: -16)
        
        changeCoverButton.addTarget(self, action: #selector(changeCoverBtnDidTouch(_:)), for: .touchUpInside)
        
        // wallet
        let tap = UITapGestureRecognizer(target: self, action: #selector(walletDidTouch))
        (headerView as! MyProfileHeaderView).walletView.isUserInteractionEnabled = true
        (headerView as! MyProfileHeaderView).walletView.addGestureRecognizer(tap)
    }
    
    override func bind() {
        super.bind()
        
        bindBalances()
        
        let offSetY = tableView.rx.contentOffset
            .map {$0.y}.share()
            
        offSetY
            .map { $0 < -140 }
            .subscribe(onNext: { show in
                self.changeCoverButton.isHidden = !show
            })
            .disposed(by: disposeBag)
        
        offSetY
            .map { $0 < -43 }
            .subscribe(onNext: { showNavBar in
                self.optionsButton.tintColor = !showNavBar ? .black : .white
                self.title = !showNavBar ? self.username : nil
            })
            .disposed(by: disposeBag)
    }
    
    override func createHeaderView() -> UserProfileHeaderView {
        let headerView = MyProfileHeaderView(tableView: tableView)
        
        headerView.changeAvatarButton.addTarget(self, action: #selector(changeAvatarBtnDidTouch(_:)), for: .touchUpInside)
        headerView.addBioButton.addTarget(self, action: #selector(addBioButtonDidTouch(_:)), for: .touchUpInside)
        headerView.descriptionLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(bioLabelDidTouch(_:)))
        headerView.descriptionLabel.addGestureRecognizer(tap)
        return headerView
    }
    
    override func moreActionsButtonDidTouch(_ sender: CommunButton) {
        guard let profile = viewModel.profile.value else { return }

        let headerView = UIView(height: 40)
        let avatarImageView = MyAvatarImageView(size: 40)
        
        avatarImageView
            .observeCurrentUserAvatar()
            .disposed(by: disposeBag)
        
        headerView.addSubview(avatarImageView)
        avatarImageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)
        
        let userNameLabel = UILabel.with(text: profile.username, textSize: 15, weight: .semibold)
        headerView.addSubview(userNameLabel)
        userNameLabel.autoPinEdge(toSuperviewEdge: .top)
        userNameLabel.autoPinEdge(.leading, to: .trailing, of: avatarImageView, withOffset: 10)
        userNameLabel.autoPinEdge(toSuperviewEdge: .trailing)

        let userIdLabel = UILabel.with(text: "@\(profile.userId)", textSize: 12, weight: .semibold, textColor: .appMainColor)
        headerView.addSubview(userIdLabel)
        userIdLabel.autoPinEdge(.top, to: .bottom, of: userNameLabel, withOffset: 3)
        userIdLabel.autoPinEdge(.leading, to: .trailing, of: avatarImageView, withOffset: 10)
        userIdLabel.autoPinEdge(toSuperviewEdge: .trailing)
        
        showCommunActionSheet(headerView: headerView, actions: [
            CommunActionSheet.Action(title: "share".localized().uppercaseFirst,
                                     icon: UIImage(named: "icon-share-circle-white"),
                                     style: .share,
                                     marginTop: 0,
                                     handle: {
                                        ShareHelper.share(urlString: self.shareWith(name: profile.username, userID: profile.userId))
            }),
            CommunActionSheet.Action(title: "referral".localized().uppercaseFirst,
                                     icon: UIImage(named: "profile_options_referral"),
                                     style: .profile,
                                     marginTop: 15,
                                     handle: {
                                        let vc = ReferralUsersVC()
                                        vc.title = "saved souls".localized().uppercaseFirst
                                        self.navigationItem.backBarButtonItem = UIBarButtonItem(customView: UIView(backgroundColor: .clear))
                                        self.show(vc, sender: self)
            }),
            CommunActionSheet.Action(title: "liked".localized().uppercaseFirst,
                                     icon: UIImage(named: "profile_options_liked"),
                                     style: .profile,
                                     marginTop: 17,
                                     handle: {
                                        let vc = PostsViewController(filter: PostsListFetcher.Filter(type: .voted, sortBy: .time, userId: Config.currentUser?.id))
                                        vc.title = "liked".localized().uppercaseFirst
                                        self.navigationItem.backBarButtonItem = UIBarButtonItem(customView: UIView(backgroundColor: .clear))
                                        self.show(vc, sender: self)
            }),
            CommunActionSheet.Action(title: "blacklist".localized().uppercaseFirst,
                                     icon: UIImage(named: "profile_options_blacklist"),
                                     style: .profile,
                                     marginTop: 19,
                                     handle: {
                                        self.show(MyProfileBlacklistVC(), sender: self)
            }),
            CommunActionSheet.Action(title: "settings".localized().uppercaseFirst,
                                     icon: UIImage(named: "profile_options_settings"),
                                     style: .profile,
                                     marginTop: 34,
                                     handle: {
                                        let vc = MyProfileSettingsVC()
                                        self.show(vc, sender: self)
            })
        ]) {
            
        }
    }
}
