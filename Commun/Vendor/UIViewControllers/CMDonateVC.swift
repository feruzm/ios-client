//
//  CMDonateVC.swift
//  Commun
//
//  Created by Chung Tran on 9/23/20.
//  Copyright © 2020 Commun Limited. All rights reserved.
//

import Foundation

class CMDonateVC<T: ResponseAPIContentMessageType>: CMSendPointsVC {
    // MARK: - Nested type
    class AmountButton: UIButton {
        var amount: CGFloat?
    }
    
    // MARK: - Properties
    override var titleText: String { "donate".localized().uppercaseFirst }
    override var actionName: String {"donate"}
    var message: T
    
    // MARK: - Subviews
    lazy var alertView: UIStackView = {
        let stackView = UIStackView(axis: .horizontal, spacing: 5, alignment: .center, distribution: .fill)
        stackView.addArrangedSubview(alertLabel)
        return stackView
    }()
    
    lazy var suggestedAmountButtons: [AmountButton] = [10, 100, 500, 1000].map {amount in
        let button = AmountButton(width: 64, height: 35, label: "+ \(amount)", labelFont: .systemFont(ofSize: 12, weight: .medium), backgroundColor: .appLightGrayColor, textColor: .appMainColor, cornerRadius: 35/2)
        button.amount = CGFloat(amount)
        button.addTarget(self, action: #selector(amountButtonDidTouch), for: .touchUpInside)
        return button
    }
    
    lazy var spacer = UIView.spacer(height: 1, backgroundColor: .clear)
    
    lazy var buyButton: UIButton = {
        let button = UIButton(height: 35, label: "+ " + "buy".localized().uppercaseFirst, labelFont: .systemFont(ofSize: 12, weight: .medium), backgroundColor: .appLightGrayColor, textColor: .appMainColor, cornerRadius: 35/2, contentInsets: UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15))
        button.addTarget(self, action: #selector(buyButtonDidTouch), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()
    
    init(selectedBalanceSymbol: String? = nil, receiver: ResponseAPIContentGetProfile? = nil, message: T, amount: Double? = nil) {
        self.message = message
        super.init(selectedBalanceSymbol: selectedBalanceSymbol, receiver: receiver)
        defer {
            self.viewModel.memo = "donation for \(selectedBalanceSymbol ?? ""):\(message.contentId.userId):\(message.contentId.permlink)"
            if let amount = amount {
                amountTextField.text = String(Double(amount).currencyValueFormatted)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setUp() {
        super.setUp()
        alertLabel.removeFromSuperview()
        
        stackView.addArrangedSubview(alertView)
        
        alertView.addArrangedSubview(alertLabel)
        alertView.addArrangedSubviews(suggestedAmountButtons)
        alertView.addArrangedSubview(buyButton)
        alertView.addArrangedSubview(spacer)
        buyButton.isHidden = true
        alertLabel.isHidden = true
    }
    
    override func setUpToolbar() {
        // do nothing
    }
    
    override func setUp(loading: Bool = false) {
        super.setUp(loading: loading)
        alertView.hideLoader()
        if loading {
            alertView.showLoader()
        }
    }
    
    override func bind() {
        super.bind()
        // observing
        T.observeItemChanged()
            .subscribe(onNext: { (post) in
                if post.identity == self.message.identity,
                    let newPost = self.message.newUpdatedItem(from: post)
                {
                    self.message = newPost
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func bindError() {
        super.bindError()
        viewModel.error
            .subscribe(onNext: { (error) in
                switch error {
                case .insufficientFunds:
                    self.alertLabel.isHidden = false
                    self.suggestedAmountButtons.forEach {$0.isHidden = true}
                    self.buyButton.isHidden = false
                    self.spacer.isHidden = true
                    self.alertLabel.text = "you don't have enough points for donation".localized().uppercaseFirst
                default:
                    self.alertLabel.isHidden = true
                    self.suggestedAmountButtons.forEach {$0.isHidden = false}
                    self.buyButton.isHidden = true
                    self.spacer.isHidden = false
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions
    override func chooseRecipientViewTapped(_ sender: UITapGestureRecognizer) {
        dismissKeyboard()
        // do nothing
    }
    
    @objc func buyButtonDidTouch() {
        dismissKeyboard()
        
        if let symbol = viewModel.selectedBalance?.symbol,
            symbol != Config.defaultSymbol
        {
            // Sell CMN
            let vc = GetPointsVC(balances: viewModel.balances, symbol: symbol)
            vc.backButtonHandler = {
                self.navigationController?.popToVC(type: Self.self)
            }
            self.show(vc, sender: nil)
        } else {
            // Buy CMN
            let vc = GetCMNVC(balances: viewModel.balances, symbol: viewModel.balances.first(where: {$0.balanceValue > 0 && $0.symbol != "CMN"})?.symbol)
            vc.backButtonHandler = {
                self.navigationController?.popToVC(type: Self.self)
            }
            self.show(vc, sender: nil)
        }
        
    }
    
    @objc func amountButtonDidTouch(_ button: UIButton) {
        guard let amount = (button as? AmountButton)?.amount else {return}
        programmaticallyChangeAmount(to: amount)
    }
    
    // MARK: - Helpers
    override func createChooseBalancesVC() -> BalancesVC {
        BalancesVC(showEmptyBalances: false) { (balance) in
            self.handleBalanceChosen(balance)
        }
    }
    
    override func transactionDidComplete(transaction: Transaction) {
        RestAPIManager.instance.getDonationsBulk(posts: [RequestAPIContentId(responseAPI: message.contentId)])
            .map {$0.items}
            .subscribe(onSuccess: { donations in
                guard let donation = donations.first(where: {$0.contentId == self.message.contentId}) else {return}
                self.message.donations = donation
                self.message.showDonationButtons = false
                self.message.notifyChanged()
            })
            .disposed(by: disposeBag)
        
        super.transactionDidComplete(transaction: transaction)
    }
    
    override func showCheck(transaction: Transaction) {
        let completedVC = WalletDonateCompletedVC(transaction: transaction)
        completedVC.backButtonHandler = {
            completedVC.backCompletion {
                self.back()
            }
        }
        show(completedVC, sender: nil)
    }
}
