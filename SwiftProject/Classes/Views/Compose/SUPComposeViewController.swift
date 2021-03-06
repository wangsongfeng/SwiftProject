//
//  SUPComposeViewController.swift
//  SwiftProject
//
//  Created by NShunJian on 2018/7/12.
//  Copyright © 2018年 superMan. All rights reserved.
//

import UIKit
import SVProgressHUD
//  发微博控制器
class SUPComposeViewController: UIViewController {
   var observerSelected: NSObjectProtocol?
   var observerDeleted: NSObjectProtocol?
    //  MARK:   - 懒加载控件
    //  右边按钮
    private lazy var rightButton: UIButton  = {
        let button = UIButton()
        //  添加点击事件
        button.addTarget(self, action: #selector(SUPComposeViewController.sendAction), for: .touchUpInside)
        button.setTitle("发送", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        //  设置不同状态的文字颜色
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.gray, for: .disabled)
        
        //  设置不头痛状态的背景图片
        button.setBackgroundImage(UIImage(named: "common_button_orange"), for: .normal)
        button.setBackgroundImage(UIImage(named: "common_button_orange_highlighted"), for: .highlighted)
        button.setBackgroundImage(UIImage(named: "common_button_white_disable"), for: .disabled)
        //  设置大 小
        button.size = CGSize(width: 45, height: 30)
        //  不管用, 这个按钮被UIBarButtonItem管理者
        //        button.enabled = false
        
        //        button.userInteractionEnabled = false
        return button
        
    }()
    //  表情键盘
    private lazy var emoticonKeyBoard: SUPEmoticonKeyBoard = {
        
        let emoticonKeyBoard = SUPEmoticonKeyBoard()
        //  指定表情键盘大小
        emoticonKeyBoard.size = CGSize(width: self.textView.width, height: 216)
        return emoticonKeyBoard
        
    }()
    //  标题视图
    private lazy var titleView: UILabel = {
        let label = UILabel(fontSize: 17, textColor: UIColor.darkGray)
        
        if let name = SUPUserAccountViewModel.sharedUserAccount.userAccount?.name {
            let result = "发微博\n\(name)"
            //  获取名称的range
            let range = (result as NSString).range(of: name)
            
            let attribuedStr = NSMutableAttributedString(string: result)
            //  添加富文本属性
            attribuedStr.addAttributes([NSAttributedStringKey.foregroundColor: UIColor.lightGray, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)], range: range)
            
            label.attributedText = attribuedStr
        } else {
            label.text = "发微博"
        }
        
        //  多行显示
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        return label
    }()
    
    
    //  发微博视图
    private lazy var textView: SUPComposeTextView = {
        let view = SUPComposeTextView()
        //  设置代理
        view.delegate = self
        view.placeHolder = "请输入微博内容~"
        view.font = UIFont.systemFont(ofSize: 16)
        //  垂直方向开启拖动
        view.alwaysBounceVertical = true
        //  扩展 不想要纠错工具条的显示
        view.autocorrectionType = .no
        return view
    }()
    
    //  toolbar
    private lazy var toolBar: SUPComposeToolBar = {
        let composeToolbar = SUPComposeToolBar(frame: CGRect.zero)
//        composeToolbar.backgroundColor = UIColor.red
        return composeToolbar
    }()
    
