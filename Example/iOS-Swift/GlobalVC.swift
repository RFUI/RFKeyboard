//
//  GlobalVC.swift
//  Example-iOS
//
//  Created by BB9z on 2018/4/21.
//  Copyright © 2018 RFUI. All rights reserved.
//

/**
 
 */
class GlobalViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        enableSwitch.isOn = RFKeyboard.autoDisimssKeyboardWhenTouch
    }
    
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBAction func onSwitchChanged(_ sender: Any) {
        RFKeyboard.autoDisimssKeyboardWhenTouch = enableSwitch.isOn
    }
}
