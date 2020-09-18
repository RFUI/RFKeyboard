//
//  GlobalVC.swift
//  Example-iOS
//
//  Created by BB9z on 2018/4/21.
//  Copyright © 2018 RFUI. All rights reserved.
//

/**
 
 */
final class GlobalViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        enableSwitch.isOn = RFKeyboard.autoDisimssKeyboardWhenTouch
    }
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet private weak var enableSwitch: UISwitch!
    @IBAction private func onSwitchChanged(_ sender: Any) {
        textField.resignFirstResponder()
        RFKeyboard.autoDisimssKeyboardWhenTouch = enableSwitch.isOn
    }
}
