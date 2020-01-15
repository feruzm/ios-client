//
//  WalletVC.swift
//  Commun
//
//  Created by Chung Tran on 12/19/19.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import Foundation
import RxSwift
import ESPullToRefresh

class WalletVC: TransferHistoryVC {
    // MARK: - Properties
    var balances: [ResponseAPIWalletGetBalance]? {
        (self.viewModel as! WalletViewModel).balancesVM.items.value
    }
    var currentBalance: ResponseAPIWalletGetBalance? {
        balances?[safe: headerView.selectedIndex]
    }
    var isUserScrolling: Bool {
        tableView.isTracking || tableView.isDragging || tableView.isDecelerating
    }
    
    // MARK: - Subviews
    lazy var headerView: WalletHeaderView = {
        let headerView = WalletHeaderView(forAutoLayout: ())
        headerView.delegate = self
        headerView.dataSource = self
        return headerView
    }()
    lazy var tableHeaderView = WalletTableHeaderView(tableView: tableView)
    var myPointsCollectionView: UICollectionView {tableHeaderView.myPointsCollectionView}
    var sendPointsCollectionView: UICollectionView {tableHeaderView.sendPointsCollectionView}
    var headerViewExpandedHeight: CGFloat = 0
    
    override class func createViewModel() -> TransferHistoryViewModel {
        WalletViewModel()
    }
    
