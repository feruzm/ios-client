//
//  TransactionCompletedView.swift
//  Commun
//
//  Created by Sergey Monastyrskiy on 24.12.2019.
//  Copyright © 2019 Commun Limited. All rights reserved.
//

import UIKit
import RxSwift

let disposeBag = DisposeBag()

enum ActionType {
    case home
    case wallet
    case `repeat`
}

class TransactionCompletedView: UIView {
    // MARK: - Properties
    var viewType: TransactionType = .send
    
    var recipientAvatarImageView: UIImageView = UIImageView.circle(size: CGFloat.adaptive(width: 40.0), imageName: "tux")

    var boldLabels = [UILabel]() {
        didSet {
            boldLabels.forEach({ $0.tune(withText: "",
                                         hexColors: blackWhiteColorPickers,
                                         font: UIFont.systemFont(ofSize: CGFloat.adaptive(width: 17.0), weight: .bold),
                                         alignment: .center,
                                         isMultiLines: false)})
        }
    }
    
    var semiboldLabels = [UILabel]() {
        didSet {
            semiboldLabels.forEach({ $0.tune(withText: "",
                                         hexColors: grayishBluePickers,
                                         font: UIFont.systemFont(ofSize: CGFloat.adaptive(width: 12.0), weight: .semibold),
                                         alignment: .center,
                                         isMultiLines: false)})
        }
    }

    var transactionDateLabel: UILabel = UILabel()
    var transactionTitleLabel: UILabel = UILabel()

    var transactionAmountLabel: UILabel = {
        let transactionAmountLabelInstance = UILabel()
        transactionAmountLabelInstance.tune(withText: "",
                                            hexColors: blackWhiteColorPickers,
                                            font: UIFont.systemFont(ofSize: CGFloat.adaptive(width: 20.0), weight: .bold),
                                            alignment: .right,
                                            isMultiLines: false)
        
        return transactionAmountLabelInstance
    }()

    var transactionCurrencyLabel: UILabel = {
        let transactionCurrencyLabelInstance = UILabel()
        transactionCurrencyLabelInstance.tune(withText: "",
                                              hexColors: grayishBluePickers,
                                              font: UIFont.systemFont(ofSize: CGFloat.adaptive(width: 20.0), weight: .semibold),
                                              alignment: .left,
                                              isMultiLines: false)
        
        return transactionCurrencyLabelInstance
    }()
    
    var recipientIDLabel: UILabel = UILabel()
    var recipientNameLabel: UILabel = UILabel()
    var burnedPercentLabel: UILabel = UILabel()

    let balanceNameLabel = UILabel()
    var balanceAvatarImageView: UIImageView = UIImageView.circle(size: CGFloat.adaptive(width: 30.0))

    var balanceAmountLabel: UILabel = {
        let senderBalanceLabelInstance = UILabel()
        senderBalanceLabelInstance.tune(withText: "",
                                        hexColors: whiteColorPickers,
                                        font: UIFont.systemFont(ofSize: CGFloat.adaptive(width: 15.0), weight: .bold),
                                        alignment: .right,
                                        isMultiLines: false)

        return senderBalanceLabelInstance
    }()
    
