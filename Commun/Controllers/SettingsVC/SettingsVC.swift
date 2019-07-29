//
//  SettingsVC.swift
//  Commun
//
//  Created by Maxim Prigozhenkov on 22/04/2019.
//  Copyright © 2019 Maxim Prigozhenkov. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import CyberSwift
import RxDataSources
import LocalAuthentication
import THPinViewController

class SettingsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let bag = DisposeBag()
    let viewModel = SettingsViewModel()
    let currentBiometryType = LABiometryType.current
    
    var sectionHeaders: [UIView]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configure views
        tableView.rowHeight = UITableView.automaticDimension//56
        title = "Settings".localized()
        
        createHeaderViews()
        
        // Bind Views
        bindUI()
    }
    
    func bindUI() {
        // Bind table
        Observable.combineLatest(
                viewModel.currentLanguage,
                viewModel.nsfwContent,
                viewModel.notificationOn,
                viewModel.optionsPushShow,
                viewModel.showKey,
                viewModel.userKeys,
                viewModel.biometryEnabled
            )
            .map {(lang, nsfw, isNotificationOn, pushShow, showKey, keys, biometryEnabled) -> [Section] in
                var sections = [Section]()
                
                // first section
                sections.append(
                    .firstSection(header: "General", items: [
                        .option((key: "Interface language", value: lang.name)),
                        .option((key: "NSFW content", value: nsfw.localized())),
                        .option((key: "Change passcode", value: "")),
                        .switcher((key: "Use \(self.currentBiometryType.stringValue)", value: biometryEnabled, image: self.currentBiometryType.icon))
                    ])
                )
                
                // second section
                var rows = [Section.CustomData]()
                if let pushShow = pushShow, isNotificationOn {
                    rows += [
                        .switcher((key: NotificationSettingType.upvote.rawValue, value: pushShow.upvote, image: nil)),
                        .switcher((key: NotificationSettingType.downvote.rawValue, value: pushShow.downvote, image: nil)),
                        .switcher((key: NotificationSettingType.points.rawValue, value: pushShow.transfer, image: nil)),
                        .switcher((key: NotificationSettingType.comment.rawValue, value: pushShow.reply, image: nil)),
                        .switcher((key: NotificationSettingType.mention.rawValue, value: pushShow.mention, image: nil)),
                        .switcher((key: NotificationSettingType.rewardsPosts.rawValue, value: pushShow.reward, image: nil)),
                        .switcher((key: NotificationSettingType.rewardsVote.rawValue, value: pushShow.curatorReward, image: nil)),
                        .switcher((key: NotificationSettingType.following.rawValue, value: pushShow.subscribe, image: nil)),
                        .switcher((key: NotificationSettingType.repost.rawValue, value: pushShow.repost, image: nil))
                    ]
                }
                sections.append(
                    .secondSection(header: "Notifications", items: rows)
                )
                
                // third section
                rows = [Section.CustomData]()
                if showKey {
                    if let keys = keys {
                        for key in keys {
                            rows.append(.keyValue((key: key.key, value: key.value)))
                        }
                    }
                    rows.append(.button(ButtonType.changeAllPasswords.rendered))
                } else {
                    rows.append(.button(ButtonType.showAllPasswords.rendered))
                }
                
                sections.append(.thirdSection(header: "Private keys".localized(), items: rows))
                
                // forth section
                sections.append(.forthSection(items: [
                    .button(ButtonType.logout.rendered)
                ]))
                
                return sections
            }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        // Action
        tableView.rx.itemSelected
            .subscribe(onNext: { (indexPath) in
                switch indexPath.section {
                case 0:
                    switch indexPath.row {
                    case 0:
                        let vc = controllerContainer.resolve(LanguageVC.self)!
                        let nav = UINavigationController(rootViewController: vc)
                        self.present(nav, animated: true, completion: nil)
                        vc.didChangeLanguage
                            .subscribe(onNext: { (language) in
                                self.viewModel.currentLanguage.accept(language)
                                AppDelegate.reloadSubject.onNext(true)
                            })
                            .disposed(by: self.bag)
                    case 1:
                        let alert = UIAlertController(title: nil, message: "Select alert".localized(), preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: "Always alert".localized(), style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    case 2:
                        let verifyVC = SetPasscodeVC()
                        verifyVC.currentPin = Config.currentUser?.passcode
                        
                        // if passcode existed
                        if (Config.currentUser?.passcode != nil) {
                            verifyVC.isVerifyVC = true
                            verifyVC.completion = {
                                let setNewPasscodeVC = SetPasscodeVC()
                                setNewPasscodeVC.onBoarding = false
                                setNewPasscodeVC.completion = {
                                    self.navigationController?.popToViewController(self, animated: true)
                                    self.showDone("New passcode was set")
                                }
                                verifyVC.show(setNewPasscodeVC, sender: nil)
                            }
                            // if no passcode was set
                        } else {
                            verifyVC.completion = {
                                verifyVC.navigationController?.popToViewController(self, animated: true)
                            }
                        }
                        
                        self.show(verifyVC, sender: self)
                    default:
                        break
                    }
                    break
                default:
                    break
                }
            })
            .disposed(by: bag)
        
        // For headerInSection
        tableView.rx.setDelegate(self)
            .disposed(by: bag)
    }

}


