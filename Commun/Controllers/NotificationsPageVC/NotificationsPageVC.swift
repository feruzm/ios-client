//
//  NotificationsPageVC.swift
//  Commun
//
//  Created by Chung Tran on 1/15/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation
import RxSwift

class NotificationsPageVC: ListViewController<ResponseAPIGetNotificationItem, NotificationCell>, PNAlertViewDelegate {
    override var prefersNavigationBarStype: BaseViewController.NavigationBarStyle {.hidden}
    
    // MARK: - Constants
    private let headerViewMaxHeight: CGFloat = 82
    private let headerViewMinHeight: CGFloat = 44
    
    // MARK: - Properties
    private var headerViewHeightConstraint: NSLayoutConstraint?
    private var headerViewHeight: CGFloat = 0
    
    // MARK: - Subviews
    private lazy var emptyTableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNormalMagnitude, height: CGFloat.leastNormalMagnitude))
    private lazy var headerView = UIView(backgroundColor: .appWhiteColor)
    private lazy var smallTitleLabel = UILabel.with(text: title, textSize: 15, weight: .semibold)
    private lazy var largeTitleLabel = UILabel.with(text: title, textSize: 30, weight: .bold)
    private lazy var newNotificationsCountLabel = UILabel.with(text: "", textSize: 12, weight: .regular, textColor: .appGrayColor)
    private var pnAlertView: PNAlertTableHeaderView?
    
    // MARK: - Initializers
    init() {
        let vm = NotificationsPageViewModel()
        super.init(viewModel: vm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if viewModel.items.value.filter({ $0.eventType == "reward" && $0.isNew }).count > 0 {
            appLiked()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let height = headerView.height
        
        if headerViewHeight == 0 {
            tableView.contentInset.top = height
            headerViewHeight = height
            scrollToTop()
        }
    }
    
    override func viewWillSetUpTableView() {
        super.viewWillSetUpTableView()
        
        title = "notifications".localized().uppercaseFirst
        view.backgroundColor = .appWhiteColor
        
        // headerView
        headerView.clipsToBounds = true
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        headerViewHeightConstraint = headerView.autoSetDimension(.height, toSize: headerViewMaxHeight)
        
        headerView.addSubview(smallTitleLabel)
        smallTitleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        smallTitleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        
        headerView.addSubview(largeTitleLabel)
        largeTitleLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        
        headerView.addSubview(newNotificationsCountLabel)
        newNotificationsCountLabel.autoPinEdge(.top, to: .bottom, of: largeTitleLabel, withOffset: -4)
        newNotificationsCountLabel.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        newNotificationsCountLabel.autoPinEdge(toSuperviewEdge: .bottom, withInset: 12)
        
        smallTitleLabel.isHidden = true
        headerView.addShadow(ofColor: .shadow, radius: 16, offset: CGSize(width: 0, height: 6), opacity: 0)
    }
    
    override func setUpTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.configureForAutoLayout()
        tableView.insetsContentViewsToSafeArea = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewSafeArea()
        tableView.backgroundColor = .appLightGrayColor
        tableView.separatorStyle = .none
        
        tableView.rowHeight = UITableView.automaticDimension
        clearPNAlertView()
    }
    
    override func viewDidSetUpTableView() {
        super.viewDidSetUpTableView()
        view.bringSubviewToFront(headerView)
        
        checkPNAuthorizationStatus()
    }
    
    override func bind() {
        super.bind()
       
        tableView.rx.contentOffset.map {$0.y}
            .skip(2)
            .subscribe(onNext: { (y) in
                if y >= -self.headerViewMinHeight {
                    if self.headerViewHeightConstraint?.constant == self.headerViewMinHeight {return}
                    self.headerViewHeightConstraint?.constant = self.headerViewMinHeight
                    self.largeTitleLabel.isHidden = true
                    self.newNotificationsCountLabel.isHidden = true
                    self.smallTitleLabel.isHidden = false
                    self.headerView.shadowOpacity = 0.05
                } else if y <= -self.headerViewMaxHeight {
                    if self.headerViewHeightConstraint?.constant == self.headerViewMaxHeight {return}
                    self.headerViewHeightConstraint?.constant = self.headerViewMaxHeight
                    self.largeTitleLabel.isHidden = false
                    self.newNotificationsCountLabel.isHidden = false
                    self.smallTitleLabel.isHidden = true
                    self.headerView.shadowOpacity = 0
                } else {
                    if self.headerViewHeightConstraint?.constant == abs(y) {return}
                    self.headerViewHeightConstraint?.constant = abs(y)
                    self.largeTitleLabel.isHidden = false
                    self.newNotificationsCountLabel.isHidden = false
                    self.smallTitleLabel.isHidden = true
                    self.headerView.shadowOpacity = 0
                }
            })
            .disposed(by: disposeBag)
        
        tableView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func bindItems() {
        viewModel.items
            .map {$0.filter {ResponseAPIGetNotificationItem.supportedTypes.contains($0.eventType)}}
            .map { (items) -> [ListSection] in
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let dictionary = Dictionary(grouping: items) { item -> Int in
                    let date = Date.from(string: item.timestamp)
                    let createdDate = calendar.startOfDay(for: date)
                    return calendar.dateComponents([.day], from: createdDate, to: today).day ?? 0
                }
                
                return dictionary.keys.sorted()
                    .map { (key) -> ListSection in
                        var sectionLabel: String
                        switch key {
                        case 0:
                            sectionLabel = "today".localized().uppercaseFirst
                        case 1:
                            sectionLabel = "yesterday".localized().uppercaseFirst
                        default:
                            sectionLabel = String(format: NSLocalizedString("%d day", comment: ""), key) + " " + "ago".localized()
                        }
                        return ListSection(model: sectionLabel, items: dictionary[key] ?? [])
                    }
            }
            .do(onNext: { (items) in
                if items.count == 0 {
                    self.handleListEmpty()
                }
            })
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        Observable.combineLatest((viewModel as! NotificationsPageViewModel).unseenCount, viewModel.items.map {UInt64($0.count(where: {$0.isNew}))})
            .map {max($0, $1)}
            .subscribe(onNext: { (newCount) in
                let text = NSMutableAttributedString()
                if newCount > 0 {
                    text.text("•", size: 20, color: .appMainColor)
                        .normal(" ")
                        .text(String(format: "%@ %@", String(format: NSLocalizedString("%d new", comment: ""), newCount), "notifications".localized()), size: 12, color: .appGrayColor)
                }
                self.newNotificationsCountLabel.attributedText = text
            })
            .disposed(by: disposeBag)
    }
    
    override func modelSelected(_ item: ResponseAPIGetNotificationItem) {
        navigateWithNotificationItem(item)
        (viewModel as! NotificationsPageViewModel).markAsRead([item])
    }
    
    override func handleListEmpty() {
        let title = "no notification"
        let description = "you haven't had any notification yet"
        tableView.addEmptyPlaceholderFooterView(emoji: "🙈", title: title.localized().uppercaseFirst, description: description.localized().uppercaseFirst)
    }
    
    override func handleLoading() {
        tableView.addNotificationsLoadingFooterView()
    }
    
    // MARK: - PNAlertViewDelegate
    var pnAlertViewShowed: Bool {
        self.tableView.tableHeaderView != emptyTableHeaderView
    }
    
    func clearPNAlertView() {
        UIView.animate(withDuration: 0.3) {
            self.tableView.tableHeaderView = self.emptyTableHeaderView
            self.pnAlertView = nil
        }
    }
    
    func showPNAlertView() {
        UIView.animate(withDuration: 0.3) {
            self.pnAlertView = PNAlertTableHeaderView(tableView: self.tableView)
            self.pnAlertView?.delegate = self
        }
    }
    
    // MARK: - AppState observer
    @objc func applicationDidBecomeActive(notification: NSNotification) {
        checkPNAuthorizationStatus()
    }
}

extension NotificationsPageVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 24
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        let headerView = UIView(frame: .zero)
        headerView.backgroundColor = .appWhiteColor
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges()
        
        let label = UILabel.with(text: dataSource.sectionModels[section].model, textSize: 12, weight: .semibold)
        headerView.addSubview(label)
        label.autoPinEdge(toSuperviewEdge: .leading, withInset: 16)
        label.autoAlignAxis(toSuperviewAxis: .horizontal)
        return view
    }
    
    // https://stackoverflow.com/questions/1074006/is-it-possible-to-disable-floating-headers-in-uitableview-with-uitableviewstylep
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView(frame: .zero)
    }

}
