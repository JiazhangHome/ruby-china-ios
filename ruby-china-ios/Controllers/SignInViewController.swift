import UIKit
import WebKit

protocol SignInViewControllerDelegate: class {
    func signInViewControllerDidAuthenticate(sender: SignInViewController)
}

class SignInViewController: UIViewController {
    weak var delegate: SignInViewControllerDelegate?
    var onDidAuthenticate: ((sender: SignInViewController) -> Void)?
    
    private var closeButton: UIBarButtonItem?
    
    private var loginField: RBTextField!
    private var passwordField: RBTextField!
    private var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "登录"
        
        closeButton = UIBarButtonItem.init(barButtonSystemItem: .Cancel, target: self, action: #selector(actionClose))
        
        navigationController?.navigationBar.tintColor = UIColor.blackColor()
        navigationItem.leftBarButtonItem = closeButton

        loginField = RBTextField.init(frame: CGRectMake(15, 100, self.view.frame.width - 30, 40))
        loginField.clearButtonMode = .WhileEditing
        loginField.autocorrectionType = .No
        loginField.keyboardType = .EmailAddress
        loginField.autocapitalizationType = .None
        loginField.placeholder = "用户名 / Email"
        loginField.delegate = self
        loginField.returnKeyType = .Next
        loginField.addTarget(self, action: #selector(textFieldDidChanged), forControlEvents: UIControlEvents.EditingChanged)
        
        passwordField = RBTextField.init(frame: CGRectMake(15, loginField.frame.maxY + 15, self.view.frame.width - 30, 40))
        passwordField.placeholder = "密码"
        passwordField.secureTextEntry = true
        passwordField.delegate = self
        passwordField.returnKeyType = .Done
        passwordField.addTarget(self, action: #selector(textFieldDidChanged), forControlEvents: UIControlEvents.EditingChanged)
        
        loginButton = UIButton.init(frame: CGRectMake(15, passwordField.frame.maxY + 25, self.view.frame.width - 30, 40))
        loginButton.setTitle("登录", forState: .Normal)
        loginButton.setBackgroundImage(UIImage.init(named: "button-normal"), forState: .Normal)
        loginButton.setBackgroundImage(UIImage.init(named: "button-down"), forState: .Highlighted)
        loginButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        loginButton.layer.cornerRadius = 6
        loginButton.addTarget(self, action: #selector(actionLogin), forControlEvents: .TouchDown)
        
        loginField.layer.cornerRadius = 0
        passwordField.layer.cornerRadius = 0
        
        view.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(loginField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)
        
        OAuth2.shared.delegate = self
        
        textFieldDidChanged()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loginField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        loginField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    func actionLogin() {
        if loginButton.enabled {
            OAuth2.shared.login(loginField.text!, password: passwordField.text!)
        }
    }
    
    func actionClose() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldDidChanged() {
        if let username = loginField.text, let password = passwordField.text where username != "" && password != "" {
            loginButton.enabled = true
        } else {
            loginButton.enabled = false
        }
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == loginField) {
            passwordField.becomeFirstResponder()
        }
        
        if (textField == passwordField) {
            actionLogin()
        }
        return true
    }
}

extension SignInViewController: OAuth2Delegate {
    func oauth2DidLoginSuccessed(accessToken: String) {
        print("Login successed", OAuth2.shared.accessToken)
        self.navigationController?.dismissViewControllerAnimated(false, completion: {
            self.delegate?.signInViewControllerDidAuthenticate(self)
            self.onDidAuthenticate?(sender: self)
            NSNotificationCenter.defaultCenter().postNotificationName(NOTICE_SIGNIN_SUCCESS, object: nil)
        })
    }
    
    func oauth2DidLoginFailed(error: NSError) {
        print("Login failed", error.localizedFailureReason)
        var errorMessage = ""
        errorMessage += error.localizedDescription
        if (error.localizedFailureReason != nil) {
            errorMessage += "\n" + error.localizedFailureReason!
        }
        let alert = UIAlertController(title: "登录失败", message: errorMessage, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "确定", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