    //  配图
    private lazy var pictureView: SUPComposePictureView = {
        let picView = SUPComposePictureView()
        
        return picView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    //  添加控件设置约束
    private func setupUI() {
        
        //  监听键盘改变的通知
        NotificationCenter.default.addObserver(self, selector: #selector(SUPComposeViewController.keyboardFrameChange(noti:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        //  监听点击表情按钮的通知
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSelectedEmoticon:", name: DidSelectedEmoticonNotification, object: nil)
        
        observerSelected = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: DidSelectedEmoticonNotification), object: nil, queue: nil) { [weak self] (noti) -> Void in
            
            //  监听通知方法的回调
//            print(self?.view)
            //  获取表情模型
            let emoticon = noti.object as! SUPEmoticon
            
            //  插入表情富文本
            self?.textView.insertEmoticon(emoticon: emoticon)
        }
        
        
        
        //  监听点击删除表情按钮的通知
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didSelecteDeleteEmoticon", name: DidSelectedDeleteEmoticonNotification, object: nil)
        
        observerDeleted = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: DidSelectedDeleteEmoticonNotification), object: nil, queue: nil) { [weak self] (noti) -> Void in
            
            //  监听通知方法的回调
//            print(self?.view)
            //  删除textview内容
            self?.textView.deleteBackward()
            
        }
        
        setupNavUI()
        
        //  添加控件
        view.addSubview(textView)
        textView.addSubview(pictureView)
        view.addSubview(toolBar)
        textView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.bottom.equalTo(toolBar.snp.top)
        }
        
        pictureView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(textView).offset(100)
            make.centerX.equalTo(textView)
            make.width.equalTo(textView.snp.width).offset(-10)
            make.height.equalTo(textView.snp.width).offset(-10)
        }
        
        toolBar.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.height.equalTo(35)
        }
        //传入闭包
        //  分析处理有循环引用 使用 [weak self]
        
        /* 当前控制器持有toolBar对象, 闭包持有当前控制器(SUPLog(self)), toolBar对象持有闭包
         
         */
        
        toolBar.didSelecteToolBarButtonClosure = { [weak self] (type: SUPComposeToolBarButtonType) in
            
            SUPLog(self) // 如果是这样 闭包持有self(当前控制器),  当前控制器又持有toolBar对象 toolBar对象持有闭包(didSelecteToolBarButtonClosure,在SUPComposeToolBar 里面点击调用闭包,当前SUPLog(self)里的self引用计数器就会加一,并且不会被释放), 造成循环引用,使用 [weak self]
            
            
            //  根据点击按钮的枚举值进行判断
            switch type {
                
            case .Picture:
                SUPLog("图片")
                self?.didSelectedPicture()
            case .Mention:
                SUPLog("@")
            case .Trend:
                SUPLog("#")
            case .Emoticon:
                SUPLog("表情")
                self?.didSelecedEmoticon()
            case .Add:
                SUPLog("加号")
            }
        }
        //  设置配图点击加号的闭包
        //当前控制器持有textView, textView持有pictureView ,pictureView持有闭包, 闭包持有当前控制器(self)self?.didSelectedPicture()
        pictureView.didSeletedAddImageViewClosure = { [weak self] in
            self?.didSelectedPicture()
        }
        
    }
    
    //  设置导航栏视图
    private func setupNavUI() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", target: self, action: #selector(SUPComposeViewController.cancelAction))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        //  设置右边的按钮不可用
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        //  设置导航栏的自定义titleView
        navigationItem.titleView = titleView
        
    }
    //  MARK:   - 监听点击删除表情按钮的通知方法
//    @objc private func didSelecteDeleteEmoticon() {
//        //  删除textview内容
//        textView.deleteBackward()
//
//    }
    
    
    //  MARK:   - 监听点击表情按钮的通知方法
