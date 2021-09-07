import Foundation
import CoreBluetooth
import QuartzCore
import CoreData
import UIKit

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
    
  let DEVICE_BLOOD_PRESSURE = 1
  let DEVICE_BLOOD_GLUCOSE = 2
  let DEVICE_BODY_MASS_INDEX = 3
  
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
    
    // 2021
    var bluetoothManager : BPMDataManager?
    var currentDeviceType = 1
    var newReadingStart = false
    var nearbyPeripheralInfos : [CBPeripheral:Dictionary<String, AnyObject>] = [CBPeripheral:Dictionary<String, AnyObject>]()
    var userSelectedBleDevice : CBPeripheral?
  
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
    
    private func mapDeviceDescriptionBGM(_ peripheral: CBPeripheral, isDeviceAlreadyPaired: Bool) -> [String: Any] {
        
      return [
        "id": peripheral.identifier.uuidString,
        "deviceId": peripheral.identifier.uuidString,
        "deviceSn": "",
        "deviceType": "",
        "modelNumber": "",
        "peripheralIdentifier": peripheral.identifier.uuidString,
        "deviceName": peripheral.name,
        "state": peripheral.state.rawValue,
        
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
      
        let id = userDetails["id"]
        let name = userDetails["first_name"]
        let dob = userDetails["dob"]
        let weight = userDetails["weight"]
        let height = userDetails["height"]
        let gender = userDetails["gender"]
        let getDeviceType = "\(userDetails["deviceType"] ?? "")"
        
        print("getDeviceType", getDeviceType)
        
        if (getDeviceType == "1") {
          currentDeviceType = DEVICE_BLOOD_PRESSURE
        } else if (getDeviceType == "2") {
          currentDeviceType = DEVICE_BLOOD_GLUCOSE
        } else if (getDeviceType == "3") {
          currentDeviceType = DEVICE_BODY_MASS_INDEX
        }
                
        if (currentDeviceType == DEVICE_BLOOD_GLUCOSE || currentDeviceType == DEVICE_BLOOD_PRESSURE) {
            self.bluetoothManager?.arrBLEList.removeAll()
            self.bluetoothManager?.macAddress.removeAll()
            self.bluetoothManager?.nearbyPeripheralInfos.removeAll()
            
            if self.bluetoothManager?.connectedPeripheral != nil {
//                self.bluetoothManager.disconnectPeripheral()
                if !(self.bluetoothManager?.arrBLEList.contains((self.bluetoothManager?.connectedPeripheral!)!))! {
                    if let address = UserDefaults.standard.value(forKey: "lastConnectedMACAddress") as? String {
                        self.bluetoothManager?.arrBLEList.append((self.bluetoothManager?.connectedPeripheral!)!)
                        if !(self.bluetoothManager?.macAddress.contains(address))! {
                            self.bluetoothManager?.macAddress.append(address)
                        }
                    }
                }
            }
        }
      
      selectedUserDetails = ContactDetail(id: "\(id ?? "unknown")", user_id: "\(id ?? "unknown")", name: "\(name ?? "unknown")", dob: "\(dob ?? "1998-01-01")", weight: "\(weight ?? "70")", height: "\(height ?? "6")", is_diabetics: "", waist: "", gender: "\(gender ?? "m")")
      
      
        if (currentDeviceType == DEVICE_BODY_MASS_INDEX) {
            self.lsDatabaseManager = LSDatabaseManager.default()
            self.lsDatabaseManager?.databaseDelegate = self
            self.lsDatabaseManager?.createManagedObjectContext(withDocumentName: "LifesenseBleDatabase")
        }
        
        if(lsBleManager!.isBluetoothPowerOn) {
          print("BLUETOOTH ON")
          status = true
        } else {
          status = false
          print("BLUETOOTH OFF")
        }

      
      try ObjC.catchException {
        if (self.currentDeviceType == self.DEVICE_BODY_MASS_INDEX) {
            self.loadDataFromDatabase()
        }
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
        if (self.currentDeviceType == self.DEVICE_BODY_MASS_INDEX) {
            self.searchBluetoothDevice()
        }
        
        if (self.currentDeviceType == self.DEVICE_BLOOD_PRESSURE || self.currentDeviceType == self.DEVICE_BLOOD_GLUCOSE) {
            self.bluetoothManager = BPMDataManager.sharedInstance
            self.bluetoothManager?.delegate = self
            self.bluetoothManager?.didUpdateManager()
        }
      }
      resolve([ "message": SCAN_BEGAN ])
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func disconnectFromDevice(_ uuid: String,
                                  resolver resolve: RCTPromiseResolveBlock,
                                  rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        if (self.currentDeviceType == self.DEVICE_BLOOD_PRESSURE || self.currentDeviceType == self.DEVICE_BLOOD_GLUCOSE) {
            self.bluetoothManager?.bluetoothManager.connectPeripheral(self.userSelectedBleDevice!)
            if self.userSelectedBleDevice != nil {
                self.bluetoothManager?.didDisconnectPeripheral(self.userSelectedBleDevice!)
            }
        }
      }
      resolve(nil)
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
  
  @objc func startCollection(_ resolve: RCTPromiseResolveBlock,
                             rejecter reject: RCTPromiseRejectBlock) {
    do {
      
      try ObjC.catchException {
        if (self.currentDeviceType == self.DEVICE_BLOOD_PRESSURE || self.currentDeviceType == self.DEVICE_BLOOD_GLUCOSE) {
            if self.userSelectedBleDevice != nil {
                self.bluetoothManager?.bluetoothManager.connectPeripheral(self.userSelectedBleDevice!)
            }
        }
      }
      resolve(nil)
    } catch {
      reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
    }
  }
    
    @objc func clearCollection(_ resolve: RCTPromiseResolveBlock,
                               rejecter reject: RCTPromiseRejectBlock) {
      do {
        
        try ObjC.catchException {
          if (self.currentDeviceType == self.DEVICE_BLOOD_PRESSURE || self.currentDeviceType == self.DEVICE_BLOOD_GLUCOSE) {
              self.bluetoothManager?.clearBPMDataCommand()
          }
        }
        resolve(nil)
      } catch {
        reject(Self.UNKNOWN_ERROR, Self.UNKOWN_ERROR_MSG, error)
      }
    }
    
    @objc func timeSyncBPMDevice(_ resolve: RCTPromiseResolveBlock,
                               rejecter reject: RCTPromiseRejectBlock) {
      do {
        
        try ObjC.catchException {
          if (self.currentDeviceType == self.DEVICE_BLOOD_PRESSURE) {
            self.bluetoothManager?.timeSyncOfBPM()
          }
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
        
        if (self.currentDeviceType == self.DEVICE_BODY_MASS_INDEX) {
            let peripheral = self.arrLSBLEList.filter({ (item) -> Bool in
              return item?.deviceName.description.contains(uuid ) ?? false
            })
            
            if(peripheral.count > 0 && peripheral[0] != nil) {
              let peripheral = peripheral[0]
              
              if ((peripheral?.deviceName?.contains("1144B"))! || (peripheral?.deviceName?.contains("SFBS1"))!){
                
                self.lsBleManager?.stopSearch()
                let tempItem = self.arrLSBLEList[0]
                
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
        } else {
            let peripheral = self.bluetoothManager?.arrBLEList.filter({ (item) -> Bool in
                return item.name?.description.contains(uuid ) ?? false
            })
            
            if(peripheral?.count ?? 0 > 0 && peripheral?[0] != nil) {
                let peripheral = peripheral?[0]
                self.userSelectedBleDevice = peripheral
                self.bluetoothManager?.bluetoothManager.stopScanPeripheral()
                self.bluetoothManager?.bluetoothManager.connectPeripheral(peripheral!)
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
        userID = "10090"
        let queryPredicate = NSPredicate.init(format: "userID = %@", userID)
        if let deviceUser = (self.lsDatabaseManager!.allObjectForEntity(forName: "DeviceUser", predicate: queryPredicate)).last as? DeviceUser{
          
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
      }
      
        var userName = "Unknown"
      
    }
  }
  
  func bleManagerDidPairedResults(_ lsDevice: LSDeviceInfo!, pairStatus: Int32) {
    
    if pairStatus == 1 {
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
      
        userInfo.setValue("1", forKey: "athleteLevel")
      
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
      
      let scanFilterInfo = NSMutableDictionary()
      scanFilterInfo.setValue("1", forKey: "scanFilterId")
      scanFilterInfo.setValue("All", forKey: "broadcastType")
      
      let enable = NSNumber(value: true)
      scanFilterInfo.setValue(enable, forKey: "enableFatScale")
      
      newlyUser.userprofiles?.hasScanFilter = ScanFilter.createScanFilter(withInfo: scanFilterInfo as! [AnyHashable : Any], in: self.lsDatabaseManager!.managedContext)
      
      let productUserInfo = DataFormatConverter.getProductUserInfo(newlyUser)
      print("set product user info on pairing mode \(String(describing: productUserInfo))")
      
      self.lsCurrentDeviceUser = newlyUser
      
      self.lsBleManager?.setProductUserInfo(productUserInfo)
      
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
      
    } else {
      print("===> Pairing Failed <====")
    }
  }
  
  func setupProductUserInfoOnPairingMode(){
    let userInfo = DataFormatConverter.getProductUserInfo(self.lsCurrentDeviceUser)
    self.lsBleManager?.setProductUserInfo(userInfo)
  }
  
  func getProductUserInfo(deviceUser: DeviceUser) -> LSProductUserInfo{
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
    let enableScanDeviceTypes = self.getEnableScanDeviceTypes()
    self.lsBleManager?.searchLsBleDevice([enableScanDeviceTypes], of: BROADCAST_TYPE_ALL, searchCompletion: { (lsDevice) in
      
        let peripheral = self.lsBleManager?.getLsPeripheral(withKey: lsDevice!.deviceName)
        
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
              self.emitEvent(Self.DEVICE_FOUND_EVENT, withData: self.rnBmiDeviceList)
            }
          }
          
        }
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
//    print("bleManagerDidReceiveWeightData(withOperatingMode2) \(weightData)")
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
      
      var bmiValue = "NA"
      
      
      var basalMetabolism = ""
      var bmiExtraData = ""
      if weightAppendData != nil{
        let df = DateFormatter()
        df.dateFormat = "dd-MMM-yyyy"
        df.setLocal()

        let date1 = df.date(from: "09-jan-1989")
        
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = calendar.dateComponents([.hour, .minute, .year], from: date1!)
        let year = dateComponents.year
        dateComponents = calendar.dateComponents([.hour, .minute, .year], from: Date())
        
        let currentYear = dateComponents.year
        let age = UInt(currentYear! - year!)
        
        basalMetabolism = self.calculateBMR(weight: data.weight, height: 160.0, age: age)
        
        bmiExtraData.append("MuscleMassRatio: \(weightAppendData!.muscleMassRatio)")
        bmiExtraData.append("\nBodyFatRatio: \(weightAppendData!.bodyFatRatio)")
        bmiExtraData.append("\nBoneDensity: \(weightAppendData!.boneDensity)")
        bmiExtraData.append("\nBodywaterRatio: \(weightAppendData!.bodywaterRatio)")
        bmiExtraData.append("\nBMR: \(basalMetabolism)")
      }

        let height = (("160".ns.floatValue) / 100)
        let bmiCal = (Float(data.weight) / (height * height))
        bmiValue = String(format: "%.1f", bmiCal)
      
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
      
      self.emitEvent(Self.DATA_EVENT, withData: param)
    }
  }
  
  func calculateBMR(weight: Double, height: Double, age: UInt) -> String{
      let weightCal = 13.75 * weight
      let heightCal = 5.003 * height
      let ageCal = 6.755 * Double(age)
      let bmr = (66.47 + weightCal + heightCal) - ageCal
      return String(format: "%.0f", bmr)
  }
  
  func showWeightDataInTableList(deviceID: String){
    arrNewlyFetchedResults.removeAll()
    
    let fatScaleMeasuredData = self.getFatScaleMeasuredData(deviceId: deviceID)

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

//    print("BMI results: \(rnMultiDataList)")
    self.emitEvent(Self.DATA_EVENT, withData: rnMultiDataList)
  }
  
  func getLatestReadingData(deviceID: String){
    let fatScaleMeasuredData = self.getFatScaleMeasuredData(deviceId: deviceID)
    for (_, _) in fatScaleMeasuredData.enumerated(){
      //print("_measuredData \(measuredData)")
    }
    if let weightDatas = fatScaleMeasuredData.value(forKey: "WeightData") as? LSWeightData{
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

    self.fatDataList.append(weightData)
    //        self.getLatestReadingData(deviceID: data.deviceId)
    if self.fatDataList.count > 1 {
      self.showWeightDataInTableList(deviceID: data.deviceId)
    } else {
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

    let queryPredicate = NSPredicate.init(format: "userID = %@", userID)
    let deviceUser = self.lsDatabaseManager?.allObjectForEntity(forName: "DeviceUser", predicate: queryPredicate)
    
    if !(deviceUser?.isEmpty)! {
      self.lsCurrentDeviceUser = deviceUser!.last as? DeviceUser
    } else {
      let userInfo = NSMutableDictionary()
      userInfo.setValue("10090", forKey: "userId")
      userInfo.setValue("Ravi", forKey: "userName")
      userInfo.setValue("Male", forKey: "userGender")
      userInfo.setValue("1.6", forKey: "height")
      userInfo.setValue("65", forKey: "weight")
      userInfo.setValue("1", forKey: "athleteLevel")
      userInfo.setValue("1989-09-01", forKey: "birthday")
      
      self.lsCurrentDeviceUser = DeviceUser.createDeviceUser(userInfo: userInfo as! [AnyHashable : Any], in: managedObjectContext)
      
      
      let userProfiles = NSMutableDictionary()
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
        self.lsBleManager?.addMeasureDevice(DataFormatConverter.converted(toLSDeviceInfo: device ))
        if device.deviceID != nil{
          self.setupProductUserInfoOnSyncMode(deviceID: device.deviceID!, userNumber: (device.deviceUserNumber?.intValue)!)
        }
        
      }
    }
  }
    
    func noBloothAlert(_ title : String, message : String) {
        print("==============================================")
        print("||")
        print("title:", title)
        print("message:", message)
        print("||")
        print("==============================================")
    }
}

extension MedcheckSdk: BPMDataManagerDelegate {
    func medcheckBLEDetected(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        noBloothAlert("FOUND LIST", message: (bluetoothManager?.arrBLEList.description)!)
        //Throws event every second
        self.rnBmiDeviceList.removeAll()
        if let listDevice = bluetoothManager?.arrBLEList {
            for device in listDevice {
                self.rnBmiDeviceList.append(self.mapDeviceDescriptionBGM(device, isDeviceAlreadyPaired: false))
            }
            DispatchQueue.main.async {
              self.emitEvent(Self.DEVICE_FOUND_EVENT, withData: self.rnBmiDeviceList)
            }
            
        }
    }
    
    func didMedCheckConnected(_ connectedPeripheral: CBPeripheral) {
//        print("didMedCheckConnected MedcheckSDK \(connectedPeripheral)")
        self.emitEvent(Self.DEVICE_CONNECTED_EVENT, withData: self.mapDeviceDescriptionBGM(connectedPeripheral, isDeviceAlreadyPaired: true))
    }
    
    func connectedUserData(_ connectedUser: [String : Any]) {
//        print("connectedUserData \(connectedUser)")
    }
    func willTakeNewReading(_ BLEName: CBPeripheral) {
//        print("willStartDataReading \(BLEName)")
    }
    
    func didSyncTime() {
//        print("didSyncTime")
    }
    
    func didTakeNewReading(_ readingData: [String : Any]) {
        if "\(readingData["device"])" == "Blood Pressure" {
            let message = "Systolic: \(readingData["Systolic"]!) \nDiastolic: \(readingData["Diastolic"]!) \nPulse: \(readingData["Pulse"]!) \nIBH: \(readingData["Indicator"]!) \nDate: \(readingData["Date"]!)"
            noBloothAlert("New Reading Blood Pressure", message: message)
        }
        else if "\(readingData["device"])" == "Glucose" {
            let message = "mg/dL: \(readingData["high_blood"]!) \nMeal: \(readingData["Indicator"]!) \nDate: \(readingData["Date"]!)"
//            noBloothAlert("New Reading Glucose", message: message)
        }
    }
    
    func fetchAllDataFromMedCheck(_ readingData: [Any]) {
        self.emitEvent(Self.DATA_EVENT, withData: jsonStringConvert(readingData))
    }
    
    func didClearedData() {
        print("didClearedData")
    }
    
    func willStartDataReading() {
        print("willStartDataReading")
    }
    
    func didEndDataReading() {
        print("didEndDataReading")
    }
    
    func jsonStringConvert(_ obj : Any) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: obj, options: JSONSerialization.WritingOptions.prettyPrinted)
            return  String(data: jsonData, encoding: String.Encoding.utf8)! as String
            
        } catch {
            return ""
        }
    }
}
