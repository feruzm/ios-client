//
//  ProfileVC.swift
//  Commun
//
//  Created by Chung Tran on 10/22/19.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import Foundation
import RxSwift
import ESPullToRefresh

class ProfileVC<ProfileType: Decodable>: BaseViewController {
    override var contentScrollView: UIScrollView? {tableView}
    
    // MARK: - Constants
    let coverHeight: CGFloat = 180
    let coverVisibleHeight: CGFloat = 150
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    var _viewModel: ProfileViewModel<ProfileType> {
        fatalError("Must override")
    }
    
    // MARK: - Subviews
    lazy var backButton = UIButton.back(tintColor: .white, contentInsets: UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 24))
    
    lazy var coverImageView: UIImageView = {
        let imageView = UIImageView(forAutoLayout: ())
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: coverHeight)
        gradient.colors = [UIColor.black.withAlphaComponent(0.3).cgColor, UIColor.clear.cgColor]
        gradient.locations = [0.0, 1.0]
        imageView.layer.insertSublayer(gradient, at: 0)
        imageView.image = .placeholder
        return imageView
    }()
    
    var _headerView: ProfileHeaderView! {
        fatalError("Must override")
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(forAutoLayout: ())
        tableView.backgroundColor = .clear
        tableView.insetsContentViewsToSafeArea = false
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.showsVerticalScrollIndicator = false
        return tableView
    }()
    
    override func setUp() {
        super.setUp()

        view.backgroundColor = #colorLiteral(red: 0.9605136514, green: 0.9644123912, blue: 0.9850376248, alpha: 1)
        let leftButtonView = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 40))
        
        leftButtonView.addSubview(backButton)
        backButton.autoPinEdgesToSuperviewEdges()
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        leftButtonView.addSubview(backButton)

        let leftBarButton = UIBarButtonItem(customView: leftButtonView)
        navigationItem.leftBarButtonItem = leftBarButton

        coverImageView.removeAllConstraints()
        view.addSubview(coverImageView)
        coverImageView.autoPinEdge(.top, to: .top, of: view)
        coverImageView.heightConstraint?.constant = coverHeight
        
        view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges()
        tableView.contentInset.top = coverVisibleHeight
        tableView.contentInset.bottom = 60 + 10 + view.safeAreaInsets.bottom
        // setup datasource
        tableView.register(BasicPostCell.self, forCellReuseIdentifier: "BasicPostCell")
        tableView.register(ArticlePostCell.self, forCellReuseIdentifier: "ArticlePostCell")
        
        tableView.separatorStyle = .none
        tableView.setContentOffset(CGPoint(x: 0, y: -coverHeight), animated: true)
        
        // pull to refresh
        tableView.es.addPullToRefresh { [unowned self] in
            self.tableView.es.stopPullToRefresh()
            self.reload()
        }
        tableView.subviews.first(where: {$0 is ESRefreshHeaderView})?.alpha = 0
        navigationController?.navigationBar.barTintColor = .white
    }
    
    override func bind() {
        super.bind()
        bindControls()
        
        bindProfile()
        
        bindList()
    }
    
    func setUp(profile: ProfileType) {
    }
    
    func handleListLoading() {
        
    }
    
    func handleListEmpty() {
        
    }
    
    func bindItems() {
        
    }
    
    func cellSelected(_ indexPath: IndexPath) {
        
    }
    
    @objc func didTapTryAgain(gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel,
            let text = label.text else {return}
        
        let tryAgainRange = (text as NSString).range(of: "try again".localized().uppercaseFirst)
        if gesture.didTapAttributedTextInLabel(label: label, inRange: tryAgainRange) {
            _viewModel.fetchNext(forceRetry: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        showTitle(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if tableView.contentOffset.y >= -43 {
            showTitle(true)
        } else {
            showTitle(false)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let headerView = tableView.tableHeaderView {

            let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
            var headerFrame = headerView.frame

            //Comparison necessary to avoid infinite loop
            if height != headerFrame.size.height {
                headerFrame.size.height = height
                headerView.frame = headerFrame
                tableView.tableHeaderView = headerView
            }
        }
    }
    
    func showTitle(_ show: Bool, animated: Bool = false) {
        UIView.animate(withDuration: animated ? 0.3: 0) {
            self.navigationController?.navigationBar.setBackgroundImage(
                show ? nil: UIImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage =
                show ? nil: UIImage()
            self.navigationController?.view.backgroundColor =
                show ? .white: .clear
            self.navigationController?.navigationBar.setTitleFont(.boldSystemFont(ofSize: 17), color:
                show ? .black: .clear)
            self.navigationController?.navigationBar.tintColor =
                show ? .appMainColor: .white
            self.backButton.tintColor = show ? .black: .white
            self.navigationController?.navigationBar.barStyle = show ? .default : .black
        }
    }
    
    @objc func reload() {
        _viewModel.reload()
        _viewModel.fetchNext(forceRetry: true)
    }
}
