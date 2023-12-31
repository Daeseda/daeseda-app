import UIKit
import Alamofire

class NameEditViewController: UIViewController {
    
    var nameData: String?
    
    @IBOutlet weak var nameEditCompleteBtn: UIButton!
    @IBOutlet weak var nameEditTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 터치 제스처 추가: 키보드 외의 영역 터치 시 키보드 내리기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // 텍스트 필드에 대한 이벤트 핸들러 설정
        nameEditTF.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        
        self.navigationItem.title = "이름 변경"
        
        updateButtonState()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationItem.title = .none
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updateButtonState()
    }
    
    func updateButtonState() {
        if let name = nameEditTF.text {
            if name.isEmpty || name == nameData {
                nameEditCompleteBtn.tintColor = UIColor.lightGray
                nameEditCompleteBtn.isEnabled = false
            } else {
                nameEditCompleteBtn.tintColor = UIColor(hex: 0x007AFF)
                nameEditCompleteBtn.isEnabled = true
            }
        }
    }
    
    func patchName() {
        let endPoint = "/users/name"
        if let name = nameEditTF.text {
            let fullURL = baseURL.baseURLString + endPoint
            
            // 1. 토큰 가져오기
            if let token = UserTokenManager.shared.getToken() {
                print("Token: \(token)")
                
                // 2. Bearer Token을 설정합니다.
                let headers: HTTPHeaders = ["Authorization": "Bearer " + token]
                
                // 3. JSON 요청 본문 데이터 설정
                let parameters: [String: String] = ["userName": name]
                
                // 4. 서버로 PATCH 요청 보내기
                AF.request(fullURL, method: .patch, parameters: parameters, encoder: JSONParameterEncoder.default, headers: headers)
                    .validate(statusCode: 200..<300)
                    .response { response in
                        switch response.result {
                        case .success:
                            print("name updated successfully")
                            self.navigationController?.popToRootViewController(animated: true)
                        case .failure(let error):
                            print("Error: \(error)")
                        }
                    }
            } else {
                print("Token not available.")
            }
        }
    }
    
    
    @IBAction func nameEditCompleteBtn(_ sender: UIButton) {
        patchName()
    }
    
    // 다른 영역 터치 시 키보드 내리기
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        nameEditTF.resignFirstResponder() // 현재 First Responder 해제
    }
}