    let homeButton: UIButton = {
        let homeButtonInstance = UIButton(width: CGFloat.adaptive(width: 335.0),
                                                  height: CGFloat.adaptive(height: 50.0),
                                                  label: "home".localized().uppercaseFirst,
                                                  labelFont: .systemFont(ofSize: CGFloat.adaptive(width: 15.0), weight: .bold),
                                                  backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.1),
                                                  textColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
                                                  cornerRadius: CGFloat.adaptive(width: 50.0) / 2)
        return homeButtonInstance
    }()

    let backToWalletButton: UIButton = {
        let backToWalletButtonInstance = UIButton(width: CGFloat.adaptive(width: 335.0),
                                                  height: CGFloat.adaptive(height: 50.0),
                                                  label: "back to wallet".localized().uppercaseFirst,
                                                  labelFont: .systemFont(ofSize: CGFloat.adaptive(width: 15.0), weight: .bold),
                                                  backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
                                                  textColor: #colorLiteral(red: 0.416, green: 0.502, blue: 0.961, alpha: 1),
                                                  cornerRadius: CGFloat.adaptive(width: 50.0) / 2)
        return backToWalletButtonInstance
    }()

    let repeatButton: UIButton = {
        let repeatButtonInstance = UIButton(width: CGFloat.adaptive(width: 335.0),
                                                  height: CGFloat.adaptive(height: 50.0),
                                                  label: "repeat".localized().uppercaseFirst,
                                                  labelFont: .systemFont(ofSize: CGFloat.adaptive(width: 15.0), weight: .bold),
                                                  backgroundColor: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1),
                                                  textColor: #colorLiteral(red: 0.416, green: 0.502, blue: 0.961, alpha: 1),
                                                  cornerRadius: CGFloat.adaptive(width: 50.0) / 2)
        return repeatButtonInstance
    }()

    
    // MARK: - Class Initialization
    init(withType type: TransactionType) {
        self.viewType = type
        
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.adaptive(width: 335.0), height: CGFloat.adaptive(height: type == .send ? 641.0 : 567.0))))
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - Custom Functions
    private func setupView() {
        backgroundColor = .clear
        boldLabels = [transactionTitleLabel, recipientNameLabel]
        semiboldLabels = [transactionDateLabel, recipientIDLabel, burnedPercentLabel]
        
        // Add content view
        let contentView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: bounds.width, height: CGFloat.adaptive(height: 497.0))))
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = CGFloat.adaptive(width: 20.0)
        contentView.clipsToBounds = true

        // Add white view
        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewSafeArea(with: .zero, excludingEdge: .bottom)
        contentView.heightAnchor.constraint(equalToConstant: contentView.bounds.height).isActive = true
        
        // Add ready checkmark
        let readyCheckMarkButton = CommunButton.circle(size: CGFloat.adaptive(width: 60.0),
                                                       backgroundColor: #colorLiteral(red: 0.3125971854, green: 0.8584119678, blue: 0.6879913807, alpha: 1),
                                                       tintColor: UIColor.white,
                                                       imageName: "icon-checkmark-white",
                                                       imageEdgeInsets: .zero)
        
        readyCheckMarkButton.isUserInteractionEnabled = false
        contentView.addSubview(readyCheckMarkButton)
        readyCheckMarkButton.autoAlignAxis(toSuperviewAxis: .vertical)
        readyCheckMarkButton.autoPinEdge(.top, to: .top, of: contentView, withOffset: CGFloat.adaptive(height: 20.0))
        
        // Add shadow
        readyCheckMarkButton.addShadow(ofColor: #colorLiteral(red: 0.732, green: 0.954, blue: 0.886, alpha: 1),
                                       radius: CGFloat.adaptive(height: 24.0),
                                       offset: CGSize(width: 0.0, height: CGFloat.adaptive(height: 8.0)),
                                       opacity: 1.0)
        
        // Add titles
        let titlesStackView = UIStackView(axis: NSLayoutConstraint.Axis.vertical, spacing: CGFloat.adaptive(height: 8.0))
        titlesStackView.alignment = .center
        titlesStackView.distribution = .fillProportionally
        
        contentView.addSubview(titlesStackView)
        titlesStackView.addArrangedSubviews([transactionTitleLabel, transactionDateLabel])
        titlesStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(horizontal: CGFloat.adaptive(width: 44.0), vertical: CGFloat.adaptive(height: 190.0)), excludingEdge: .bottom)
        
        // Draw first dashed line
        let dashedLine1 = UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.adaptive(width: 291.0), height: CGFloat.adaptive(height: 2.0))))
        draw(dashedLine: dashedLine1)
        contentView.addSubview(dashedLine1)
        dashedLine1.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(horizontal: CGFloat.adaptive(width: 44.0), vertical: CGFloat.adaptive(height: 330.0)), excludingEdge: .bottom)

        // Add Recipient data
        let recipientStackView = UIStackView(axis: NSLayoutConstraint.Axis.horizontal, spacing: CGFloat.adaptive(width: 8.0))
        recipientStackView.alignment = .fill
        recipientStackView.distribution = .fillProportionally
        
        recipientStackView.widthAnchor.constraint(equalToConstant: CGFloat.adaptive(width: 280.0)).isActive = true
        recipientStackView.addArrangedSubviews([transactionAmountLabel, transactionCurrencyLabel])

        burnedPercentLabel.text = String(format: "%.1f%% %@ 🔥", 0.1, "was burned".localized())
        
        let recipientDataStackView = UIStackView(axis: NSLayoutConstraint.Axis.vertical, spacing: CGFloat.adaptive(height: 8.0))
        recipientDataStackView.alignment = .center
        recipientDataStackView.distribution = .fillProportionally
        
        contentView.addSubview(recipientDataStackView)
        recipientDataStackView.addArrangedSubviews([recipientStackView, burnedPercentLabel])
        recipientDataStackView.autoAlignAxis(toSuperviewAxis: .vertical)
        recipientDataStackView.autoPinEdge(.top, to: .bottom, of: dashedLine1, withOffset: CGFloat.adaptive(height: 32))

        contentView.addSubview(recipientAvatarImageView)
        recipientAvatarImageView.autoAlignAxis(toSuperviewAxis: .vertical)
        recipientAvatarImageView.autoPinEdge(.top, to: .bottom, of: dashedLine1, withOffset: CGFloat.adaptive(height: 92.0))

        let namesStackView = UIStackView(axis: NSLayoutConstraint.Axis.vertical, spacing: CGFloat.adaptive(height: 8.0))
        titlesStackView.alignment = .center
        titlesStackView.distribution = .fillProportionally
        
        contentView.addSubview(namesStackView)
        namesStackView.addArrangedSubviews([recipientNameLabel, recipientIDLabel])
        namesStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(horizontal: CGFloat.adaptive(width: 44.0), vertical: CGFloat.adaptive(height: 636.0)), excludingEdge: .bottom)

        // Draw second dashed line
        if let dashedLine2 = dashedLine1.copyView() {
            draw(dashedLine: dashedLine2)
            contentView.addSubview(dashedLine2)
            dashedLine2.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(horizontal: CGFloat.adaptive(width: 44.0), vertical: CGFloat.adaptive(height: 218.0)), excludingEdge: .top)
        }
        
        // Add circles
        let leftTopCircle = createCircleView(withColor: viewType == .send ? #colorLiteral(red: 0.416, green: 0.502, blue: 0.961, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), sideSize: CGFloat.adaptive(width: 24.0))
        contentView.addSubview(leftTopCircle)
        leftTopCircle.autoPinTopAndLeadingToSuperView(inset: CGFloat.adaptive(height: 154.0), xInset: CGFloat.adaptive(width: -24.0 / 2))

        let leftBottomCircle = createCircleView(withColor: viewType == .send ? #colorLiteral(red: 0.416, green: 0.502, blue: 0.961, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6), sideSize: CGFloat.adaptive(width: 24.0))
        contentView.addSubview(leftBottomCircle)
        leftBottomCircle.autoPinBottomAndLeadingToSuperView(inset: CGFloat.adaptive(height: 97.0), xInset: CGFloat.adaptive(width: -24.0 / 2))

        let rightTopCircle = createCircleView(withColor: viewType == .send ? #colorLiteral(red: 0.416, green: 0.502, blue: 0.961, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), sideSize: CGFloat.adaptive(width: 24.0))
        contentView.addSubview(rightTopCircle)
        rightTopCircle.autoPinTopAndTrailingToSuperView(inset: CGFloat.adaptive(height: 154.0), xInset: CGFloat.adaptive(width: -24.0 / 2))

        let rightBottomCircle = createCircleView(withColor: viewType == .send ? #colorLiteral(red: 0.416, green: 0.502, blue: 0.961, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.6), sideSize: CGFloat.adaptive(width: 24.0))
        contentView.addSubview(rightBottomCircle)
        rightBottomCircle.autoPinBottomAndTrailingToSuperView(inset: CGFloat.adaptive(height: 97.0), xInset: CGFloat.adaptive(width: -24.0 / 2))
        
        // Add 'Debited from' label
        let debitedFromLabel = UILabel()
        debitedFromLabel.tune(withText: "debited from".localized().uppercaseFirst,
                              hexColors: grayishBluePickers,
                              font: .systemFont(ofSize: CGFloat.adaptive(width: 12.0), weight: .semibold),
                              alignment: .center,
                              isMultiLines: false)
        
        contentView.addSubview(debitedFromLabel)
        debitedFromLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        debitedFromLabel.autoPinEdge(.top, to: .bottom, of: dashedLine1, withOffset: CGFloat.adaptive(height: 254.0))
        
        // Add blue bottom view
        let blueBottomView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: CGFloat.adaptive(width: 289.0), height: CGFloat.adaptive(height: 50.0))))
        blueBottomView.backgroundColor = #colorLiteral(red: 0.558, green: 0.629, blue: 1, alpha: 1)
        blueBottomView.roundCorners(UIRectCorner(arrayLiteral: [.topLeft, .topRight]), radius: CGFloat.adaptive(width: 15.0))
        
        contentView.addSubview(blueBottomView)
        blueBottomView.heightAnchor.constraint(equalToConstant: CGFloat.adaptive(height: 50.0)).isActive = true
        blueBottomView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(horizontal: CGFloat.adaptive(width: 46.0), vertical: 0.0), excludingEdge: .top)
        
        let senderStackView = UIStackView(axis: NSLayoutConstraint.Axis.horizontal, spacing: CGFloat.adaptive(width: 10.0))
        senderStackView.alignment = .fill
        senderStackView.distribution = .fill
                
        senderStackView.addArrangedSubviews([balanceAvatarImageView, balanceNameLabel, balanceAmountLabel])
        balanceNameLabel.setContentHuggingPriority(249.0, for: NSLayoutConstraint.Axis.horizontal)
        
        blueBottomView.addSubview(senderStackView)
        senderStackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(horizontal: CGFloat.adaptive(width: 30.0), vertical: CGFloat.adaptive(height: 20.0)))
        
        // Add action buttons
        let actionButtonsStackView = UIStackView(axis: NSLayoutConstraint.Axis.vertical, spacing: CGFloat.adaptive(height: 10.0))
        actionButtonsStackView.alignment = .center
        actionButtonsStackView.distribution = .fillEqually
        
        self.addSubview(actionButtonsStackView)
        actionButtonsStackView.addArrangedSubviews(viewType == .send ? [homeButton, backToWalletButton] : [repeatButton])
        actionButtonsStackView.autoPinEdge(.top, to: .bottom, of: contentView, withOffset: CGFloat.adaptive(width: viewType == .send ? 34.0 : 20.0))
        actionButtonsStackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }
    
    func actions(_ sender: @escaping (ActionType) -> Void) {
        // Home button
        homeButton.rx.tap
        .bind {
            print("Home button tapped")
            sender(.home)
        }
        .disposed(by: disposeBag)
        
        // Back to Wallet button
        backToWalletButton.rx.tap
        .bind {
            print("Back to Wallet button tapped")
            sender(.wallet)
        }
        .disposed(by: disposeBag)

        // Back to Wallet button
        repeatButton.rx.tap
        .bind {
            print("Repeat button tapped")
            sender(.repeat)
        }
        .disposed(by: disposeBag)
    }
    
    private func draw(dashedLine: UIView) {
        dashedLine.draw(lineColor: .e2e6e8,
                        lineWidth: CGFloat.adaptive(height: 2.0),
                        startPoint: CGPoint(x: 0.0, y: CGFloat.adaptive(height: 2.0) / 2),
                        endPoint: CGPoint(x: CGFloat.adaptive(width: 291.0), y: CGFloat.adaptive(height: 2.0) / 2),
                        withDashPattern: [10, 6])
        
        dashedLine.heightAnchor.constraint(equalToConstant: dashedLine.bounds.height).isActive = true
    }
    
    private func createCircleView(withColor color: UIColor, sideSize: CGFloat) -> UIView {
        let viewInstance = UIView(width: sideSize, height: sideSize, backgroundColor: color, cornerRadius: sideSize / 2)

        return viewInstance
    }
    
    func update(balance: Balance) {
        if let senderAvatarURL = balance.avatarURL {
            balanceAvatarImageView.setAvatar(urlString: senderAvatarURL, namePlaceHolder: "icon-select-user-grey-cyrcle-default")
        } else {
            let communLogo = UIView.transparentCommunLogo(size: CGFloat.adaptive(width: 30.0), backgroundColor: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2))
            balanceAvatarImageView.addSubview(communLogo)
            communLogo.autoAlignAxis(toSuperviewAxis: .vertical)
            communLogo.autoAlignAxis(toSuperviewAxis: .horizontal)
            communLogo.isUserInteractionEnabled = false
            balanceAvatarImageView.backgroundColor = .clear
        }

        balanceAmountLabel.text = balance.amount.formattedWithSeparator

        balanceNameLabel.tune(withText: balance.name,
                              hexColors: whiteColorPickers,
                              font: UIFont.systemFont(ofSize: CGFloat.adaptive(width: 15.0), weight: .semibold),
                              alignment: .left,
                              isMultiLines: false)
    }
    
    func update(recipient: Recipient) {
        recipientIDLabel.text = recipient.id
        recipientNameLabel.text = recipient.name
        recipientAvatarImageView.setAvatar(urlString: recipient.avatarURL, namePlaceHolder: recipient.name!)
    }
    
    func update(transaction: Transaction) {
        transactionTitleLabel.text = "transaction completed".localized().uppercaseFirst
        transactionDateLabel.text = transaction.operationDate.convert(toStringFormat: .transactionCompletedType)
        transactionAmountLabel.text = String(format: "%.*f", transaction.accuracy, transaction.amount)
        transactionCurrencyLabel.text = transaction.symbol.fullName
    }
}
