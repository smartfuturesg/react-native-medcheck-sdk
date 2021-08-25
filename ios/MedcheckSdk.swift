import Foundation
import CoreBluetooth
import QuartzCore
import CoreData

//extension String {
//  var ns: NSString {
//    return self as NSString
//  }
//}
//
//extension DateFormatter
//{
//  func setLocal() {
//    self.locale = Locale.init(identifier: "en_US_POSIX")
//    self.timeZone = TimeZone(abbreviation: "UTC")!
//  }
//}

struct ContactDetail {
  var id = "23423234"
  var user_id = "user234234"
  var name = "ravi"
  var dob = "1989-09-01"
  var weight = "72"
  var height = "185"
  var is_diabetics = ""
  var waist = ""
  var gender = "Male"
}

struct CurrentUserDetails {
  var key:String
  var value:String
}

struct WscaleUser {
  var key:String
  var value:String
}

enum BLEDevice : String {
  case BPM_BLE          = "HL158HC BLE"  //1
  case BGM_BLE          = "HL568HC BLE"  //2
  case BPM_BLE_NEW      = "SFBPBLE"  //1
  case BGM_BLE_NEW      = "SFBGBLE"
  case WSCAL_BLE        = "1144B"
  case WSCAL_BLE_New    = "SFBS1"
  case CheckMe_ViaTom   = "Checkme"
  case MedCheck_ViaTom   = "MedCheck"
}

public extension String {
  var trim : String {
    return trimmingCharacters(in: CharacterSet.whitespaces)
  }
  
  var length : Int {
    return self.count
  }
}

@objc(MedcheckSdk)
class MedcheckSdk: RCTEventEmitter {
  private typealias `Self` = MedcheckSdk
  
  static let MODULE_NAME = "MedcheckSdk"
  
  static let INIT_ERROR = "INIT_ERROR"
  static let PAIR_ERROR = "PAIR_ERROR"
  static let UNKNOWN_ERROR = "UNKNOWN_ERROR"
  
  static let UNKOWN_ERROR_MSG = "Unknown runtime Objective-C error (MedcheckSdk)."
  
  let SCAN_BEGAN = "SCAN_BEGAN"
  let SCAN_END = "SCAN_END"
  let SCAN_FAILED = "SCAN_FAILED"
  
  static let DATA_EVENT = "data"
  static let DEVICE_FOUND_EVENT = "deviceFound"
  static let DEVICE_CONNECTED_EVENT = "deviceConnected"
  static let DEVICE_DISCONNECTED_EVENT = "deviceDisconnected"
  static let AMBIGUOUS_DEVICE_FOUND_EVENT = "ambiguousDeviceFound"
  static let SCAN_FINISHED_EVENT = "scanFinished"
  static let COLLECTION_FINISHED_EVENT = "collectionFinished"
  static let USER_LIST_FOUND_EVENT = "userListFound"
  
  //Local Variables
  let lsBleManager = LSBLEDeviceManager.defaultLsBle()
  var lsDatabaseManager: LSDatabaseManager?
  var lsCurrentDeviceUser: DeviceUser?
  
  var currentConnectedProtocol = ""
  var dataMap = NSMutableDictionary()
  var weightDataMap = NSMutableDictionary()
  
  var weightDataList = [LSWeightData]()
  var fatDataList = [LSWeightAppendData]()
  var currentConnectedBMIDevice: LSDeviceInfo?
  var pairingUserNumber = 1
  
  var contactArray = [ContactDetail]()
  var selectedUserDetails: ContactDetail?
  var arrBLEList = [CBPeripheral]()
  var arrLSBLEList = [LSDeviceInfo?]()
  var macAddress = [String]()
  var rnBmiDeviceList = [Any]()
  var rnMultiDataList = [Any]()
  var arrNewlyFetchedResults = [[String : AnyObject]]()
  
  var currentWeightData: LSWeightData?
  
  
  override func constantsToExport() -> [AnyHashable : Any] {
    return [
      "EVENTS": supportedEvents()
    ]
  }
  
  private func emitEvent(_ eventName: String, withData data: Any?) {
    print(Self.MODULE_NAME, "Send \(eventName) event.")
    sendEvent(withName: eventName, body: data)
  }
  
  private func mapDeviceDescription(_ lsDevice: LSDeviceInfo, isDeviceAlreadyPaired: Bool) -> [String: Any] {
    return [
      "id": lsDevice.broadcastId,
      "deviceId": lsDevice.deviceId,
      "deviceSn": lsDevice.deviceSn,
      "deviceType": lsDevice.deviceType.rawValue,
      "modelNumber": lsDevice.modelNumber,
      "peripheralIdentifier": lsDevice.peripheralIdentifier,
      "deviceName": lsDevice.deviceName ?? "Unknown",
      "state": isDeviceAlreadyPaired,
    ]
  }
 
  
  private func mapUser(_ key: String, value: String) -> [String: Any] {
    return [
      "key": key,
      "value": value,
    ]
  }
  
  
  private func mapWeightData(_ wData: LSWeightData ) -> [String: String] {
    return [
        "batteryValue" : wData.batteryValue.description,
        "broadcastId" : wData.broadcastId.description,
        "date" : wData.date.description,
        "deviceId" : wData.deviceId.description,
        "deviceSelectedUnit" : wData.deviceSelectedUnit.description,
        "hasAppendMeasurement" : wData.hasAppendMeasurement.description,
        "lbWeightValue" : wData.lbWeightValue.description,
        "pbf" : wData.pbf.description,
        "resistance_1" : wData.resistance_1.description,
        "resistance_2" : wData.resistance_2.description,
        "stSectionValue" : wData.stSectionValue.description,
        "stWeightValue" : wData.stWeightValue.description,
        "userNo" : wData.userNo.description,
        "utc" : wData.utc.description,
        "voltageValue" : wData.voltageValue.description,
        "weight" : wData.weight.description,
  ]
  }
  
  private func mapAppendWeightData(_ wData: LSWeightAppendData ) -> [String: Any] {
    return [
        "deviceId" : wData.deviceId.description,
        "utc" : wData.utc.description,
        "userId" : wData.userId.description,
        "basalMetabolism" : wData.basalMetabolism.description,
        "bodyFatRatio" : wData.bodyFatRatio.description,
        "bodywaterRatio" : wData.bodywaterRatio.description,
        "visceralFatLevel" : wData.visceralFatLevel.description,
        "muscleMassRatio" : wData.muscleMassRatio.description,
        "boneDensity" : wData.boneDensity.description,
        "battery" : wData.battery.description,
        "voltageData" : wData.voltageData.description,
        "bmiLevel" : wData.bmiLevel.description,
        "measuredTime" : wData.measuredTime.description,
    ]
  }
  