//    @objc private func didSelectedEmoticon(noti: NSNotification) {
//
//        //  获取表情模型
//        let emoticon = noti.object as! SUPEmoticon
//
//        //  插入表情富文本
//        textView.insertEmoticon(emoticon: emoticon)
//
//    }
    //  MARK:   - 监听键盘改变的通知方法
    @objc private func keyboardFrameChange(noti: NSNotification) {
        
        SUPLog(noti.userInfo ?? nil)
        //  获取键盘的frame
        let keyBoardFrame = (noti.userInfo!["UIKeyboardFrameEndUserInfoKey"] as! NSValue).cgRectValue
        //  获取动画时长
        let duration = (noti.userInfo!["UIKeyboardAnimationDurationUserInfoKey"] as! NSNumber).doubleValue
        
        
        //  更新约束
        toolBar.snp.updateConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(keyBoardFrame.origin.y - self.view.height)
        }
        //  更新约束动画
        UIView.animate(withDuration: duration) { () -> Void in
            self.view.layoutIfNeeded()
        }
        
    }
    
    
    //  MARK:   - 点击事件
    @objc private func cancelAction() {
        
        //  取消第一响应者
        self.view.endEditing(true)
        
        dismiss(animated: true, completion: nil)
        
    }
    
    @objc private func sendAction() {
        SUPLog(textView.emoticonText)
        //  判断是否有没有图片,有图片调用上传图片的微博接口
        if pictureView.images.count > 0 {
            //  获取微博内容
            let status = textView.emoticonText //textView.text!
            //  获取accesstoken
            let accessToken = SUPUserAccountViewModel.sharedUserAccount.accessToken!
            //  获取图片
            let image = pictureView.images.first!
            
            SVProgressHUD.show()
            SUPNetworkTools.sharedTools.update(access_token: accessToken, status: status, image: image, callBack: { (response, error) in
                if error != nil {
                    SVProgressHUD.showError(withStatus: "网络异常, 发送失败")
                                    SUPLog(error)
                                    return
                                }
                
                SVProgressHUD.showSuccess(withStatus: "发送成功")
            })
            
    } else {
          //  没有图片执行的发送文字微博接口
        //  获取微博内容
        let status = textView.text!
        //  获取accesstoken
        let accessToken = SUPUserAccountViewModel.sharedUserAccount.accessToken!
        SVProgressHUD.show()
        //  请求发送微博文字接口
        SUPNetworkTools.sharedTools.update(access_token: accessToken, status: status) { (response, error) -> () in
            if error != nil {
                SVProgressHUD.showError(withStatus: "网络异常,发送失败")
                SUPLog(error)
                return
            }
            SVProgressHUD.showSuccess(withStatus: "发送成功")
        }
        
        
    }
}
    deinit {
        print("over")
        //  移除通知
        NotificationCenter.default.removeObserver(observerSelected!)
         NotificationCenter.default.removeObserver(observerDeleted!)
    }
}

    //  MARK:   点击toolbar按钮处理逻辑
    extension SUPComposeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        //  处理点击表情按钮逻辑
        func didSelecedEmoticon() {
            
            if textView.inputView == nil {
                //  设置自定义表情键盘
                textView.inputView = emoticonKeyBoard
                toolBar.switchEmotionIcon(isEmoticon: true)
            } else {
                //  设置为系统键盘
                textView.inputView = nil
                toolBar.switchEmotionIcon(isEmoticon: false)
            }
            
            //  设置其为第一响应者
            textView.becomeFirstResponder()
            //  重写刷新inputview
            textView.reloadInputViews()
            
        }
        
        //  处理点击图片逻辑
        func didSelectedPicture() {
            
            let picCtr = UIImagePickerController()//图片选择器
            picCtr.delegate = self
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                //  设置来源类型
                picCtr.sourceType = .camera
                
            } else {
                //  设置图库
                picCtr.sourceType = .photoLibrary
            }
            //  判断前置摄像头是否可用
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                
                SUPLog("前置摄像头可用")
            } else if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                SUPLog("后者摄像头可用")
            } else {
                SUPLog("没有摄像头")
            }
            
            //  是否允许编辑
            //picCtr.allowsEditing = true
            
            present(picCtr, animated: true, completion: nil)
            
        }
        
        //  MARK:   -UIImagePickerControllerDelegate 实现代理方法, 如果实现了代理方法直接调用dismis操作
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            //  添加配图信息
            let scaleImage = info["UIImagePickerControllerOriginalImage"] as! UIImage
            pictureView.addImage(image: scaleImage.scaleImageWithScaleWidth(scaleWidth: 200))
            //
            picker.dismiss(animated: true, completion: nil)
        }
        
        

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
             picker.dismiss(animated: true, completion: nil)
        }
        

    }
    
    //  MARK:   -实现UITextViewDelegate代理方法
    extension SUPComposeViewController: UITextViewDelegate {
        
        //  内容改变
        func textViewDidChange(_ textView: UITextView) {
            //  如果有内容则右侧按钮可用,否则不可用
            navigationItem.rightBarButtonItem?.isEnabled = textView.hasText
        }
        
        //  将要拖动的时候让其失去第一响应者
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            //  失去第一响应者
            self.view.endEditing(true)
        }
}
