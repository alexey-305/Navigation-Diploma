import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: LoginViewModel
    var onLoginSuccess: (() -> Void)?
    
    init(viewModel: LoginViewModel = AppDependencyContainer.shared.makeLoginViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let loginTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.font = AppFonts.body
        textField.backgroundColor = AppColors.secondaryBackground
        textField.layer.cornerRadius = 10
        textField.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = AppColors.separator.cgColor
        textField.textColor = AppColors.primaryText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = .emailAddress
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.font = AppFonts.body
        textField.backgroundColor = AppColors.secondaryBackground
        textField.layer.cornerRadius = 10
        textField.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        textField.layer.borderWidth = 0.5
        textField.layer.borderColor = AppColors.separator.cgColor
        textField.textColor = AppColors.primaryText
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        textField.leftViewMode = .always
        textField.isSecureTextEntry = true
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 0
        stack.layer.cornerRadius = 10
        stack.clipsToBounds = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.setTitleColor(AppColors.onAccentText, for: .normal)
        button.titleLabel?.font = AppFonts.button
        button.backgroundColor = AppColors.accent
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    // MARK: - Задача 1: кнопка авторизации по биометрии
    private let biometricButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = AppColors.accent
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = AppColors.separator.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        return button
    }()
    
    private let localAuthorizationService = AppDependencyContainer.shared.localAuthorizationService
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        
        setupViews()
        setupConstraints()
        setupTextFields()
        setupButtonAction()
        setupTapGesture()
        bindViewModel()
        setupBiometricButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        loginTextField.layer.borderColor = AppColors.separator.cgColor
        passwordTextField.layer.borderColor = AppColors.separator.cgColor
        biometricButton.layer.borderColor = AppColors.separator.cgColor
    }
    
    // MARK: - Setup
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handle(state: state)
            }
        }
    }
    
    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(logoImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(loginButton)
        contentView.addSubview(biometricButton)
        
        stackView.addArrangedSubview(loginTextField)
        stackView.addArrangedSubview(passwordTextField)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 120),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 100),
            logoImageView.heightAnchor.constraint(equalToConstant: 100),
            
            stackView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 120),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.heightAnchor.constraint(equalToConstant: 100),
            
            loginButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 16),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            biometricButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            biometricButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            biometricButton.widthAnchor.constraint(equalToConstant: 50),
            biometricButton.heightAnchor.constraint(equalToConstant: 50),
            biometricButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupTextFields() {
        loginTextField.addTarget(self, action: #selector(textFieldsChanged), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldsChanged), for: .editingChanged)
    }
    
    private func setupButtonAction() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Задача 1 / 2*: настройка кнопки биометрии
    private func setupBiometricButton() {
        let biometricType = localAuthorizationService.availableBiometricType
        
        switch biometricType {
        case .faceID:
            biometricButton.setImage(UIImage(systemName: "faceid"), for: .normal)
            biometricButton.isHidden = false
        case .touchID:
            biometricButton.setImage(UIImage(systemName: "touchid"), for: .normal)
            biometricButton.isHidden = false
        case .none:
            biometricButton.isHidden = true
        }
        
        biometricButton.addTarget(self, action: #selector(biometricButtonTapped), for: .touchUpInside)
    }
    
    @objc private func biometricButtonTapped() {
        localAuthorizationService.authorizeIfPossible { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                self.onLoginSuccess?()
            } else {
                // Задача 2*: показываем пользователю причину неудачи
                let message = error?.localizedDescription ?? "Не удалось выполнить авторизацию по биометрии"
                self.showError(message)
            }
        }
    }
    
    // MARK: - Actions
    @objc private func textFieldsChanged() {
        let isEmailFilled = !(loginTextField.text?.isEmpty ?? true)
        let isPasswordFilled = !(passwordTextField.text?.isEmpty ?? true)
        
        loginButton.isEnabled = isEmailFilled && isPasswordFilled
        loginButton.alpha = loginButton.isEnabled ? 1.0 : 0.5
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func loginButtonTapped() {
        let email = loginTextField.text ?? ""
        let password = passwordTextField.text ?? ""
        viewModel.updateState(.loginButtonDidTap(email: email, password: password))
    }
    
    // MARK: - State handling
    private func handle(state: LoginViewState) {
        switch state {
        case .idle:
            break
        case .loading:
            loginButton.isEnabled = false
            loginButton.setTitle("Загрузка...", for: .normal)
        case .success:
            loginButton.isEnabled = true
            loginButton.setTitle("Log In", for: .normal)
            onLoginSuccess?()
        case .error(let message):
            loginButton.isEnabled = true
            loginButton.setTitle("Log In", for: .normal)
            loginButton.alpha = 1.0
            showError(message)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
