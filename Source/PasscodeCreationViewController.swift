//
//  PasscodeCreationViewController.swift
//  SimplePasscode
//
//  Created by Zhu Shengqi on 5/8/16.
//  Copyright © 2016 Zhu Shengqi. All rights reserved.
//

import UIKit
import SnapKit

class PasscodeCreationViewController: UIViewController {
    enum CreationStage {
        case First
        case Confirm
    }
    
    // MARK: Private Properties
    private var stage: CreationStage = .First
    private var firstPasscode: String?
    private var secondPasscode: String?
    
    private lazy var shiftView: ShiftView<PasscodeInputView>! = {
        let firstInputView = PasscodeInputView()
        firstInputView.delegate = self
        
        let secondInputView = PasscodeInputView()
        secondInputView.delegate = self
        
        let shiftView = ShiftView(firstView: firstInputView, secondView: secondInputView)
        
        return shiftView
    }()
    
    // MARK: Public Properties
    var completionHandler: ((newPasscode: String?) -> Void)?
    
    // MARK: Init & Deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - VC Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        registerNotificationObservers()
        updateInputView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        shiftView.currentView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    // MARK: - Register Notification Observers
    private func registerNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillChange(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.keyboardWillChange(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    // MARK: - UI Config
    private func setupUI() {
        title = "New Passcode"
        
        view.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(self.cancelButtonTapped))
        
        view.addSubview(shiftView)
        shiftView.snp_remakeConstraints { make in
            make.top.equalTo(view).offset(64)
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        }
    }
    
    private func updateInputView() {
        shiftView.currentView.enabled = !FreezeManager.freezed
        
        if FreezeManager.freezed {
            shiftView.currentView.title = "Try again in \(FreezeManager.timeUntilUnfreezed) minute\(FreezeManager.timeUntilUnfreezed > 1 ? "s" : "")"
            
            shiftView.currentView.error = "\(FreezeManager.currentPasscodeFailures) Failed Passcode Attempts"
        } else {
            shiftView.firstView.title = "Enter a passcode"
            
            if let _ = secondPasscode {
                shiftView.firstView.message = "Passcode did not match.\nTry again"
            }
            
            shiftView.secondView.title = "Re-enter your passcode"
        }
    }
    
    // MARK: - Action Handlers
    func cancelButtonTapped() {
        completionHandler?(newPasscode: nil)

        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Notification Handlers
    func keyboardWillChange(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            return
        }
        
        guard let keyboardHeight = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue().height else {
            return
        }
        
        guard let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue else {
            return
        }
        
        guard let animationCurve = userInfo[UIKeyboardAnimationCurveUserInfoKey]?.unsignedIntegerValue else {
            return
        }
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: UIViewAnimationOptions(rawValue: animationCurve << 16), animations: {
            self.shiftView.snp_remakeConstraints { make in
                make.top.equalTo(self.view).offset(64)
                make.left.equalTo(self.view)
                make.right.equalTo(self.view)
                make.bottom.equalTo(self.view).offset(-keyboardHeight)
            }
            
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
}

extension PasscodeCreationViewController: PasscodeInputViewDelegate {
    func passcodeInputView(inputView: PasscodeInputView, didFinishWithPasscode passcode: String) {
        if inputView == shiftView.firstView {
            firstPasscode = passcode
            shiftView.secondView.passcode = ""
            shiftView.secondView.becomeFirstResponder()
            
            shiftView.shift(.Forward)
            
            return
        }
        
        if inputView == shiftView.secondView {
            secondPasscode = passcode
            
            if secondPasscode != firstPasscode {
                shiftView.firstView.passcode = ""
                updateInputView()
                shiftView.firstView.becomeFirstResponder()
                
                shiftView.shift(.Backward)
            } else {
                completionHandler?(newPasscode: passcode)

                dismissViewControllerAnimated(true, completion: nil)
            }
            
            return
        }
    }
}