    override func createTableView() -> UITableView {
        view.addSubview(headerView)
        headerView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.configureForAutoLayout()
        tableView.insetsContentViewsToSafeArea = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
        
        view.bringSubviewToFront(headerView)
        return tableView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    override func setUp() {
        super.setUp()
        headerView.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        
        headerView.sendButton.addTarget(self, action: #selector(sendButtonDidTouch), for: .touchUpInside)
        headerView.convertButton.addTarget(self, action: #selector(convertButtonDidTouch), for: .touchUpInside)
        
        tableHeaderView.sendPointsSeeAllButton.addTarget(self, action: #selector(sendPointsSeeAllDidTouch), for: .touchUpInside)
        tableHeaderView.myPointsSeeAllButton.addTarget(self, action: #selector(myPointsSeeAllDidTouch), for: .touchUpInside)
        
        tableHeaderView.filterButton.addTarget(self, action: #selector(openFilter), for: .touchUpInside)
        
        tableHeaderView.setMyPointHidden(false)
    }
    
    override func bind() {
        super.bind()
        
        // forward delegate
        myPointsCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        sendPointsCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        let offsetY = tableView.rx.contentOffset
            .map {$0.y}
            .share()
            
        offsetY
            .filter {_ in self.isUserScrolling}
            .map({ y in
                if y > 0 {return true}
                return self.headerViewExpandedHeight + y > 40
            })
            .distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (collapse) in
                self.headerView.setIsCollapsed(collapse)
            })
            .disposed(by: disposeBag)
        
        offsetY
            .map {$0 < -self.headerViewExpandedHeight}
            .subscribe(onNext: { (show) in
                self.tableView.subviews.first(where: {$0 is ESRefreshHeaderView})?.alpha = show ? 1 : 0
            })
            .disposed(by: disposeBag)
    }
    
    override func bindItems() {
        super.bindItems()
        (viewModel as! WalletViewModel).balancesVM.items
            .distinctUntilChanged()
            .subscribe(onNext: { (_) in
                self.headerView.reloadData()
            })
            .disposed(by: disposeBag)
        
        (viewModel as! WalletViewModel).balancesVM.items
            .bind(to: myPointsCollectionView.rx.items(cellIdentifier: "\(MyPointCollectionCell.self)", cellType: MyPointCollectionCell.self)) { _, model, cell in
                cell.setUp(with: model)
            }
            .disposed(by: disposeBag)
        
        myPointsCollectionView.rx.modelSelected(ResponseAPIWalletGetBalance.self)
            .subscribe(onNext: { (balance) in
                guard let index = self.balances?.firstIndex(where: {$0.symbol == balance.symbol}) else {return}
                self.headerView.setSelectedIndex(index)
            })
            .disposed(by: disposeBag)
        
        (viewModel as! WalletViewModel).subscriptionsVM.items
            .map({ (items) -> [ResponseAPIContentGetSubscriptionsUser?] in
                let items = items.compactMap {$0.userValue}
                return [nil] + items
            })
            .bind(to: sendPointsCollectionView.rx.items(cellIdentifier: "\(SendPointCollectionCell.self)", cellType: SendPointCollectionCell.self)) { _, model, cell in
                cell.setUp(with: model)
            }
            .disposed(by: disposeBag)
    }
    
    override func bindItemSelected() {
        super.bindItemSelected()
        sendPointsCollectionView.rx.itemSelected
            .subscribe(onNext: { (indexPath) in
                if indexPath.row == 0 {
                    self.addFriend()
                } else {
                    guard let user = (self.viewModel as! WalletViewModel).subscriptionsVM.items.value[safe: indexPath.row - 1]?.userValue else {return}
                    self.sendPoint(to: user)
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func bindState() {
        super.bindState()
        (viewModel as! WalletViewModel).balancesVM.state
            .distinctUntilChanged()
            .debounce(0.3, scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] state in
                switch state {
                case .loading(let isLoading):
                    if isLoading {
                        self?.headerView.startLoading()
                        self?.myPointsCollectionView.showLoader()
                        self?.sendPointsCollectionView.showLoader()
                    } else {
                        self?.headerView.endLoading()
                        self?.myPointsCollectionView.hideLoader()
                        self?.sendPointsCollectionView.hideLoader()
                    }
                case .listEnded:
                    self?.headerView.endLoading()
                    self?.myPointsCollectionView.hideLoader()
                    self?.sendPointsCollectionView.hideLoader()
                case .listEmpty:
                    self?.headerView.endLoading()
                    self?.myPointsCollectionView.hideLoader()
                    self?.sendPointsCollectionView.hideLoader()
                case .error(let error):
                    self?.headerView.endLoading()
                    self?.myPointsCollectionView.hideLoader()
                    self?.sendPointsCollectionView.hideLoader()
                    self?.view.showErrorView {
                        self?.view.hideErrorView()
                        self?.viewModel.reload()
                    }
                    #if !APPSTRORE
                        self?.showAlert(title: "Error", message: "\(error)")
                    #endif
                }
            })
            .disposed(by: disposeBag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    // MARK: - Actions
    @objc func sendButtonDidTouch() {
        
    }
    
    @objc func convertButtonDidTouch() {
        guard let balance = currentBalance else {return}
        let vc: WalletConvertVC
        if balance.symbol == "CMN" {
            vc = WalletSellCommunVC(balances: (self.viewModel as! WalletViewModel).balancesVM.items.value)
        } else {
            vc = WalletBuyCommunVC(balances: (self.viewModel as! WalletViewModel).balancesVM.items.value, symbol: balance.symbol)
        }
        vc.completion = {
            self.viewModel.reload()
        }
        let nc = navigationController as? BaseNavigationController
        nc?.shouldResetNavigationBarOnPush = false
        show(vc, sender: nil)
        nc?.shouldResetNavigationBarOnPush = true
    }
    
    @objc func moreActionsButtonDidTouch(_ sender: CommunButton) {
        
    }
    
    @objc func sendPointsSeeAllDidTouch() {
        let vc = SendPointListVC { (user) in
            self.sendPoint(to: user)
        }
        let nc = BaseNavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }
    
    @objc func myPointsSeeAllDidTouch() {
        let vc = BalancesVC { balance in
            guard let index = self.balances?.firstIndex(where: {$0.symbol == balance.symbol}) else {return}
            self.headerView.setSelectedIndex(index)
        }
        let nc = BaseNavigationController(rootViewController: vc)
        present(nc, animated: true, completion: nil)
    }
    
    func sendPoint(to user: ResponseAPIContentGetSubscriptionsUser) {
        showAlert(title: "TODO: Send point", message: user.userId)
    }
    
    func addFriend() {
        showAlert(title: "TODO: Add friend", message: "add friend")
    }
}

extension WalletVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == sendPointsCollectionView {
            return CGSize(width: 90, height: SendPointCollectionCell.height)
        }
        return CGSize(width: 140, height: MyPointCollectionCell.height)
    }
}

extension WalletVC: WalletHeaderViewDelegate, WalletHeaderViewDatasource {
    func data(forWalletHeaderView headerView: WalletHeaderView) -> [ResponseAPIWalletGetBalance]? {
        balances
    }
    
    func walletHeaderView(_ headerView: WalletHeaderView, willUpdateHeightCollapsed isCollapsed: Bool) {
        if isCollapsed {return}
        resetTableViewContentInset()
    }
    
    func walletHeaderView(_ headerView: WalletHeaderView, currentIndexDidChangeTo index: Int) {
        tableHeaderView.setMyPointHidden(index != 0)
    }
    
    private func resetTableViewContentInset() {
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        if headerViewExpandedHeight == height {return}
        headerViewExpandedHeight = height
        tableView.contentInset = UIEdgeInsets(top: headerViewExpandedHeight - 20, left: 0, bottom: 0, right: 0)
        
        // change bounds without calling scrollViewDidScroll
        var bounds = tableView.bounds
        bounds.origin = CGPoint(x: 0, y: -headerViewExpandedHeight + 20)
        tableView.bounds = bounds
    }
}
