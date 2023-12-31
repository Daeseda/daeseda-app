//
//  RequestViewController.swift
//  Daeseda
//
//  Created by 축신효상 on 2023/09/16.
//

import UIKit
import Alamofire


class RequestViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.isHidden = true
        
        fetchCategoryInfo()
        
        applyClothesListTableView.dataSource = self
        applyClothesListTableView.delegate = self
        
        listLabel.isHidden = true
        
        nextButton()
        textLabel()
        setupPicker()
        setupToolBar()
        
        //선택옵션 기능에 이용할 UIButton 배열 추가
        ButtonArray.append(generalButton)
        ButtonArray.append(specialButton)
        
        // deliveryDate를 초기화
        let currentDate = Date()
        if let newDate = Calendar.current.date(byAdding: .day, value: 3, to: currentDate) {
            deliveryDate = dateFormat(date: newDate)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "세탁 신청"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.title = .none
    }
    
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var timeTextField: UITextField!
    let datePicker = UIDatePicker()
    let timePicker = UIDatePicker()
    
    @IBOutlet weak var generalButton: UIButton!
    @IBOutlet weak var specialButton: UIButton!
    var ButtonArray = [UIButton]()
    
    @IBOutlet weak var categoryTextField: UITextField!
    let categoryPicker = UIPickerView()
    
    @IBOutlet weak var clothesTextField: UITextField!
    let clothesPicker = UIPickerView()
    
    
    @IBOutlet weak var countTextField: UITextField!
    
    
    @IBOutlet weak var listLabel: UILabel!
    
    
    @IBOutlet weak var applyClothesListTableView: UITableView!
    
    var way : String = ""
    var deliveryDate : String = ""
    var categoryIdMapping = [String: Int]()
    var categoryNames: [String] = []
    var selectCategoryId : Int = 0
    
    var clothesIdMapping = [String: Int]()
    var clothesPirceMapping = [String: Int]()
    var clothesNames: [String] = []
    var selectClothesId : Int = 0
    
    var totalClothesCount : [ClothesCount] = []
    
    func fetchCategoryInfo(){
        AF.request("\(baseURL.baseURLString)/category/list").responseDecodable(of: [Category].self) { response in
            switch response.result {
            case .success(let categories):
                for category in categories {
                    let categoryName = category.categoryName
                    let categoryId = category.categoryId
                    self.categoryIdMapping[categoryName] = categoryId
                    self.categoryNames.append(categoryName)
                }
                print("Category Names: \(self.categoryNames)")
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func fetchClothesInfo(categoryId: Int) {
        AF.request("\(baseURL.baseURLString)/clothes/list").responseDecodable(of: [GetClothes].self) { response in
            switch response.result {
            case .success(let clothes):
                self.clothesNames.removeAll()
                // categoryId값에 따라 필터링
                let filteredClothes = clothes.filter { $0.categoryId == categoryId }
                
                for cloth in filteredClothes {
                    let clothesName = cloth.clothesName
                    let clothesId = cloth.clothesId
                    self.clothesIdMapping[clothesName] = clothesId
                    self.clothesPirceMapping[clothesName] = Int(cloth.clothesPrice)
                    self.clothesNames.append(clothesName)
                }
                print("Clothes Names: \(filteredClothes)")
                print(self.clothesNames)
                
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    
    @IBAction func addClothes(_ sender: Any) {
        if let categoryName = categoryTextField.text, let categoryId = categoryIdMapping[categoryName] {
            selectCategoryId = categoryId
            print("Selected Category ID: \(categoryId)")
        } else {
            print("Invalid or unrecognized category name.")
        }
        
        if let clothesName = clothesTextField.text, let clothesId = clothesIdMapping[clothesName] {
            selectClothesId = clothesId
            print("Selected clothes ID: \(clothesId)")
        } else {
            print("Invalid or unrecognized category name.")
        }
        
        let clothes = Clothes(clothesId: selectClothesId, clothesName: clothesTextField.text!, categoryId: selectCategoryId)
        
        if let countText = countTextField.text, let count = Int(countText) {
            let clothesCount = ClothesCount(clothes: clothes, count: count)
            self.totalClothesCount.append(clothesCount)
        } else {
            print("수량 int형 변형 오류")
        }
        
        listLabel.isHidden = false

        
        categoryTextField.text = ""
        clothesTextField.text = ""
        countTextField.text = ""
        
        self.applyClothesListTableView.reloadData()
        
    }
    
    func nextButton(){
        let nextButton = UIButton()
        nextButton.frame = CGRect(x: 0, y: 0, width: 300, height: 40)
        nextButton.layer.backgroundColor = UIColor(red: 0.365, green: 0.553, blue: 0.949, alpha: 1).cgColor
        nextButton.layer.cornerRadius = 20
        
        self.view.addSubview(nextButton)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.widthAnchor.constraint(equalToConstant: 300).isActive = true
        nextButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        nextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50).isActive = true
        nextButton.addTarget(self, action: #selector(requestInfoVC), for: .touchUpInside)
        
        
        let naxtText = UILabel()
        naxtText.frame = CGRect(x: 0, y: 0, width: 300, height: 40)
        naxtText.textColor = UIColor.white
        naxtText.font = UIFont(name: "NotoSansKR-Bold", size: 20)
        // Line height: 27.24 pt
        naxtText.textAlignment = .center
        naxtText.text = "다음"
        
        self.view.addSubview(naxtText)
        naxtText.translatesAutoresizingMaskIntoConstraints = false
        naxtText.centerXAnchor.constraint(equalTo: nextButton.centerXAnchor).isActive = true
        naxtText.centerYAnchor.constraint(equalTo: nextButton.centerYAnchor).isActive = true
    }
    
    @objc func requestInfoVC() {
        guard  let requestInfoVC = storyboard?.instantiateViewController(withIdentifier: "requestInfo") as? RequestInfoViewController else { return }
        requestInfoVC.selectDate = self.dateTextField.text!
        requestInfoVC.selectTime = self.timeTextField.text!
        requestInfoVC.selectWay = self.way
        requestInfoVC.deliveryDate = self.deliveryDate
        requestInfoVC.totalClothesCount = self.totalClothesCount
        requestInfoVC.totalPrice = calculateTotalPrice()
        
        self.navigationController?.pushViewController(requestInfoVC, animated: true)
    }
    
    func calculateTotalPrice() -> Int {
        var totalPrice = 0

        for clothesCount in totalClothesCount {
            let clothesName = clothesCount.clothes.clothesName
            if let price = clothesPirceMapping[clothesName] {
                totalPrice += price * clothesCount.count
            }
        }

        return totalPrice
    }

    func textLabel() {
        
        let title = UILabel()
        title.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        title.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        title.font = UIFont(name: "GmarketSansTTFMedium", size: 30)
        title.numberOfLines = 0
        title.lineBreakMode = .byWordWrapping
        // Line height: 25 pt
        title.text = "쉽고 간편한\n세탁 서비스"
        
        self.view.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 38).isActive = true
        title.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
        
        let subTitle = UILabel()
        subTitle.frame = CGRect(x: 0, y: 0, width: 300, height: 50)
        subTitle.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        subTitle.font = UIFont(name: "GmarketSansTTFLight", size: 15)
        subTitle.numberOfLines = 0
        subTitle.lineBreakMode = .byWordWrapping
        // Line height: 25 pt
        subTitle.text = "양식에 맞추어 정보를 입력하세요."
        
        self.view.addSubview(subTitle)
        subTitle.translatesAutoresizingMaskIntoConstraints = false
        subTitle.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 38).isActive = true
        subTitle.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 170).isActive = true
        
        let dateLabel = UILabel()
        dateLabel.frame = CGRect(x: 0, y: 0, width: 56, height: 27)
        dateLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        dateLabel.font = UIFont(name: "NotoSansKR-Regular", size: 18)
        // Line height: 27.24 pt
        dateLabel.textAlignment = .center
        dateLabel.text = "수거일"
        
        self.view.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50).isActive = true
        dateLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 220).isActive = true
        
        let timeLabel = UILabel()
        timeLabel.frame = CGRect(x: 0, y: 0, width: 37, height: 27)
        timeLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        timeLabel.font = UIFont(name: "NotoSansKR-Regular", size: 18)
        // Line height: 27.24 pt
        timeLabel.textAlignment = .center
        timeLabel.text = "시간"
        
        self.view.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 280).isActive = true
        
        // Auto layout, variables, and unit scale are not yet supported
        let typeLabel = UILabel()
        typeLabel.frame = CGRect(x: 0, y: 0, width: 74, height: 27)
        typeLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        typeLabel.font = UIFont(name: "NotoSansKR-Regular", size: 18)
        // Line height: 27.24 pt
        typeLabel.textAlignment = .center
        typeLabel.text = "세탁종류"
        
        self.view.addSubview(typeLabel)
        typeLabel.translatesAutoresizingMaskIntoConstraints = false
        typeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50).isActive = true
        typeLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 340).isActive = true
        
        // Auto layout, variables, and unit scale are not yet supported
        let categoryLabel = UILabel()
        categoryLabel.frame = CGRect(x: 0, y: 0, width: 74, height: 27)
        categoryLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        categoryLabel.font = UIFont(name: "NotoSansKR-Regular", size: 18)
        // Line height: 27.24 pt
        categoryLabel.textAlignment = .center
        categoryLabel.text = "신청 품목"
        
        self.view.addSubview(categoryLabel)
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50).isActive = true
        categoryLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 400).isActive = true
        
    }
    
    func setupToolBar() {
        
        let dateToolBar = UIToolbar()
        let timeToolBar = UIToolbar()
        let categoryToolBar = UIToolbar()
        let clothesToolBar = UIToolbar()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let dateDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dateDoneButtonHandeler))
        let timeDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(timeDoneButtonHandeler))
        let categoryDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(categoryDoneButtonHandeler))
        let clothesDoneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(clothesDoneButtonHandeler))
        
        dateToolBar.items = [flexibleSpace, dateDoneButton]
        dateToolBar.sizeToFit()
        
        timeToolBar.items = [flexibleSpace, timeDoneButton]
        timeToolBar.sizeToFit()
        
        categoryToolBar.items = [flexibleSpace, categoryDoneButton]
        categoryToolBar.sizeToFit()
        
        clothesToolBar.items = [flexibleSpace, clothesDoneButton]
        clothesToolBar.sizeToFit()
        // textField의 경우 클릭 시 키보드 위에 AccessoryView가 표시됨.
        dateTextField.inputAccessoryView = dateToolBar
        timeTextField.inputAccessoryView = timeToolBar
        categoryTextField.inputAccessoryView = categoryToolBar
        clothesTextField.inputAccessoryView = clothesToolBar
    }
    
    @objc func dateDoneButtonHandeler(_ sender: UIBarButtonItem) {
        
        dateTextField.text = dateFormat(date: datePicker.date)
        
        // 키보드 내리기
        dateTextField.resignFirstResponder()
    }
    
    @objc func timeDoneButtonHandeler(_ sender: UIBarButtonItem) {
        
        timeTextField.text = timeFormat(date: timePicker.date)
        // 키보드 내리기
        timeTextField.resignFirstResponder()
    }
    
    @objc func categoryDoneButtonHandeler(_ sender: UIBarButtonItem) {
        
        // 키보드 내리기
        categoryTextField.resignFirstResponder()
    }
    
    @objc func clothesDoneButtonHandeler(_ sender: UIBarButtonItem) {
        
        // 키보드 내리기
        clothesTextField.resignFirstResponder()
    }
    
    @IBAction func selectOptionBtnAction(_ sender: UIButton) {
        for Btn in ButtonArray {
            if Btn == sender {
                Btn.isSelected = true
                Btn.tintColor = UIColor(red: 0.365, green: 0.553, blue: 0.949, alpha: 1)
                
                switch sender {
                case generalButton : way = "일반세탁"
                case specialButton :  way = "특수세탁"
                default : break
                }
            } else {
                Btn.isSelected = false
                Btn.tintColor = UIColor.black
            }
        }
    }
}