  public func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      closure()
    }
  }
  
  @objc func initialize(_ userDetails: NSDictionary,
                        resolver resolve: RCTPromiseResolveBlock,
                        rejecter reject: RCTPromiseRejectBlock) {
    var response = "NO_RESPONSE"
    var status = false
    do {
      
      self.lsDatabaseManager = LSDatabaseManager.default()
      self.lsDatabaseManager?.databaseDelegate = self
      self.lsDatabaseManager?.createManagedObjectContext(withDocumentName: "LifesenseBleDatabase")
      
//      print("userDetails", userDetails)
//      print(userDetails["id"].debugDescription)
//      print(userDetails["first_name"])
//      print(userDetails["dob"])
//      print(userDetails["weight"])
//      print(userDetails["height"])
//      print(userDetails["gender"])
      
//      guard
        let id = userDetails["id"]
        let name = userDetails["first_name"]
        let dob = userDetails["dob"]
        let weight = userDetails["weight"]
        let height = userDetails["height"]
        let gender = userDetails["gender"]
//        else {
//          print("Provided user format is not supported")
//          response = "UNSUPPORTED_USER"
//          resolve(["message": response, "status": status ])
//          return
//      }
      
      selectedUserDetails = ContactDetail(id: "\(id ?? "unknown")", user_id: "\(id ?? "unknown")", name: "\(name ?? "unknown")", dob: "\(dob ?? "1998-01-01")", weight: "\(weight ?? "70")", height: "\(height ?? "6")", is_diabetics: "", waist: "", gender: "\(gender ?? "m")")
      
//      selectedUserDetails?.id = "\(id ?? "unknown")"
//      selectedUserDetails?.user_id = "\(id ?? "unknown")"
//      selectedUserDetails?.name = "\(name ?? "unknown")"
//      selectedUserDetails?.dob = "\(dob ?? "1998-01-01")"
//      selectedUserDetails?.weight = "\(weight ?? "70")"
//      selectedUserDetails?.height = "\(height ?? "6")"
//      selectedUserDetails?.is_diabetics = ""
//      selectedUserDetails?.waist = ""
//      selectedUserDetails?.gender = "\(gender ?? "m")"
      
      print("=====> \(String(describing: selectedUserDetails)) <=====")
      
      if(lsBleManager!.isBluetoothPowerOn) {
        print("BLUETOOTH ON")
        status = true
//        resolve(["status" : true])
      } else {
        status = false
        print("BLUETOOTH OFF")
//        resolve(["status" : false])
      }
      
      try ObjC.catchException {
        self.loadDataFromDatabase()
      }
      resolve(["message": response, "status": status ])
    } catch {
      let msg = "Incorrect Device."
      reject(Self.INIT_ERROR, msg, error)
    }
  }
  
  @objc func startScan(_ resolve: RCTPromiseResolveBlock,
                       rejecter reject: RCTPromiseRejectBlock) {
    
    do {
      print(Self.MODULE_NAME, "Start scanning for devices.")
      try ObjC.catchException {
        self.searchBluetoothDevice()
      }
      resolve([ "message": SCAN_BEGAN ])
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func disconnectFromDevice(_ uuid: String,
                                  resolver resolve: RCTPromiseResolveBlock,
                                  rejecter reject: RCTPromiseRejectBlock) {
    
  }
  
  @objc func startCollection(_ resolve: RCTPromiseResolveBlock,
                             rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        
      }
      resolve(nil)
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func connectToDevice(_ uuid: String,
                             resolver resolve: RCTPromiseResolveBlock,
                             rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        print("====> \(uuid) <====")
        
        let peripheral = self.arrLSBLEList.filter({ (item) -> Bool in
          return item?.deviceName.description.contains(uuid ) ?? false
        })
        
        if(peripheral.count > 0 && peripheral[0] != nil) {
          let peripheral = peripheral[0]
          
          if ((peripheral?.deviceName?.contains("1144B"))! || (peripheral?.deviceName?.contains("SFBS1"))!){
            
            self.lsBleManager?.stopSearch()
            let tempItem = self.arrLSBLEList[0]
            
            print("=====> tempItem <======", tempItem)
            
            if tempItem!.preparePair{
              if tempItem?.broadcastId != nil{
                  self.lsBleManager?.deleteMeasureDevice(tempItem?.broadcastId)

              }
              self.lsBleManager?.pair(with: tempItem, pairedDelegate: self)
            } else {
              self.setupProductUserInfoOnPairingMode()
              //              self.bluetoothManager.stopScanPeripheral()
              //              self.lsBleManager?.stopDataReceiveService()
              self.currentConnectedBMIDevice = tempItem
              
              
              self.loadDataFromDatabase()
              //BMI Scanning started
              
              if self.lsCurrentDeviceUser == nil{
                self.lsCurrentDeviceUser = self.setupCurrentDeviceUser()
              }
              
              self.lsDatabaseManager?.databaseDelegate = self
              self.lsBleManager?.connectDevice(self.currentConnectedBMIDevice!, connectDelegate: self)
              self.lsBleManager?.startDataReceiveService(self)
              
            }
          }
        }
          
        
        
      }
      resolve(nil)
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func stopScan(_ resolve: RCTPromiseResolveBlock,
                      rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        self.lsBleManager?.stopSearch()
      }
      resolve(nil)
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func stopReceivingData(_ resolve: RCTPromiseResolveBlock,
                               rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        self.lsBleManager?.stopDataReceiveService()
      }
      resolve(nil)
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func pairUser(_ user: NSDictionary,
                             resolver resolve: RCTPromiseResolveBlock,
                             rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        
        guard let key = user["key"] as? String,
          let value = user["value"] as? String else {
            print("Provided user format is not supported")
            return
        }
        
        let object = WscaleUser(key: key, value: value)
        
        print("PAIR TO USER", object.value, object.key)
        self.lsBleManager?.bindingDeviceUsers(UInt(object.key)!, userName: self.selectedUserDetails?.name ?? object.value)

      }
      resolve(["message" : "Pairing user" ])
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  override func supportedEvents() -> [String]! {
    return [
      Self.DATA_EVENT, Self.DEVICE_FOUND_EVENT, Self.DEVICE_CONNECTED_EVENT,
      Self.DEVICE_DISCONNECTED_EVENT, Self.AMBIGUOUS_DEVICE_FOUND_EVENT,
      Self.SCAN_FINISHED_EVENT, Self.COLLECTION_FINISHED_EVENT,
       Self.USER_LIST_FOUND_EVENT
    ]
  }
  
  override static func requiresMainQueueSetup() -> Bool {
    return true
  }
  
  func setupProductUserInfoOnSyncMode(deviceID: String, userNumber: Int){
    delay(0.33) {
      if deviceID.length > 0 {
        var userID = ""
//        if self.lsCurrentDeviceUser == nil{
//          userID = "10090"
//        }
//        else{
          userID = "10090"
//        }
        let queryPredicate = NSPredicate.init(format: "userID = %@", userID)
        if let deviceUser = (self.lsDatabaseManager!.allObjectForEntity(forName: "DeviceUser", predicate: queryPredicate)).last as? DeviceUser{
          
          print("setupProductUserInfoOnSyncMode \(DataFormatConverter.parseObjectDetail(inDictionary: deviceUser))")
          
          self.lsCurrentDeviceUser = deviceUser
          
          let userInfo = DataFormatConverter.getProductUserInfo(deviceUser)
          userInfo?.deviceId = deviceID
          userInfo?.userNumber = UInt(userNumber)
          if deviceUser.gender == "Male" {
            userInfo?.sex = SEX_MALE
          }
          else{
            userInfo?.sex = SEX_FEMALE
          }
          userInfo?.height = (deviceUser.height?.floatValue)!
          userInfo?.goalWeight = (deviceUser.weight?.floatValue)!
          
          if deviceUser.birthday != nil{
            let calendar = Calendar(identifier: .gregorian)
            
            var dateComponents = calendar.dateComponents([.hour, .minute, .year], from: (deviceUser.birthday)!)
            
            let year = dateComponents.year
            
            dateComponents = calendar.dateComponents([.hour, .minute, .year], from: Date())
            
            let currentYear = dateComponents.year
            userInfo?.age = UInt(currentYear! - year!)
          }
          else{
            userInfo?.age = 26
          }
          
          if deviceUser.userprofiles?.weightUnit == "Lb"{
            userInfo?.unit = UNIT_LB
          }
          else if deviceUser.userprofiles?.weightUnit == "St"{
            userInfo?.unit = UNIT_ST
          }
          else{
            userInfo?.unit = UNIT_KG
          }
          
          
          userInfo?.athleteLevel = (deviceUser.athleteLevel?.uintValue)!
          
          print("set product user info on sync mode %@",DataFormatConverter.parseObjectDetail(inDictionary: userInfo));
          self.lsBleManager?.setProductUserInfo(userInfo)
        }
      }
    }
  }
}

//MARK: BMI Classes
enum LSDeviceType: Int {
  case TYPE_UNKONW = 0
  case LS_WEIGHT_SCALE = 1
  case LS_FAT_SCALE = 2
  case LS_HEIGHT_MIRIAM = 3
  case LS_PEDOMETER = 4
  case LS_WAISTLINE_MIRIAM = 5
  case LS_GLUCOSE_METER = 6
  case LS_THERMOMETER = 7
  case LS_SPHYGMOMETER = 8
  case LS_KITCHEN_SCALE = 9
}

extension MedcheckSdk:LSBlePairingDelegate {
  func getEnableScanDeviceTypes() -> [Int]{
    var enableTypes = [Int]()
    enableTypes.append(LSDeviceType.LS_FAT_SCALE.rawValue)
    return enableTypes
  }
  
  func bleManagerDidDiscoverUserList(_ userlist: [AnyHashable : Any]!) {
    print("userList: \(userlist)")
    
    let maxUserNumber = userlist.count
    let deviceUserArray = NSMutableArray()
    
    if maxUserNumber > 0 {
      // Create and add first option action
      var username = ""
      var title = ""
      var key = ""
      
      var userNameDict = [String : String]()
      var userListArray = [Any]()
      for (key, value) in userlist {
//        print(key, value)
        userNameDict["\(key)"] = value as? String ?? "Unknown"
        userListArray.append(mapUser("\(key)", value: value as? String ?? "Unknown"))
      }
      
      self.emitEvent(Self.USER_LIST_FOUND_EVENT, withData: userListArray)
      for (index, userData) in self.contactArray.enumerated(){
          userNameDict["\(index+1)"] = userData.name
      }
      
      for index in 1...maxUserNumber {
        key = "\(index)"
        if let uName = userNameDict[key]{
          username = uName
        }
        title = "P\(key):\(username)"
        print(title)
      }
      
        var userName = "Unknown"
//      self.selectedUserDetails = userNameDict[0]
//      self.lsBleManager?.bindingDeviceUsers(1, userName: userNameDict["\(key)"])
      //TODO:- Undo for direct connection
//      self.lsBleManager?.bindingDeviceUsers(1, userName: userNameDict["\(1)"])
      
    }
    
    
    
    
//    if maxUserNumber > 0 {
//      // MARK: These are the available users in BMI Device
//      // Select User to Pair
//      let actionSheetController = UIAlertController(title: "MedCheck", message: "Select User to Pair", preferredStyle: .actionSheet)
//
//      // Create and add the Cancel action
//      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
//        // Just dismiss the action sheet
//      }
//      actionSheetController.addAction(cancelAction)
//
//      // Create and add first option action
//      var username = ""
//      var title = ""
//      var key = ""
//
//      var userNameDict = [String : String]()
//      for (key, value) in userlist {
//        //print(key, value)
//        userNameDict["\(key)"] = value as? String ?? "Unknown"
//      }
//
//      for index in 1...maxUserNumber {
//        key = "\(index)"
//        if let uName = userNameDict[key]{
//          username = uName
//        }
//        title = "P\(key):\(username)"
//        let takePictureAction = UIAlertAction(title: title, style: .default) { action -> Void in
//
//          self.delay(0.3, closure: {
//            let actionSheetInnerController = UIAlertController(title: "Medilives", message: "Select User to Pair", preferredStyle: .actionSheet)
//
//            for (_, userData) in self.contactArray.enumerated(){
//              let selectUser = UIAlertAction(title: userData.name, style: .default) { action -> Void in
//                //print("selected user \(userData)")
//                self.selectedUserDetails = userData
//                self.lsBleManager?.bindingDeviceUsers(UInt(index), userName: userData.name)
//              }
//              actionSheetInnerController.addAction(selectUser)
//            }
//
//            actionSheetInnerController.popoverPresentationController?.sourceView = self.view as UIView
//            self.present(actionSheetInnerController, animated: true, completion: nil)
//          })
//
//        }
//
//        actionSheetController.addAction(takePictureAction)
//        if username.count == 0{
//          username = "Unknown"
//        }
//        deviceUserArray.add(username)
//      }
////      actionSheetController.popoverPresentationController?.sourceView = self.view as UIView
////      self.present(actionSheetController, animated: true, completion: nil)
//    }
    
    //        self.lsBleManager?.bindingDeviceUsers(1, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(2, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(3, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(4, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(5, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(6, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(7, userName: UserInfo.savedUser()?.name)
    //        self.lsBleManager?.bindingDeviceUsers(8, userName: UserInfo.savedUser()?.name)
  }
  
  func bleManagerDidPairedResults(_ lsDevice: LSDeviceInfo!, pairStatus: Int32) {
    
    print("bleManagerDidPairedResults: \(String(describing: lsDevice)) pair status: \(pairStatus)")
    
    if pairStatus == 1 {
        print("Paired Results", lsDevice)
      self.emitEvent(Self.DEVICE_CONNECTED_EVENT, withData: self.mapDeviceDescription(lsDevice, isDeviceAlreadyPaired: true))
      
      if self.lsCurrentDeviceUser == nil{
        self.lsCurrentDeviceUser = self.setupCurrentDeviceUser()
      }
      
      let userInfo = NSMutableDictionary()
      userInfo.setValue(selectedUserDetails?.id, forKey: "userId")
      userInfo.setValue(selectedUserDetails?.name, forKey: "userName")
//
        if let code = self.selectedUserDetails?.gender , !code.trim.isEmpty {
          if code == "af" || code == "f" {
            userInfo.setValue("Female", forKey: "userGender")
          }
          else {
            userInfo.setValue("Male", forKey: "userGender")
          }
        }
        else {
          userInfo.setValue("Male", forKey: "userGender")
        }
        userInfo.setValue((self.selectedUserDetails?.height.ns.intValue)! > 0 ? String(format:"%.2f",(self.selectedUserDetails?.height.ns.floatValue)! / 100) : "1.6", forKey: "height")
      
      userInfo.setValue((self.selectedUserDetails?.weight.ns.intValue)! > 0 ? self.selectedUserDetails?.weight : "65", forKey: "weight")
      
//        userInfo.setValue("1.6", forKey: "height")
//        userInfo.setValue("65", forKey: "weight")
        userInfo.setValue("1", forKey: "athleteLevel")
//        userInfo.setValue("1989-09-01", forKey: "birthday")
      
        //NOT IN USE FOR PROJECT rn.
//        if let code = self.selectedUserDetails?.gender , !code.trim.isEmpty {
//          if code == "af" || code == "am" {
//            userInfo.setValue("1", forKey: "athleteLevel")
//          }
//          else {
//            userInfo.setValue("0", forKey: "athleteLevel")
//          }
//        }
//        else {
//          userInfo.setValue("1", forKey: "athleteLevel")
//        }
      
      // FIXME:- Add User Birthday
      if self.selectedUserDetails?.dob != nil && self.selectedUserDetails?.dob != "" {
        let df = DateFormatter()
        df.dateFormat = "dd-MMM-yyyy"
        df.setLocal()
        let date1 = df.date(from: (self.selectedUserDetails?.dob)!)
        df.dateFormat = "yyyy-MM-dd"
        let newDate = df.string(from: date1!)
        userInfo.setValue(newDate, forKey: "birthday")
      }
      else{
        userInfo.setValue("1989-09-01", forKey: "birthday")
      }
      
      let newlyUser = DeviceUser.createDeviceUser(userInfo: userInfo as! [AnyHashable : Any], in: self.lsDatabaseManager!.managedContext)
      
      let userProfiles = NSMutableDictionary()
      userProfiles.setValue(self.selectedUserDetails?.id, forKey: "userId")
      userProfiles.setValue("Kg", forKey: "weightUnit")
      userProfiles.setValue("70", forKey: "weightTarget")
      userProfiles.setValue("Sunday", forKey: "weekStart")
      userProfiles.setValue("24", forKey: "hourFormat")
      userProfiles.setValue("Kilometer", forKey: "distanceUnit")
      userProfiles.setValue("10000", forKey: "weekTargetSteps")
      userProfiles.setValue("1", forKey: "alarmClockId")
      userProfiles.setValue("1", forKey: "scanFilterId")
      
      newlyUser.userprofiles = DeviceUserProfiles.createUserProfiles(withInfo: userProfiles as! [AnyHashable : Any], in: self.lsDatabaseManager!.managedContext)
      
//      let alarmClock = NSMutableDictionary()
//      alarmClock.setValue("1", forKey: "alarmClockId")
//      alarmClock.setValue(Date(), forKey: "alarmClockTime")
//      alarmClock.setValue("127", forKey: "alarmClockDay")
//
//      let defaultValue = NSNumber(value: true)
//      alarmClock.setValue(defaultValue, forKey: "monday")
//      alarmClock.setValue(defaultValue, forKey: "tuesday")
//      alarmClock.setValue(defaultValue, forKey: "wednesday")
//      alarmClock.setValue(defaultValue, forKey: "thursday")
//      alarmClock.setValue(defaultValue, forKey: "friday")
//      alarmClock.setValue(defaultValue, forKey: "saturday")
//      alarmClock.setValue(defaultValue, forKey: "sunday")
//
//      newlyUser.userprofiles?.deviceAlarmClock = DeviceAlarmClock.createAlarmClock(withInfo: alarmClock as! [AnyHashable : Any], in: self.lsDatabaseManager!.managedContext)
      
      let scanFilterInfo = NSMutableDictionary()
      scanFilterInfo.setValue("1", forKey: "scanFilterId")
      scanFilterInfo.setValue("All", forKey: "broadcastType")
      
      let enable = NSNumber(value: true)
      scanFilterInfo.setValue(enable, forKey: "enableFatScale")
      
      newlyUser.userprofiles?.hasScanFilter = ScanFilter.createScanFilter(withInfo: scanFilterInfo as! [AnyHashable : Any], in: self.lsDatabaseManager!.managedContext)
      
      let productUserInfo = DataFormatConverter.getProductUserInfo(newlyUser)
      print("set product user info on pairing mode \(String(describing: productUserInfo))")
      
      self.lsCurrentDeviceUser = newlyUser
      //            WeightScaleCurrentDeviceUser.shared.saveCurrentDeviceUser(self.lsCurrentDeviceUser!)
      
      self.lsBleManager?.setProductUserInfo(productUserInfo)
//      lsCurrentDeviceUser = self.lsCurrentDeviceUser
      
      let userId = selectedUserDetails?.id
      BleDevice.bindDevice(withUserId: userId!, deviceInfo: lsDevice, in: self.lsDatabaseManager!.managedContext)
      
      self.lsBleManager?.addMeasureDevice(lsDevice)
      
      if lsDevice.deviceId != nil{
        self.setupProductUserInfoOnSyncMode(deviceID: lsDevice.deviceId!, userNumber: Int(lsDevice.deviceUserNumber))
      }
      
      self.currentConnectedBMIDevice = lsDevice

      //CONNECTING FOR SYNC
      self.lsDatabaseManager?.databaseDelegate = self
      self.lsBleManager?.connectDevice(self.currentConnectedBMIDevice!, connectDelegate: self)
      self.lsBleManager?.startDataReceiveService(self)
      
//      self.lsBleManager?.stopDataReceiveService()
//      appDelegate.window?.rootViewController?.dismiss(animated: true, completion: {})
      
    }
    else{
//      showAlert("Pairing failed")
      print("===> Pairing Failed <====")
    }
  }
  
  func setupProductUserInfoOnPairingMode(){
    let userInfo = DataFormatConverter.getProductUserInfo(self.lsCurrentDeviceUser)
    //print("set product user info on pairing mode \(String(describing: userInfo))")
    self.lsBleManager?.setProductUserInfo(userInfo)
  }
  
  func getProductUserInfo(deviceUser: DeviceUser) -> LSProductUserInfo{
    //print("device user info \(DataFormatConverter.parseObjectDetail(inDictionary: deviceUser))")
    if (deviceUser.birthday == nil) {
      //print("Birthday is nil.......")
    }
    
    let calendar = Calendar.init(identifier: .gregorian)
    var dateComponents = calendar.dateComponents([.hour, .minute, .year], from: deviceUser.birthday!)
    
    let year = dateComponents.year
    
    dateComponents = calendar.dateComponents([.hour, .minute, .year], from: Date())
    
    let currentYear = dateComponents.year
    
    let userInfo = LSProductUserInfo()
    userInfo.height = Float(deviceUser.height!.doubleValue)
    
    userInfo.goalWeight = Float(deviceUser.userprofiles!.weightTarget!.intValue)
    
    userInfo.age = UInt(currentYear! - year!)
    
    if deviceUser.gender == "Male" {
      userInfo.sex = SEX_MALE
    }
    else{
      userInfo.sex=SEX_FEMALE;
    }
    
    if deviceUser.userprofiles!.weightUnit == "Lb" {
      userInfo.unit = UNIT_LB
    }
    else if deviceUser.userprofiles!.weightUnit == "St" {
      userInfo.unit = UNIT_ST
    }
    else{
      userInfo.unit = UNIT_KG
    }
    
    userInfo.athleteLevel = UInt(deviceUser.athleteLevel!.intValue)
    return userInfo;
    
  }
  
  func setupCurrentDeviceUser() -> DeviceUser{
    if let currentUser = (self.lsDatabaseManager!.allObjectForEntity(forName: "DeviceUser", predicate: nil)).last as? DeviceUser{
      return currentUser
    }
    return DeviceUser()
    
  }
  //call LSBLEDeviceManager interface searchLsBleDevice...
  func searchBluetoothDevice() {
    //        [self.scanResultsArray removeAllObjects];
    //        [self.tableView reloadData];
    
    //you can change the device type which one or all you want to scan
    let enableScanDeviceTypes = self.getEnableScanDeviceTypes()
    self.lsBleManager?.searchLsBleDevice([enableScanDeviceTypes], of: BROADCAST_TYPE_ALL, searchCompletion: { (lsDevice) in
      
//        print("BMI Scanned deviceName==> \(lsDevice?.deviceName)")
//        print("BMI Scanned deviceId==> \(lsDevice?.deviceId)")
//        print("BMI Scanned deviceSn==> \(lsDevice?.deviceSn)")
//        print("BMI Scanned deviceType==> \(lsDevice?.deviceType.rawValue)")
//        print("BMI Scanned broadcastId==> \(lsDevice?.broadcastId)")
//        print("BMI Scanned modelNumber==> \(lsDevice?.modelNumber)")
//        print("BMI Scanned password==> \(lsDevice?.password)")
//        print("BMI Scanned protocolType==> \(lsDevice?.protocolType)")
//        print("BMI Scanned preparePair==> \(lsDevice?.preparePair)")
//        print("BMI Scanned supportDownloadInfoFeature==> \(lsDevice?.supportDownloadInfoFeature)")
//        print("BMI Scanned maxUserQuantity==> \(lsDevice?.maxUserQuantity)")
//        print("BMI Scanned systemId==> \(lsDevice?.systemId)")
//        print("BMI Scanned peripheralIdentifier==> \(lsDevice?.peripheralIdentifier)")
//        print("BMI Scanned deviceUserNumber==> \(lsDevice?.deviceUserNumber)")
//        print("BMI Scanned peripheral==> \(lsDevice?.lsCBPeripheral)")
      
        let peripheral = self.lsBleManager?.getLsPeripheral(withKey: lsDevice!.deviceName)
        
        //print("BMI Scanned peripheral 2==> \(peripheral)")
        
        
        if lsDevice != nil {
          var isDeviceAlreadyPaired = false
          if let pairedDevicesArray = self.getPairedDevicesList()?.filter({$0.broadcastID == lsDevice?.broadcastId }){
            if !pairedDevicesArray.isEmpty{
              isDeviceAlreadyPaired = true
            }
            else{
              isDeviceAlreadyPaired = false
            }
          }
          
          if isDeviceAlreadyPaired || lsDevice!.preparePair {
            if lsDevice!.deviceName.contains("1144B") || lsDevice!.deviceName.contains("SFBS1"){
              if !self.arrBLEList.contains(peripheral!) {
                if lsDevice!.deviceName.contains("1144B"){
                  self.macAddress.append("1144B")
                }
                else if lsDevice!.deviceName.contains("SFBS1"){
                  self.macAddress.append("SFBS1")
                }
                else{
                  self.macAddress.append("1144B")
                }
                
                self.arrLSBLEList.append(lsDevice)
                self.rnBmiDeviceList.append(self.mapDeviceDescription(lsDevice!, isDeviceAlreadyPaired: false))
              }
            }

            DispatchQueue.main.async {
                //MARK:- Refresh Table
              print("=========rnBmiDeviceList================")
              print(self.rnBmiDeviceList)
              print("==================================")
              print("=========arrLSBLEList================")
              print(self.arrLSBLEList)
              print("==================================")
              self.emitEvent(Self.DEVICE_FOUND_EVENT, withData: self.rnBmiDeviceList)
            }
          }
          
        }
//          self.delay(2, closure: {
//          //self.deviceTbl.reloadData()
//          print("=========arrBLEList============232323====")
//          print(self.arrBLEList)
//          print("===============================2323==")
//          print("=========arrLSBLEList===============232323=")
//          print(self.arrLSBLEList)
//          print("==============================3232===")
//          //MARK: - Refresh Table
//        })
      
    })
  }
  
  
  func getPairedDevicesList() -> [BleDevice]? {
    if let deviceArray = lsDatabaseManager?.allObjectForEntity(forName: "BleDevice", predicate: nil) as? [BleDevice]{
      return deviceArray
    }
    return nil
  }

}

extension MedcheckSdk: LSBleDataReceiveDelegate{
  func updateGattConnectStatus(broadcastId: String, connectState: DeviceConnectState){
    //        self.currentConnectedProtocol=deviceItem.protocolType;
    
    //        BleDevice *deviceItem=[self.pairedDeviceArray objectAtIndex:indexPath.row];
    
    
    if(connectState==CONNECTED_SUCCESS)
    {
      print("BMI connected")
    }
    else if(connectState==CONNECTED_FAILED)
    {
      print("BMI connection failed")
    }
    else
    {
      
    }
  }
  
  
  func bleManagerDidConnectStateChange(_ connectState: DeviceConnectState, deviceName: String!) {
    //print("UI device connect state change %d",connectState);
    self.updateGattConnectStatus(broadcastId: deviceName, connectState: connectState)
    self.dataMap.removeAllObjects()
    self.weightDataMap.removeAllObjects()
    self.fatDataList.removeAll()
    self.weightDataList.removeAll()
  }
  
  func bleManagerDidDiscoveredDeviceInfo(_ deviceInfo: LSDeviceInfo!) {
    if deviceInfo == nil {
      return
    }
    
    if deviceInfo.deviceType == LS_KITCHEN_SCALE || deviceInfo.protocolType == "GENERIC_FAT" || deviceInfo.protocolType == "A4" {
      NSLog("discovered device info %@",DataFormatConverter.parseObjectDetail(inDictionary: deviceInfo))
      //update the kitchen scale info and save
      BleDevice.bindDevice(withUserId: "10090", deviceInfo: deviceInfo, in: self.lsDatabaseManager!.managedContext)
    }
  }
  
  func bleManagerDidReceiveWeightData(withOperatingMode2 weightData: LSWeightData!) {
    print("bleManagerDidReceiveWeightData(withOperatingMode2) \(weightData)")
  }
  
  func bleManagerDidReceiveWeightMeasuredData(_ data: LSWeightData!) {
    guard let weightData = data else {
      return
    }
    self.currentWeightData = weightData
    
    self.weightDataList.append(data)
    //print("new weight: \(weightData.description)")
    
    if self.currentConnectedProtocol == "GENERIC_FAT" {
      var value = ""
      let weightValue = DataFormatConverter.doubleValue(withTwoDecimalFormat: data.weight)
      if weightData.deviceSelectedUnit == "LB"{
        value = String(format: "%f", data.lbWeightValue)
      }
      else{
        value = weightValue!
      }
      //print("weight \(value)")
      //            [self updateRecordNumber:data.broadcastId count:0 text:value unit:data.deviceSelectedUnit];
    }
    else{
      if weightDataList.count > 1{
        self.showWeightDataInTableList(deviceID: data.deviceId)
      }
      else{
        if weightData.hasAppendMeasurement == 1{
          
        }
        else{
          self.showWeightBMIPopUp(weightAppendData: nil)
        }
      }
      
      //            var tempWeightDatas = self.findMeasuredDataArrayWithBroadcastID(broadcastId: data.broadcastId)
      //            //print("tempWeightDatas \(DataFormatConverter.parseObjectDetail(inDictionary: tempWeightDatas))")
      //            tempWeightDatas?.append(data)
      //            self.dataMap.setValue(tempWeightDatas, forKey: data.broadcastId)
      //            //print("self.dataMap \(self.dataMap)")
      //            if data.hasAppendMeasurement == 0{
      //                self.getLatestReadingData(deviceID: data.deviceId)
      //            }
      
      
      
      
      
      //            [self updateRecordNumber:data.broadcastId count:tempWeightDatas.count text:nil unit:nil];
    }
  }
  
  func showWeightBMIPopUp(weightAppendData: LSWeightAppendData?){
    if let data = currentWeightData{
      
      var value = ""
      let weightValue = DataFormatConverter.doubleValue(withTwoDecimalFormat: data.weight)
      if data.deviceSelectedUnit == "LB"{
        value = String(format: "%f", data.lbWeightValue)
      }
      else{
        value = weightValue!
      }
      
      print("weight \(value)")

      var bmiValue = "NA"
      
      
      var basalMetabolism = ""
      var bmiExtraData = ""
      if weightAppendData != nil{
        let df = DateFormatter()
        df.dateFormat = "dd-MMM-yyyy"
        df.setLocal()
        
//        let date1 = df.date(from: selectedUserDetails?.dob ?? "1989-09-01")
        let date1 = df.date(from: "09-jan-1989")
        
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = calendar.dateComponents([.hour, .minute, .year], from: date1!)
        let year = dateComponents.year
        dateComponents = calendar.dateComponents([.hour, .minute, .year], from: Date())
        
        let currentYear = dateComponents.year
        let age = UInt(currentYear! - year!)
        
        
        
        //                basalMetabolism = LSFatParser.basalMetabolism(byMuscl: Double(weightAppendData!.muscleMassRatio), weight: data.weight, age: Int32(age), sex: UserInfo.savedUser()!.gender == "m" ? SEX_MALE : SEX_FEMALE)
        basalMetabolism = self.calculateBMR(weight: data.weight, height: 160.0, age: age)
        
        print("basalMetabolism \(basalMetabolism)")
        bmiExtraData.append("MuscleMassRatio: \(weightAppendData!.muscleMassRatio)")
        bmiExtraData.append("\nBodyFatRatio: \(weightAppendData!.bodyFatRatio)")
        bmiExtraData.append("\nBoneDensity: \(weightAppendData!.boneDensity)")
        bmiExtraData.append("\nBodywaterRatio: \(weightAppendData!.bodywaterRatio)")
        bmiExtraData.append("\nBMR: \(basalMetabolism)")
      }
//      if UserInfo.savedUser()?.height != "" && UserInfo.savedUser()!.height.ns.floatValue > 0{
      let height = (("160".ns.floatValue) / 100)
        let bmiCal = (Float(data.weight) / (height * height))
        bmiValue = String(format: "%.1f", bmiCal)
//      }
//      let readingdata = ["bleType" : "BMI","person":contactArray[0], "data" : ["kgWeightValue":  String(format:"%.1f",data.weight), "valueUnit" : data.deviceSelectedUnit ?? "", "date" : data.date ?? "", "lbWeightValue" : data.lbWeightValue, "stWeightValue" : data.stWeightValue, "bmiValue": bmiValue, "appendedData" : bmiExtraData]] as [String : Any]
      
      let familyID = "10090"
      
      let df = DateFormatter()
      df.dateFormat = "yyyy-MM-dd HH:mm:ss"
      df.setLocal()
      let date1 = df.date(from: data.date)
      df.dateFormat = "dd-MMM-yyyy HH:mm:ss"
      let newDate = df.string(from: date1!)
      
      let param = ["data" : [ "device_id" : "5",
                              "user_id": "10090",
                              "user_family_id":familyID,
                              "reading_time":newDate,
                              "is_manual":"0",
                              "reading_notes": "notes",
                              "device_data" :["bmi_weight":value,
                                              "bmi": bmiValue == "NA" ? "" : bmiValue,
                                              "fat_per":weightAppendData != nil ? DataFormatConverter.doubleValue(withTwoDecimalFormat: Double((weightAppendData?.bodyFatRatio)!)) : "",
                                              "muscle_per":weightAppendData != nil ? DataFormatConverter.doubleValue(withTwoDecimalFormat: Double((weightAppendData?.muscleMassRatio)!)) : "",
                                              "water_per":weightAppendData != nil ? DataFormatConverter.doubleValue(withTwoDecimalFormat: Double((weightAppendData?.bodywaterRatio)!)) : "",
                                              "bone_mass":weightAppendData != nil ? DataFormatConverter.doubleValue(withTwoDecimalFormat: Double((weightAppendData?.boneDensity)!)) : "",
                                              "bmr":weightAppendData != nil ? basalMetabolism : ""]
        ]]
      
      print("User BMI Data", param)
      self.emitEvent(Self.DATA_EVENT, withData: param)
    }
  }
  
  func calculateBMR(weight: Double, height: Double, age: UInt) -> String{
//    if UserInfo.savedUser()?.gender == "m"{
      let weightCal = 13.75 * weight
      let heightCal = 5.003 * height
      let ageCal = 6.755 * Double(age)
      let bmr = (66.47 + weightCal + heightCal) - ageCal
      return String(format: "%.0f", bmr)
//    }
//    else{
//      let weightCal = 9.563 * weight
//      let heightCal = 1.85 * height
//      let ageCal = 4.676 * Double(age)
//      let bmr = (655.1 + weightCal + heightCal) - ageCal
//      return String(format: "%.0f", bmr)
//    }
  }
  
  func showWeightDataInTableList(deviceID: String){
    arrNewlyFetchedResults.removeAll()
//    dismissPopUp()
    
    let fatScaleMeasuredData = self.getFatScaleMeasuredData(deviceId: deviceID)
    //print("fatScaleMeasuredAppendData \(fatScaleMeasuredData)")
    
    if fatScaleMeasuredData.count > 0{
      if let weightDatas = fatScaleMeasuredData.value(forKeyPath: String(format:"%@.WeightData",deviceID)) as? [LSWeightData]{
        //print("weightDatas \(weightDatas)")
        for weightData in weightDatas{
          
          if weightData.hasAppendMeasurement == 1{
            if let weightAppendDatas = fatScaleMeasuredData.value(forKeyPath: String(format:"%@.WeightAppendData",deviceID)) as? [LSWeightAppendData]{
              //print("weightAppendDatas \(weightAppendDatas)")
              for weightAppendData in weightAppendDatas{
                if weightData.date == weightAppendData.measuredTime{
                  
                  let data = ["WeightData" : weightData, "WeightAppendData" : weightAppendData]
                  arrNewlyFetchedResults.append(["deviceType":"WSCAL" as AnyObject,"data":data as AnyObject])
                  
                  let rnData = ["WeightData" : mapWeightData(weightData), "WeightAppendData": mapAppendWeightData(weightAppendData)]
                  rnMultiDataList.append(rnData)
                  
                }
              }
            }
          }
          else{
            let data = ["WeightData" : weightData]
            arrNewlyFetchedResults.append(["deviceType":"WSCAL" as AnyObject,"data":data as AnyObject])
            
            //FIXME:- //WeightData: null in RN
            let rnData = ["WeightData" : mapWeightData(weightData)]
            rnMultiDataList.append(["deviceType":"WSCAL" as AnyObject,"data":rnData])
            
          }
        }
      }
    }
//    print("BMI results: \(arrNewlyFetchedResults)")
    print("BMI results: \(rnMultiDataList)")
    self.emitEvent(Self.DATA_EVENT, withData: rnMultiDataList)
  }
  
  func getLatestReadingData(deviceID: String){
    let fatScaleMeasuredData = self.getFatScaleMeasuredData(deviceId: deviceID)
    //print("fatScaleMeasuredData \(fatScaleMeasuredData)")
    for (_, _) in fatScaleMeasuredData.enumerated(){
      //print("_measuredData \(measuredData)")
      
    }
    if let weightDatas = fatScaleMeasuredData.value(forKey: "WeightData") as? LSWeightData{
      //print("weightData array \(DataFormatConverter.parseObjectDetail(inDictionary: weightDatas))")
      if weightDatas.hasAppendMeasurement == 1{
        if (fatScaleMeasuredData.value(forKey: "WeightAppendData") as? LSWeightAppendData) != nil{
          //print("WeightAppendDatas \(DataFormatConverter.parseObjectDetail(inDictionary: weightAppendDatas))")
        }
      }
    }
  }
  
  func bleManagerDidReceiveWeightAppendMeasuredData(_ data: LSWeightAppendData!) {
    guard let weightData = data else {
      return
    }
    //print("bleManagerDidReceiveWeightAppendMeasuredData2 \(DataFormatConverter.parseObjectDetail(inDictionary: data))")
    self.fatDataList.append(weightData)
    //        self.getLatestReadingData(deviceID: data.deviceId)
    if self.fatDataList.count > 1 {
      self.showWeightDataInTableList(deviceID: data.deviceId)
      //            self.showWeightBMIPopUp(weightAppendData: self.fatDataList.last)
    }
    else{
      self.showWeightBMIPopUp(weightAppendData: data)
    }
  }
  
  func getFatScaleMeasuredData(deviceId: String) -> NSDictionary{
    let tempWeightData = NSMutableArray()
    let tempWeightAppendData = NSMutableArray()
    
    if self.weightDataList.count > 0 {
      for (_, weightData) in self.weightDataList.enumerated(){
        if weightData.deviceId == deviceId{
          tempWeightData.add(weightData)
        }
      }
      self.weightDataMap.setValue(tempWeightData, forKey: "WeightData")
    }
    if self.fatDataList.count > 0 {
      for (_, appendData) in self.fatDataList.enumerated(){
        if appendData.deviceId == deviceId{
          tempWeightAppendData.add(appendData)
        }
      }
      self.weightDataMap.setValue(tempWeightAppendData, forKey: "WeightAppendData")
    }
    if self.weightDataMap.count > 0 {
      self.dataMap.setValue(self.weightDataMap, forKey: deviceId)
    }
    return self.dataMap;
  }
  
  func findMeasuredDataArrayWithBroadcastID(broadcastId: String) -> [Any]?{
    if broadcastId.length > 0 {
      if let map = self.dataMap.value(forKey: broadcastId){
        return [map]
      }
      else{
        let tempDataMap = [Any]()
        self.dataMap.setValue(tempDataMap, forKey: broadcastId)
        return tempDataMap
      }
    }
    else{
      return nil
    }
  }
  
  func getCurrentMeasuredData(broadcastId: String) -> [Any]?{
    if(broadcastId.length > 0){
      return self.dataMap.value(forKey: broadcastId) as? [Any]
    }
    else{
      return nil
    }
  }
}

extension MedcheckSdk: LSDeviceConnectDelegate{
  func bleManagerDidWaiting(forStartMeasuring deviceId: String!) {
    //print("bleManagerDidWaiting")
  }
  func bleManagerDidReceiveBloodPressureMeasuredData(_ bpData: LSSphygmometerData!) {
    //print("bleManagerDidReceiveBloodPressureMeasuredData \(bpData)")
  }
  func bleManagerDidConnectStateChange(_ connectState: DeviceConnectState) {
    //print("bleManagerDidConnectStateChange \(connectState)")
  }
}


extension MedcheckSdk: DatabaseManagerDelegate{
  @objc func managedContextChanged(_ notification: Notification){
    //        if let userInfo = notification.userInfo{
    //            //print("insert value %@",userInfo[NSInsertedObjectsKey] ?? "No inserted data");
    //            //print("update value %@",userInfo[NSUpdatedObjectsKey] ?? "No update data");
    //            //print("delete value %@",userInfo[NSDeletedObjectsKey] ?? "No deleted data");
    //        }
  }
  
  func databaseManagerDidCreatedManagedObjectContext(_ managedObjectContext: NSManagedObjectContext!) {
    var userID = "10090"
    print("DMDCMOC", self.selectedUserDetails)
    if self.lsCurrentDeviceUser == nil{
      userID = selectedUserDetails?.id ?? "rnUser"
    }
    else{
      if let uID = self.lsCurrentDeviceUser!.userID, !uID.trim.isEmpty {
        userID = uID
      }
      else{
        userID = "rnUser"
      }
    }
    
    //        if self.lsCurrentDeviceUser == nil{
    //            userID = (UserInfo.savedUser()?.id)!
    //        }
    //        else{
    //            userID = (self.lsCurrentDeviceUser?.userID)!
    //        }
    let queryPredicate = NSPredicate.init(format: "userID = %@", userID)
    let deviceUser = self.lsDatabaseManager?.allObjectForEntity(forName: "DeviceUser", predicate: queryPredicate)
    
    if !(deviceUser?.isEmpty)! {
      self.lsCurrentDeviceUser = deviceUser!.last as? DeviceUser
      //print("my user info \(DataFormatConverter.parseObjectDetail(inDictionary: self.lsCurrentDeviceUser))")
    }
    else{
      //print("no device user and user profiles,create.......")
      let userInfo = NSMutableDictionary()
      userInfo.setValue("10090", forKey: "userId")
      userInfo.setValue("Ravi", forKey: "userName")
//      if let code = UserInfo.savedUser()?.gender , !code.trim.isEmpty {
//        if code == "af" || code == "f" {
//          userInfo.setValue("Female".localized, forKey: "userGender")
//        }
//        else {
//
//        }
//      }
//      else {
//        userInfo.setValue("Male".localized, forKey: "userGender")
//      }
      
      userInfo.setValue("Male", forKey: "userGender")
      userInfo.setValue("1.6", forKey: "height")
      userInfo.setValue("65", forKey: "weight")
      
//      if let code = UserInfo.savedUser()?.gender , !code.trim.isEmpty {
//        if code == "af" || code == "am" {
          userInfo.setValue("1", forKey: "athleteLevel")
//        }
//        else {
//          userInfo.setValue("0", forKey: "athleteLevel")
//        }
//      }
//      else {
//        userInfo.setValue("0", forKey: "athleteLevel")
//      }
      
      
//      if UserInfo.savedUser()?.dob != nil{
//        let df = DateFormatter()
//        df.dateFormat = "dd-MMM-yyyy"
//        df.setLocal()
//        let date1 = df.date(from: (UserInfo.savedUser()?.dob)!)
//        df.dateFormat = "yyyy-MM-dd"
//        let newDate = df.string(from: date1!)
//        userInfo.setValue(newDate, forKey: "birthday")
//      }
//      else{
        userInfo.setValue("1989-09-01", forKey: "birthday")
//      }
      
      self.lsCurrentDeviceUser = DeviceUser.createDeviceUser(userInfo: userInfo as! [AnyHashable : Any], in: managedObjectContext)
      
      
      let userProfiles = NSMutableDictionary()
//      userProfiles.setValue(UserInfo.savedUser()?.id, forKey: "userId")
      userProfiles.setValue("10090", forKey: "userId")
      userProfiles.setValue("Kg", forKey: "weightUnit")
      userProfiles.setValue("70", forKey: "weightTarget")
      userProfiles.setValue("Sunday", forKey: "weekStart")
      userProfiles.setValue("24", forKey: "hourFormat")
      userProfiles.setValue("Kilometer", forKey: "distanceUnit")
      userProfiles.setValue("10000", forKey: "weekTargetSteps")
      userProfiles.setValue("1", forKey: "alarmClockId")
      userProfiles.setValue("1", forKey: "scanFilterId")
      
      DeviceUserProfiles.createUserProfiles(withInfo: userProfiles as! [AnyHashable : Any], in: managedObjectContext)
      
      
      let alarmClock = NSMutableDictionary()
      alarmClock.setValue("1", forKey: "alarmClockId")
      alarmClock.setValue(Date(), forKey: "alarmClockTime")
      alarmClock.setValue("127", forKey: "alarmClockDay")
      
      let defaultValue = NSNumber(value: true)
      alarmClock.setValue(defaultValue, forKey: "monday")
      alarmClock.setValue(defaultValue, forKey: "tuesday")
      alarmClock.setValue(defaultValue, forKey: "wednesday")
      alarmClock.setValue(defaultValue, forKey: "thursday")
      alarmClock.setValue(defaultValue, forKey: "friday")
      alarmClock.setValue(defaultValue, forKey: "saturday")
      alarmClock.setValue(defaultValue, forKey: "sunday")
      
      DeviceAlarmClock.createAlarmClock(withInfo: alarmClock as! [AnyHashable : Any], in: managedObjectContext)
      
      let scanFilterInfo = NSMutableDictionary()
      scanFilterInfo.setValue("1", forKey: "scanFilterId")
      scanFilterInfo.setValue("All", forKey: "broadcastType")
      
      let enable = NSNumber(value: true)
      scanFilterInfo.setValue(enable, forKey: "enableFatScale")
      
      ScanFilter.createScanFilter(withInfo: scanFilterInfo as! [AnyHashable : Any], in: managedObjectContext)
    }
    
    self.loadDataFromDatabase()
  }
  
  func loadDataFromDatabase(){
    if let deviceArray = self.lsDatabaseManager?.allObjectForEntity(forName: "BleDevice", predicate: nil) as? [BleDevice]{
      //print(deviceArray)
      for (_, device) in deviceArray.enumerated(){
        
        //print("get device info from database %@",(device as AnyObject).description)
        //                [self.pairedDeviceArray addObject:device];
        self.lsBleManager?.addMeasureDevice(DataFormatConverter.converted(toLSDeviceInfo: device ))
        if device.deviceID != nil{
          self.setupProductUserInfoOnSyncMode(deviceID: device.deviceID!, userNumber: (device.deviceUserNumber?.intValue)!)
        }
        
      }
    }
  }
  
//  func setupProductUserInfoOnSyncMode(deviceID: String, userNumber: Int)
//  func showDeviceInfoInAlertView(device: LSDeviceInfo, title: String)
}
