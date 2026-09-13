import XCTest
@testable import Navigation

final class CheckerServiceMock: CheckerServiceProtocol {
    var checkCredentialsResult: Result<Void, Error> = .success(())
    var signUpResult: Result<Void, Error> = .success(())
    private(set) var signUpCallCount = 0
    
    func checkCredentials(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        completion(checkCredentialsResult)
    }
    
    func signUp(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        signUpCallCount += 1
        completion(signUpResult)
    }
}

final class LoginViewModelTests: XCTestCase {
    
    private var checkerServiceMock: CheckerServiceMock!
    private var sut: LoginViewModel!
    
    override func setUp() {
        super.setUp()
        checkerServiceMock = CheckerServiceMock()
        sut = LoginViewModel(checkerService: checkerServiceMock)
    }
    
    override func tearDown() {
        checkerServiceMock = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - updateState(.loginButtonDidTap)
    
    func test_updateState_emptyFields_setsErrorState() {
        // when
        sut.updateState(.loginButtonDidTap(email: "", password: ""))
        
        // then
        XCTAssertEqual(sut.state, .error("Пожалуйста, заполните все поля"))
    }
    
    func test_updateState_invalidEmailFormat_setsErrorState() {
        // when
        sut.updateState(.loginButtonDidTap(email: "not-an-email", password: "123456"))
        
        // then
        XCTAssertEqual(sut.state, .error("Введите корректный email"))
    }
    
    func test_updateState_tooShortPassword_setsErrorState() {
        // when
        sut.updateState(.loginButtonDidTap(email: "user@example.com", password: "123"))
        
        // then
        XCTAssertEqual(sut.state, .error("Пароль должен быть не менее 6 символов"))
    }
    
    func test_updateState_validCredentials_success_setsSuccessState() {
        // given
        checkerServiceMock.checkCredentialsResult = .success(())
        
        // when
        sut.updateState(.loginButtonDidTap(email: "user@example.com", password: "123456"))
        
        // then
        XCTAssertEqual(sut.state, .success)
    }
    
    func test_updateState_validCredentials_genericFailure_setsErrorState() {
        // given
        let error = NSError(domain: "TestDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Wrong password"])
        checkerServiceMock.checkCredentialsResult = .failure(error)
        
        // when
        sut.updateState(.loginButtonDidTap(email: "user@example.com", password: "123456"))
        
        // then
        XCTAssertEqual(sut.state, .error("Wrong password"))
        XCTAssertEqual(checkerServiceMock.signUpCallCount, 0)
    }
    
    func test_updateState_userNotFound_triggersSignUpAndSetsSuccessState() {
        // given
        // код ошибки соответствует AuthErrorCode.userNotFound.rawValue из FirebaseAuth,
        // взят как литерал, чтобы не тянуть FirebaseAuth в тестовый таргет
        let userNotFoundError = NSError(domain: "FIRAuthErrorDomain", code: 17011, userInfo: nil)
        checkerServiceMock.checkCredentialsResult = .failure(userNotFoundError)
        checkerServiceMock.signUpResult = .success(())
        
        // when
        sut.updateState(.loginButtonDidTap(email: "new-user@example.com", password: "123456"))
        
        // then
        XCTAssertEqual(checkerServiceMock.signUpCallCount, 1)
        XCTAssertEqual(sut.state, .success)
    }
}