extension RequestViewController : UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    private func dateFormat(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter.string(from: date)
    }
    
    private func timeFormat(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        
        return formatter.string(from: date)
    }
    
    func setupPicker() {
        
        // Moded - time, date, dateAndTime, countDownTimer
        datePicker.datePickerMode = .date
        timePicker.datePickerMode = .time
        
        // 스타일 - wheels, inline, compact, automatic
        datePicker.preferredDatePickerStyle = .wheels
        timePicker.preferredDatePickerStyle = .wheels
        datePicker.locale = Locale(identifier: "ko-KR")
        
        // 값이 변할 때마다 동작을 설정
        datePicker.addTarget(self, action: #selector(dateChange), for: .valueChanged)
        timePicker.addTarget(self, action: #selector(timeChange), for: .valueChanged)
        
        // inputView가 nil이라면 기본 할당은 키보드
        dateTextField.inputView = datePicker
        timeTextField.inputView = timePicker
        
        categoryPicker.delegate = self
        categoryTextField.inputView = categoryPicker
        
        clothesPicker.delegate = self
        clothesTextField.inputView = clothesPicker
        
    }
    
    // 값이 변할 때 마다 동작
    @objc func dateChange(_ sender: UIDatePicker) {
        dateTextField.text = dateFormat(date: sender.date)
        
        let selectedDate = sender.date
        if let newDate = Calendar.current.date(byAdding: .day, value: 3, to: selectedDate) {
            dateTextField.text = dateFormat(date: selectedDate)
            deliveryDate = dateFormat(date: newDate)
        }
    }
    @objc func timeChange(_ sender: UIDatePicker) {
        timeTextField.text = timeFormat(date: sender.date)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // UIPickerView에서 행 수 설정
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == categoryPicker {
            return categoryNames.count
        } else if pickerView == clothesPicker {
            return clothesNames.count
        }
        return 0
    }
    
    // UIPickerView에 표시할 타이틀 설정
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == categoryPicker {
            return categoryNames[row]
        } else if pickerView == clothesPicker {
            
            return clothesNames[row]
        }
        return nil
    }
    
    // UIPickerView에서 선택된 항목 처리
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == categoryPicker {
            categoryTextField.text = categoryNames[row]
            if let categoryName = categoryTextField.text, let categoryId = categoryIdMapping[categoryName] {
                fetchClothesInfo(categoryId: categoryId)
                print("Selected Category ID: \(categoryId)")
            } else {
                print("Invalid or unrecognized category name.")
            }
        } else if pickerView == clothesPicker {
            clothesTextField.text = clothesNames[row]
        }
    }
    
}

extension RequestViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalClothesCount.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "applyClothesListCell", for: indexPath) as! ApplyClothesListTableViewCell
        
        let clothesCount = totalClothesCount[indexPath.row]
        
        let categoryId = clothesCount.clothes.categoryId
        if let categoryName = categoryNames.first(where: { categoryIdMapping[$0] == categoryId }) {
                cell.categoryLabel.text = categoryName
            }

        cell.clothesLabel.text = clothesCount.clothes.clothesName
        cell.countLabel.text = String(clothesCount.count)
        
        return cell
    }
    
    
}
