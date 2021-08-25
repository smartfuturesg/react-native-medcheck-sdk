package com.reactnativemedchecksdk

import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Promise

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.DialogInterface
import android.content.Intent
import android.content.IntentSender
import android.os.Bundle
import android.os.Handler

import androidx.annotation.NonNull
//import android.support.v7.app.AppCompatActivity
import androidx.appcompat.app.AppCompatActivity

import com.getmedcheck.lib.constant.Constants
import com.getmedcheck.lib.listener.MedCheckCallback
import com.getmedcheck.lib.listener.OnDialogClickListener
import com.getmedcheck.lib.model.BleDevice
import com.getmedcheck.lib.model.BloodGlucoseData
import com.getmedcheck.lib.model.BloodGlucoseDataJSON
import com.getmedcheck.lib.model.BloodPressureData
import com.getmedcheck.lib.model.BloodPressureDataJSON
import com.getmedcheck.lib.model.IDeviceData
import com.getmedcheck.lib.utils.PermissionHelper

//import com.google.android.gms.common.api.ApiException
//import com.google.android.gms.common.api.CommonStatusCodes
//import com.google.android.gms.common.api.ResolvableApiException
//import com.google.android.gms.location.LocationRequest
//import com.google.android.gms.location.LocationServices
//import com.google.android.gms.location.LocationSettingsRequest
//import com.google.android.gms.location.LocationSettingsResponse
//import com.google.android.gms.location.LocationSettingsStatusCodes
//import com.google.android.gms.location.SettingsClient
//import com.google.android.gms.tasks.OnFailureListener
//import com.google.android.gms.tasks.OnSuccessListener
//import com.google.android.gms.tasks.Task
import com.google.gson.Gson

import android.text.TextUtils
import android.util.Log
import android.widget.Toast
import com.facebook.react.bridge.*
import com.facebook.react.bridge.UiThreadUtil.runOnUiThread
import com.facebook.react.modules.core.DeviceEventManagerModule
import com.getmedcheck.lib.MedCheck
import com.lifesense.ble.LsBleManager
import com.lifesense.ble.PairCallback
import com.lifesense.ble.ReceiveDataCallback
import com.lifesense.ble.SearchCallback
import com.lifesense.ble.bean.*
import com.lifesense.ble.commom.BroadcastType
import com.lifesense.ble.commom.DeviceType

import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList

import com.facebook.react.bridge.*
import com.facebook.react.bridge.UiThreadUtil.runOnUiThread
import com.lifesense.ble.bean.*
import com.reactnativemedchecksdk.*
import java.util.*

class MedcheckSdkModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

  private var reactContext: ReactApplicationContext = reactContext

  private var myDeviceList: List<LsDeviceInfo>? = null
  private var mlsBleManager: LsBleManager? = null
  //    private lateinit var mDeviceListItems: List<PairedDeviceListItem>
  private var mDeviceListItems: MutableList<PairedDeviceListItem>? = null
  private var mBroadcastType: BroadcastType? = null
  private var mScanDeviceType: MutableList<DeviceType>? = null
  private var tempList: ArrayList<LsDeviceInfo>? = null
  val rnDeviceList: MutableList<Any> = java.util.ArrayList()
  val rnDeviceUserList: MutableList<Any> = java.util.ArrayList()
  private var mDeviceUserList: List<DeviceUserInfo>? = null
  private var userData: FamilyUser? = null
  private val wDataList_A3: MutableList<WeightData_A3> = ArrayList()
//    val mDeviceList: MutableList<BluetoothDevice> = java.util.ArrayList()

  private val CELL_DEFAULT_HEIGHT = 200
  val DEVICE_BLOOD_PRESSURE = 1
  val DEVICE_BLOOD_GLUCOSE = 2
  val DEVICE_BODY_MASS_INDEX = 3
  val DEVICE_HEART_ECG = 4
  val DEVICE_BLOOD_SPO2 = 5
  val DEVICE_BODY_TEMPERATURE = 6

  private val currentDeviceType = 3

  var dX = 0f
  var dY = 0f
  var lastAction = 0

  private var hasScanResults = false
  private var scanResultTimer: Timer? = null

  companion object {
    const val MODULE_NAME = "MedcheckSdk"

    const val INIT_ERROR = "INIT_ERROR"
    const val PAIR_ERROR = "PAIR_ERROR"
    const val UNKNOWN_ERROR = "UNKNOWN_ERROR"

    const val DATA_EVENT = "data"
    const val DEVICE_FOUND_EVENT = "deviceFound"
    const val DEVICE_CONNECTED_EVENT = "deviceConnected"
    const val DEVICE_DISCONNECTED_EVENT = "deviceDisconnected"
    const val AMBIGUOUS_DEVICE_FOUND_EVENT = "ambiguousDeviceFound"
    const val SCAN_FINISHED_EVENT = "scanFinished"
    const val COLLECTION_FINISHED_EVENT = "collectionFinished"
    const val USER_LIST_FOUND_EVENT = "userListFound"
  }

    override fun getName(): String {
        return MODULE_NAME
    }

    // Example method
    // See https://reactnative.dev/docs/native-modules-android
    @ReactMethod
    fun multiply(a: Int, b: Int, promise: Promise) {

      promise.resolve(a * b)

    }


  override fun getConstants() = mapOf(
    "EVENTS" to listOf(
      DATA_EVENT, DEVICE_FOUND_EVENT, DEVICE_CONNECTED_EVENT,
      DEVICE_DISCONNECTED_EVENT, AMBIGUOUS_DEVICE_FOUND_EVENT,
      SCAN_FINISHED_EVENT, COLLECTION_FINISHED_EVENT, USER_LIST_FOUND_EVENT
    )
  )

  private val eventEmitter by lazy {
    reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
  }

  private fun showToast(message: String) {
    reactContext.currentActivity?.runOnUiThread(Runnable {
      Toast.makeText(reactApplicationContext, message, Toast.LENGTH_SHORT).show()
    })
  }

  private fun logData(data:Any){
    Log.d(MODULE_NAME, "======> ********************* <======")
    Log.d(MODULE_NAME, "======> " + data + "          <======")
    Log.d(MODULE_NAME, "======> ********************* <======")
  }

  private fun emitEvent(eventName: String, params: Any?) {
    Log.i(MODULE_NAME, "Send '$eventName' event.")
    eventEmitter.emit(eventName, params)
  }

  private fun mapDeviceDescription(device: LsDeviceInfo, state: Boolean): WritableMap =
    Arguments.makeNativeMap(mapOf(
      "id" to device.broadcastID,
      "deviceId" to device.deviceId,
      "deviceSn" to device.deviceSn,
      "deviceType" to device.deviceType,
      "modelNumber" to device.modelNumber,
      "peripheralIdentifier" to device.macAddress,
      "deviceName" to device.deviceName,
      "state" to state
    ))

  private fun mapUser(key: Int, value:String): WritableMap =
    Arguments.makeNativeMap(mapOf(
      "key" to key,
      "value" to value
    ))

  private fun mapWeightData( wData: ModelBmiData, rawData: WeightData_A3): WritableMap =
    Arguments.makeNativeMap(mapOf(


      "_dateTime" to wData.dateTime.toString(),
      "_assignedUserId" to wData.assignedUserId.toString(),
      "_bmi" to wData.bmi.toString(),
      "_bmiWeight" to wData.bmiWeight.toString(),
      "_bmr" to wData.bmr.toString(),
      "_boneMass" to wData.boneMass.toString(),
      "_fatPer" to wData.fatPer.toString(),
      "_id" to wData.id.toString(),
      "_musclePer" to wData.musclePer.toString(),
      "_readingNotes" to wData.readingNotes.toString(),
      "_userId" to wData.userId.toString(),
      "_waterPer" to wData.waterPer.toString(),

      "batteryValue" to rawData.battery.toString(),
      "broadcastId" to rawData.broadcastId.toString(),
      "date" to wData.dateTime.toString(),
      "deviceId" to rawData.deviceId.toString(),
      "deviceSelectedUnit" to rawData.deviceSelectedUnit.toString(),
      "hasAppendMeasurement" to rawData.isAppendMeasurement.toString(),
      "lbWeightValue" to rawData.lbWeightValue.toString(),
      "pbf" to rawData.bodyFatRatio.toString(),
      "resistance_1" to "",
      "resistance_2" to "",
      "stSectionValue" to rawData.stSectionValue.toString(),
      "stWeightValue" to rawData.stWeightValue.toString(),
      "userNo" to rawData.userId.toString(),
      "utc" to rawData.utc.toString(),
      "voltageValue" to "",
      "weight" to wData.bmiWeight.toString()
    ))

  private fun mapInitDescription(init: Boolean): WritableMap =
    Arguments.makeNativeMap(mapOf(
      "status" to init
    ))

  private fun mapMessageStats(message: String): WritableMap =
    Arguments.makeNativeMap(mapOf(
      "message" to message
    ))

  private fun getBMIReadingList(wDataList_a3: List<WeightData_A3>?): MutableList<Any> {
//        val modelBmiData = ArrayList<ModelBmiData>()
    val rnMultiDataList: MutableList<Any> = ArrayList()

    wDataList_a3?.forEachIndexed { index, weightdataA3 ->
      println("$weightdataA3 at $index")
      try {
//                modelBmiData.add(getModelBmiDataFromReading(weightdataA3))
        rnMultiDataList.add(mapWeightData(getModelBmiDataFromReading(weightdataA3), weightdataA3))
      } catch (e: java.lang.Exception) {
        e.printStackTrace()
      }
    }

//        if (wDataList_a3 != null && wDataList_a3.size > 0) { //            for (Iterator<String> iterator = list.iterator(); iterator.hasNext(); ) {
////                String value = iterator.next();
////                if (value.length() > 5) {
////                    iterator.remove();
////                }
////            }
//            val weightData_a3 = wDataList_a3.iterator()
//            while (weightData_a3.hasNext()) {
//                //            for (WeightData_A3 weightData_a3 : wDataList_a3) {
//                try {
//                    modelBmiData.add(getModelBmiDataFromReading(weightData_a3))
//                } catch (e: java.lang.Exception) {
////                    e.printStackTrace()
//                }
//            }
//        }
//        return modelBmiData
    Log.d(MODULE_NAME, "RN DATA LIST${rnMultiDataList}")
    return rnMultiDataList
  }

  private fun showMeasuredReadingsDetailsInList(wDataList_a3: List<WeightData_A3>) { // get all unassigned bpm reading from database
    val newReadingData: MutableList<Any> = getBMIReadingList(wDataList_a3)
    val readings = Arguments.makeNativeArray(newReadingData)
    emitEvent(DATA_EVENT, readings)
    //TODO: Sending and printing the data gives crash
//        Log.d(MODULE_NAME, "MULTI NEW READING IN OBJECT ${newReadingData}")
  }


  private fun getModelBmiDataFromReading(objectData: Any): ModelBmiData {
    val wData = objectData as WeightData_A3
    var boneMass = 0f
    var waterPer = 0f
    var musclePer = 0f
    var fatPer = 0f
    val modelBmiData = ModelBmiData()
    modelBmiData.setBmiWeight(String.format("%1$.2f", 0f))
    modelBmiData.setBmi(String.format("%1$.2f", 0f))
    modelBmiData.setBoneMass(String.format("%1$.2f", boneMass))
    modelBmiData.setFatPer(String.format("%1$.2f", fatPer))
    modelBmiData.setWaterPer(String.format("%1$.2f", waterPer))
    modelBmiData.setMusclePer(String.format("%1$.2f", musclePer))
    modelBmiData.setBmr(String.format("%1$.2f", 0f))
    modelBmiData.setDateTime(DateTimeUtils.getTimeFromStringDate("yyyy-MM-dd HH:mm:ss", wData.date))
    try {
      val userWeight = wData.weight
      boneMass = wData.boneDensity
      waterPer = wData.bodyWaterRatio
      musclePer = wData.muscleMassRatio
      fatPer = wData.bodyFatRatio
      val height: String = userData?.height ?: "165"
      val h = height.toDouble() //in cm
      val bmi = userWeight / (h * h) * 10000.0
      val bmr: Int
      bmr = if (userData?.gender.equals("m")) {
        (66.47 +
          13.75 * userWeight +
          5.003 * h -
          6.755 * DateTimeUtils.findAge(userData?.dob).toDouble()).toInt()
      } else {
        (655.1 +
          9.563 * userWeight +
          1.85 * h -
          4.676 * DateTimeUtils.findAge(userData?.dob).toDouble()).toInt()
      }
      modelBmiData.setBmiWeight(String.format("%1$.2f", userWeight))
      modelBmiData.setBmi(String.format("%1$.2f", bmi))
      modelBmiData.setBoneMass(String.format("%1$.2f", boneMass))
      modelBmiData.setFatPer(String.format("%1$.2f", fatPer))
      modelBmiData.setWaterPer(String.format("%1$.2f", waterPer))
      modelBmiData.setMusclePer(String.format("%1$.2f", musclePer))
      modelBmiData.setBmr(bmr.toString()) //String.format("%1$.2f",
      modelBmiData.setDateTime(DateTimeUtils.getTimeFromStringDate("yyyy-MM-dd HH:mm:ss", wData.date))
    } catch (e: java.lang.Exception) {
      showToast("Error bmi data")
    }
    return modelBmiData
  }

  /**
   *
   */
  private fun showMeasuredDataDetails(objectData: Any?) {
    if (objectData != null) {
      if (objectData is WeightData_A3) {
        try {
          Log.d(MODULE_NAME,"OBJECT dateTime ${getModelBmiDataFromReading(objectData).dateTime}")
          Log.d(MODULE_NAME,"OBJECT assignedUserId ${getModelBmiDataFromReading(objectData).assignedUserId}")
          Log.d(MODULE_NAME,"OBJECT bmi ${getModelBmiDataFromReading(objectData).bmi}")
          Log.d(MODULE_NAME,"OBJECT bmiWeight ${getModelBmiDataFromReading(objectData).bmiWeight}")
          Log.d(MODULE_NAME,"OBJECT bmr ${getModelBmiDataFromReading(objectData).bmr}")
          Log.d(MODULE_NAME,"OBJECT boneMass ${getModelBmiDataFromReading(objectData).boneMass}")
          Log.d(MODULE_NAME,"OBJECT fatPer ${getModelBmiDataFromReading(objectData).fatPer}")
          Log.d(MODULE_NAME,"OBJECT id ${getModelBmiDataFromReading(objectData).id}")
          Log.d(MODULE_NAME,"OBJECT musclePer ${getModelBmiDataFromReading(objectData).musclePer}")
          Log.d(MODULE_NAME,"OBJECT readingNotes ${getModelBmiDataFromReading(objectData).readingNotes}")
          Log.d(MODULE_NAME,"OBJECT userId ${getModelBmiDataFromReading(objectData).userId}")
          Log.d(MODULE_NAME,"OBJECT waterPer ${getModelBmiDataFromReading(objectData).waterPer}")

          emitEvent(DATA_EVENT, mapWeightData(getModelBmiDataFromReading(objectData), objectData))
//                    showLiveReadingDialog(, false)
        } catch (e: java.lang.Exception) {
          e.printStackTrace()
          Log.d(MODULE_NAME,"OBJECT DATA ${getModelBmiDataFromReading(objectData)}")
          showToast("Error BMI data")
        }
      }
    }
  }

  private fun getPairedDeviceInfo(): List<LsDeviceInfo>? {
    var deviceList: List<LsDeviceInfo>? = null
    val key = PairedDeviceInfo::class.java.name
    val mPairedDeviceInfo = SettingInfoManager.readPairedDeviceInfoFromFile(reactContext, key)
    if (mPairedDeviceInfo != null && mPairedDeviceInfo.pairedDeviceMap != null) {
      deviceList = ArrayList()
      val deviceMap: Map<String, LsDeviceInfo> = mPairedDeviceInfo.pairedDeviceMap
      val it = deviceMap.entries.iterator()
      while (it.hasNext()) {
        val entry = it.next()
        val lsDevice = entry.value
        if (lsDevice != null) {
          deviceList.add(lsDevice)
        }
      }
    }
    return deviceList
  }

  private fun getUserInfo(): BleDeviceUserInfo {
//        val userData = null
    val bleDeviceUserInfo = BleDeviceUserInfo()
    bleDeviceUserInfo.userName = "Ravi"
//        if (userData != null) {
//            when (userData.getGender()) {
//                GENDER_MALE -> {
//                    bleDeviceUserInfo.userGender = GenderType.MALE
//                    bleDeviceUserInfo.athleteLevel = "0".toInt()
//                }
//                GENDER_FEMALE -> {
//                    bleDeviceUserInfo.userGender = GenderType.FEMALE
//                    bleDeviceUserInfo.athleteLevel = "0".toInt()
//                }
//                GENDER_ATHELET_MALE -> {
//                    bleDeviceUserInfo.userGender = GenderType.MALE
//                    bleDeviceUserInfo.athleteLevel = "1".toInt()
//                }
//                GENDER_ATHELET_FEMALE -> {
//                    bleDeviceUserInfo.userGender = GenderType.FEMALE
//                    bleDeviceUserInfo.athleteLevel = "1".toInt()
//                }
//                else -> {
//                    bleDeviceUserInfo.userGender = GenderType.MALE
//                    bleDeviceUserInfo.athleteLevel = "0".toInt()
//                }
//            }
//        } else {
    bleDeviceUserInfo.userGender = GenderType.MALE
    bleDeviceUserInfo.athleteLevel = "0".toInt()
//        }
    /*SimpleDateFormat inputDateFormat = new SimpleDateFormat("dd-MMM-yyyy", Locale.getDefault());
    SimpleDateFormat outputDateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());

    String outputDate = "";
    try {
        Date inputDate = inputDateFormat.parse(userData.getBirthDate());
        outputDate = outputDateFormat.format(inputDate);

    } catch (ParseException e) {
        e.printStackTrace();
    }

    String birthday = outputDate;
    bleDeviceUserInfo.setBirthday(birthday);
    //set user age
    if (!TextUtils.isEmpty(birthday) && birthday.contains("-")) {
        int yearIndex = birthday.indexOf("-");
        String yearStr = birthday.substring(0, yearIndex);
        int yearIntValue = Integer.parseInt(yearStr);
        Calendar calendar = Calendar.getInstance();
        int currentYear = calendar.get(Calendar.YEAR);
        bleDeviceUserInfo.setUserAge(currentYear - yearIntValue);
    } else {
        bleDeviceUserInfo.setUserAge(18);
    }*/try {
//            if (userData.getHeight() != null && !TextUtils.isEmpty(userData.getHeight())) {
//                bleDeviceUserInfo.userHeight = userData.getHeight().toFloat() / 100
//            } else {
      bleDeviceUserInfo.userHeight = 1.65f
//            }
//            if (userData.getWeight() != null && !TextUtils.isEmpty(userData.getWeight())) {
//                bleDeviceUserInfo.userWeight = userData.getWeight().toFloat()
//            } else {
      bleDeviceUserInfo.setUserWeight(65F)
//            }
    } catch (e: java.lang.Exception) {
      e.printStackTrace()
    }

    val weightUnit: WeightUnitType = WeightUnitType.KG
    bleDeviceUserInfo.weightUnit = weightUnit
    bleDeviceUserInfo.weightTarget = "65".toInt()
    val distanceUnit: DistanceUnitType = DistanceUnitType.KILOMETER
    bleDeviceUserInfo.distanceUnit = distanceUnit
    val hourFormat: HourFormatType = HourFormatType.HOUR_12
    bleDeviceUserInfo.hourFormat = hourFormat
    val weekStart: WeekStartType = WeekStartType.MONDAY
    bleDeviceUserInfo.weekStart = weekStart
    bleDeviceUserInfo.movingTarget = "50".toInt()
    bleDeviceUserInfo.developerKey = "true"
    return bleDeviceUserInfo
  }

  /**
   * @param deviceId
   */
  private fun setWeightUserInfoOnSyncDataMode(deviceId: String, userNumber: Int) {
    val userInfo: BleDeviceUserInfo = getUserInfo()
    val weightUserInfo = WeightUserInfo()
    weightUserInfo.age = if (userInfo.getUserAge() === 0) 25 else userInfo.getUserAge()
    weightUserInfo.productUserNumber = userNumber
//        if (userInfo.getUserHeight() === 0) {
    weightUserInfo.height = 1.65f
//        } else {
//            weightUserInfo.height = userInfo.getUserHeight()
//        }
    weightUserInfo.athleteActivityLevel = userInfo.getAthleteLevel()
    weightUserInfo.goalWeight = 10F
    if (userInfo.getWeightUnit() === WeightUnitType.KG) {
      weightUserInfo.unit = UnitType.UNIT_KG
    } else weightUserInfo.unit = UnitType.UNIT_LB
    if (userInfo.getUserGender() === GenderType.FEMALE) {
      weightUserInfo.sex = SexType.FEMALE
    } else weightUserInfo.sex = SexType.MALE
    if (userInfo.getAthleteLevel() === 0) {
      weightUserInfo.isAthlete = false
    } else weightUserInfo.isAthlete = true
    weightUserInfo.deviceId = deviceId
    mlsBleManager!!.setProductUserInfo(weightUserInfo)
  }

  private fun showBMIDeviceList() {

    myDeviceList = getPairedDeviceInfo()
    if (myDeviceList != null && myDeviceList!!.size > 0) {
      for (device in myDeviceList!!) {
        val deviceItem = PairedDeviceListItem(device, CELL_DEFAULT_HEIGHT, 0)
        mDeviceListItems!!.clear()
        mDeviceListItems!!.add(deviceItem)
        mlsBleManager!!.addMeasureDevice(device)
        if (DeviceTypeConstants.FAT_SCALE == device.deviceType || DeviceTypeConstants.WEIGHT_SCALE == device.deviceType) {
          setWeightUserInfoOnSyncDataMode(device.deviceId, device.deviceUserNumber)
        }
      }
    }
    if (mDeviceListItems!!.size > 0) {
      //TODO: SHOW DEVICE LIST
      logData(mDeviceListItems!!)
//            mRvScanResult.setVisibility(View.GONE)
//            mListView.setVisibility(View.VISIBLE)
//            mLlScanButtons.setVisibility(View.GONE)
    }
//        deviceAdapter.notifyDataSetChanged()
  }

  private fun intializeBMIReciever() {
    myDeviceList = getPairedDeviceInfo()
    if (myDeviceList != null && myDeviceList!!.size > 0) {
      for (device in myDeviceList!!) {
        mlsBleManager!!.addMeasureDevice(device)
      }
      if (mlsBleManager != null) {
        mlsBleManager!!.stopDataReceiveService()
        mlsBleManager!!.startDataReceiveService(mReceiveDataCallback)
      }
    }
  }

  private fun initiateListener() {
    Timer().schedule(object : TimerTask() {
      override fun run() {
        intializeBMIReciever()
      }
    }, 2000)
  }

  private fun initiateTimer() {
    Timer().schedule(object : TimerTask() {
      override fun run() {
        if (wDataList_A3.size == 1) {
          showMeasuredDataDetails(wDataList_A3[0])
//                    Log.d(MODULE_NAME, "SINGLE WEIGHT DATA ${wDataList_A3[0]}")
          wDataList_A3.clear()
        } else {
//                    Log.d(MODULE_NAME, "MULTI WEIGHT DATA ${wDataList_A3}")
          showMeasuredReadingsDetailsInList(wDataList_A3)
          wDataList_A3.clear()
        }
      }
    }, 2000)
  }

  private val mReceiveDataCallback: ReceiveDataCallback = object : ReceiveDataCallback() {
    override fun onReceiveWeightData_A3(wData: WeightData_A3) {

      Log.d("Weight", "New Weight wData$wData")
//            if (wData != null) {
////                println("Receiving the measured data A3 fat scale=$wData")
//                logData(wData)
//                //TODO: SHOW MEASURED DETAILS FROM MACHINE
////                showMeasuredDataDetails(wData, true)
//                Log.d("Weight", "New Weight$wData")
//            }x
      if (wData != null) {
        wDataList_A3.add(wData)
        if (wDataList_A3.size == 1) {
          initiateTimer()
        }
      }
    }

    override fun onReceiveUserInfo(proUserInfo: WeightUserInfo) {

      Log.e("WeightUserInfo========", "product user info is :$proUserInfo")
//            runOnUiThread { showloadAds() }
    }

    //update and save device info ,if current connected device is generic fat and kitchen scale
    override fun onReceiveDeviceInfo(device: LsDeviceInfo) {
//            restartTimer()
      Log.d(MODULE_NAME, "the current connected device info is:$device")
      val runner = AsyncTaskRunner(reactContext, device)
      Log.d("Weight", "New Weight" + device.deviceName)
      runner.execute()
    }
  }

  /**
   *
   */
  private fun setWeightUserInfoOnPairingMode() {
    val userInfo = getUserInfo()
    val weightUserInfo = WeightUserInfo()
    weightUserInfo.age = if (userInfo.userAge === 0) 25 else userInfo.userAge
    if (userInfo.userHeight === 0F) {
      weightUserInfo.height = 1.65f
    } else {
      weightUserInfo.height = userInfo.userHeight
    }
    weightUserInfo.athleteActivityLevel = userInfo.athleteLevel
    weightUserInfo.goalWeight = userInfo.weightTarget.toFloat()
    if (userInfo.weightUnit === WeightUnitType.LB) {
      weightUserInfo.unit = UnitType.UNIT_LB
    } else weightUserInfo.unit = UnitType.UNIT_KG
    if (userInfo.userGender === GenderType.FEMALE) {
      weightUserInfo.sex = SexType.FEMALE
    } else weightUserInfo.sex = SexType.MALE
    if (userInfo.athleteLevel === 0) {
      weightUserInfo.isAthlete = false
    } else weightUserInfo.isAthlete = true
    println("Pairing process, setting up the scale user information$weightUserInfo")
    mlsBleManager!!.setProductUserInfo(weightUserInfo)
  }

  private fun writeUserAccountToDevice(userNumber: Int, name: String) {
    mlsBleManager!!.bindDeviceUser(userNumber, name.trim { it <= ' ' })
  }

  private fun showDeviceUserInfo(userList: List<DeviceUserInfo>?) {

    // Strings to Show In Dialog with Radio Buttons
    rnDeviceUserList.clear()
    if (userList != null && userList.size > 0) {
      for (user in userList) {
        if (user != null) {
          user.deviceId
          val index = userList.indexOf(user)
          if (user.userName.isEmpty()) {
            rnDeviceUserList.add(mapUser(user.userNumber, "unknown" ))
          } else {
            rnDeviceUserList.add(mapUser(user.userNumber, user.userName ))
          }
        }
      }
      emitEvent(USER_LIST_FOUND_EVENT, Arguments.makeNativeArray(rnDeviceUserList))
    }
  }

  private val mPairCallback: PairCallback = object : PairCallback() {
    override fun onDiscoverUserInfo(userList: List<*>?) {
      if (userList != null) {
        mDeviceUserList = userList as List<DeviceUserInfo>?
        showDeviceUserInfo(mDeviceUserList)
      }
    }

    override fun onPairResults(lsDevice: LsDeviceInfo, status: Int) {
      runOnUiThread {
        //                /
        if (lsDevice != null && status == 0) {
//                    val modelBleDevice = ModelBleDevice()
//                    modelBleDevice.setDeviceName(lsDevice.deviceName)
//                    modelBleDevice.setStatus(Constants.BLE_STATUS_CONNECTED)
//                    modelBleDevice.setMacAddress(lsDevice.macAddress)
          if (userData != null) {
//                        val userData: FamilyUser = mUserArrayList.get(mSelectedUser)
            val bleDeviceUserInfo = BleDeviceUserInfo()
            bleDeviceUserInfo.userName = userData!!.getName()
            if (userData!!.getGender() != null) {
              when (userData!!.getGender()) {
                "m" -> {
                  bleDeviceUserInfo.userGender = GenderType.MALE
                  bleDeviceUserInfo.athleteLevel = "0".toInt()
                }
                "f" -> {
                  bleDeviceUserInfo.userGender = GenderType.FEMALE
                  bleDeviceUserInfo.athleteLevel = "0".toInt()
                }
                "am" -> {
                  bleDeviceUserInfo.userGender = GenderType.MALE
                  bleDeviceUserInfo.athleteLevel = "1".toInt()
                }
                "af" -> {
                  bleDeviceUserInfo.userGender = GenderType.FEMALE
                  bleDeviceUserInfo.athleteLevel = "1".toInt()
                }
                else -> {
                  bleDeviceUserInfo.userGender = GenderType.MALE
                  bleDeviceUserInfo.athleteLevel = "0".toInt()
                }
              }
            } else {
              bleDeviceUserInfo.userGender = GenderType.MALE
              bleDeviceUserInfo.athleteLevel = "0".toInt()
            }
            val inputDateFormat = SimpleDateFormat("dd-MMM-yyyy", Locale.getDefault())
            val outputDateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
            var outputDate = ""
            try {
              val inputDate = inputDateFormat.parse(userData!!.getDob())
              outputDate = outputDateFormat.format(inputDate)
            } catch (e: ParseException) {
              e.printStackTrace()
            }
            val birthday = outputDate
            bleDeviceUserInfo.birthday = birthday
            //set user age
            if (!TextUtils.isEmpty(birthday) && birthday.contains("-")) {
              val yearIndex = birthday.indexOf("-")
              val yearStr = birthday.substring(0, yearIndex)
              val yearIntValue = yearStr.toInt()
              val calendar = Calendar.getInstance()
              val currentYear = calendar[Calendar.YEAR]
              bleDeviceUserInfo.userAge = currentYear - yearIntValue
            } else {
              bleDeviceUserInfo.userAge = 18
            }
            try {
              bleDeviceUserInfo.userHeight = userData!!.getHeight().toFloat() / 100
              bleDeviceUserInfo.userWeight = if (!TextUtils.isEmpty(userData!!.getWeight())) userData!!.getWeight().toFloat() else 0f
            } catch (e: java.lang.Exception) {
              e.printStackTrace()
            }
            val weightUnit = WeightUnitType.KG
            bleDeviceUserInfo.weightUnit = weightUnit
            bleDeviceUserInfo.weightTarget = "65".toInt()
            val distanceUnit = DistanceUnitType.KILOMETER
            bleDeviceUserInfo.distanceUnit = distanceUnit
            val hourFormat = HourFormatType.HOUR_12
            bleDeviceUserInfo.hourFormat = hourFormat
            val weekStart = WeekStartType.MONDAY
            bleDeviceUserInfo.weekStart = weekStart
            bleDeviceUserInfo.movingTarget = "50".toInt()
            bleDeviceUserInfo.developerKey = "true"
            val weightUserInfo = WeightUserInfo()
            weightUserInfo.productUserNumber = lsDevice.deviceUserNumber
            weightUserInfo.age = bleDeviceUserInfo.userAge
            weightUserInfo.height = bleDeviceUserInfo.userHeight
            weightUserInfo.athleteActivityLevel = bleDeviceUserInfo.athleteLevel
            weightUserInfo.goalWeight = bleDeviceUserInfo.weightTarget.toFloat()
            if (bleDeviceUserInfo.weightUnit === WeightUnitType.LB) {
              weightUserInfo.unit = UnitType.UNIT_LB
            } else weightUserInfo.unit = UnitType.UNIT_KG
            if (bleDeviceUserInfo.userGender === GenderType.FEMALE) {
              weightUserInfo.sex = SexType.FEMALE
            } else weightUserInfo.sex = SexType.MALE
            if (bleDeviceUserInfo.athleteLevel === 0) {
              weightUserInfo.isAthlete = false
            } else weightUserInfo.isAthlete = true
            try {
              weightUserInfo.waistline = userData!!.getWaist().toFloat()
            } catch (e: java.lang.Exception) {
            }
            weightUserInfo.deviceId = lsDevice.deviceId

            logData(weightUserInfo)

            if (mlsBleManager!!.setProductUserInfo(weightUserInfo)) {
              val runner = AsyncTaskRunner(reactContext, lsDevice)
              runner.execute()
              logData("Initiating User")
              initiateListener()
//                            redirectToScreen(modelBleDevice)
              emitEvent(DEVICE_CONNECTED_EVENT, mapDeviceDescription(lsDevice, true))
            } else {
//                            mSelectedUser = 0
              mlsBleManager!!.searchLsDevice(mSearchCallback, getDeviceTypes(), getBroadcastType())
              logData("Pairing process")
//                            showPromptDialog(getResources().getString(R.string.prompt), getResources().getString(R.string.pairing_failed_try_again), ActionType.PAIRING_PROCESS)
            }
          }
        } else {
//                    mSelectedUser = 0
          mlsBleManager!!.searchLsDevice(mSearchCallback, getDeviceTypes(), getBroadcastType())
          logData("Pairing process")
//                    showPromptDialog(getResources().getString(R.string.prompt), getResources().getString(R.string.pairing_failed_try_again), ActionType.PAIRING_PROCESS)
        }
      }
    }
  }

  /**
   *
   */
  private fun readScanFilterSetting() {
    mBroadcastType = BroadcastType.ALL
    mScanDeviceType = ArrayList<DeviceType>()
    mScanDeviceType!!.add(DeviceType.FAT_SCALE)
  }


  private fun setUpForBMI() {

    mlsBleManager = LsBleManager.newInstance()
    mlsBleManager!!.initialize(reactContext)

    mDeviceListItems = ArrayList()

    myDeviceList = getPairedDeviceInfo()

    if (myDeviceList != null && myDeviceList!!.size > 0) {
      for (device in myDeviceList!!) {
        val deviceItem = PairedDeviceListItem(device, CELL_DEFAULT_HEIGHT, 0)
        mDeviceListItems!!.add(deviceItem)
      }
    }

    if (mDeviceListItems!!.size > 0) {
      showBMIDeviceList()
    }

    readScanFilterSetting()
    tempList = ArrayList()
  }

  /**
   * Initialize the timer to restart the scan. If the scan callback interface does not respond within 15 seconds, it will return a prompt result.
   *
   * @param delayTime
   */
  private fun initScanResultsTimer(delayTime: Int) {
    val scanTime = 15 * 1000 + delayTime
    if (scanResultTimer != null) {
      scanResultTimer!!.cancel()
    }
    scanResultTimer = Timer()
    scanResultTimer!!.schedule(object : TimerTask() {
      override fun run() {
        runOnUiThread(Runnable {
          if (!hasScanResults) {
            //TODO: Hide loader
            showToast("Please make sure that bluetooth device is on and then try again.")
          }
        })
      }
    }, scanTime.toLong())
  }
  private fun isDeviceExists(name: String?): Boolean {
    if (name == null || name.length == 0) {
      return false
    }
    return if (tempList != null && tempList!!.size > 0) {
      for (i in tempList!!.indices) {
        val tempDeInfo = tempList!![i]
        if (tempDeInfo != null && tempDeInfo.deviceName != null && tempDeInfo.deviceName == name) {
          return true
        }
      }
      false
    } else false
  }

  private val mSearchCallback = SearchCallback { lsDevice ->
    if (lsDevice != null) {
      hasScanResults = true
      if (scanResultTimer != null) {
        scanResultTimer!!.cancel()
      }
      runOnUiThread {
        //TODO: Hide loader if visible
        if (!isDeviceExists(lsDevice.deviceName)) {
          Log.d(MODULE_NAME,"scan results $lsDevice")
          if (lsDevice.pairStatus == 1) {
            rnDeviceList?.add(mapDeviceDescription(lsDevice, false))
          } else {
            logData("Initiating User mSearchCallback")
            rnDeviceList?.add(mapDeviceDescription(lsDevice, true))
            intializeBMIReciever()
          }
//                    myDeviceList.add
          Log.d(MODULE_NAME, rnDeviceList.toString())


//                    val arguments = Arguments.createMap().apply {
//                        putString("path", "general/authentication")
//                        putArray("actions",Arguments.makeNativeArray(listOf(rnDeviceList)))
//                    }

//                    emitEvent(DEVICE_FOUND_EVENT, arguments)

          emitEvent(DEVICE_FOUND_EVENT, Arguments.makeNativeArray(rnDeviceList))

//                    emitEvent(DATA_EVENT, Arguments.makeNativeMap(mapOf(
//                            "data" to mappedEcgDATA,
//                            "device" to mapDeviceDescription(mDevice!!, CONNECT))))
//
//                    myDeviceList!!.add(lsDevice)
          tempList!!.add(lsDevice)
        }
      }
    }
  }

  private fun getPairedDeviceInfoStatus(lsDevice: LsDeviceInfo): Boolean {
    val key = PairedDeviceInfo::class.java.name
    val mPairedDeviceInfo = SettingInfoManager.readPairedDeviceInfoFromFile(reactContext, key)
    if (mPairedDeviceInfo != null && mPairedDeviceInfo.pairedDeviceMap != null) {
      val deviceMap: Map<String, LsDeviceInfo> = mPairedDeviceInfo.pairedDeviceMap
      val it = deviceMap.entries.iterator()
      while (it.hasNext()) {
        val entry = it.next()
        val lsdevice = entry.value
        if (lsdevice != null && lsdevice.macAddress != null && lsdevice.macAddress == lsDevice.macAddress) {
          return true
        }
      }
    }
    return false
  }

  private fun getDeviceTypes(): List<DeviceType?>? {
    if (mScanDeviceType == null) {
      mScanDeviceType = ArrayList()
      mScanDeviceType!!.add(DeviceType.FAT_SCALE)
      mScanDeviceType!!.add(DeviceType.WEIGHT_SCALE)
    }
    Log.d(MODULE_NAME,"Current scan device type：" + mScanDeviceType.toString())
    return mScanDeviceType
  }

  private fun getBroadcastType(): BroadcastType? {
    return mBroadcastType
  }

  @ReactMethod
  fun initialize(userDetails: ReadableMap, promise: Promise) {
    try {



      val id : Int = userDetails.getInt("id")
      val name : String? = userDetails.getString("first_name").toString()
      val dob : String? = userDetails.getString("dob").toString()
      val weight : String? = userDetails.getDouble("weight").toString()
      val height : String? = userDetails.getString("height").toString()
      val gender : String? = userDetails.getString("gender").toString()

      val user = FamilyUser()
      // if logged in user then set id to 0
      user.id = 0
      user.userId = id
      user.name = name
      user.dob = "08-Aug-1997"
      user.gender = gender
      user.height = height
      user.weight = weight

      userData = user

      logData(user)

      setUpForBMI()


      if (!mlsBleManager!!.isOpenBluetooth) {
        showToast("Please turn on bluetooth")
        promise.resolve(mapInitDescription(false))
      } else {
        promise.resolve(mapInitDescription(true))
      }
    } catch (e: Exception) {
      promise.reject(INIT_ERROR, e)
    }
  }

  @ReactMethod
  fun startScan(promise: Promise) {
    try {
      Log.i(MODULE_NAME, "Start scanning for devices.")
      if (!mlsBleManager!!.isSupportLowEnergy) {
        showToast("Unsupported device")
      }

      if (!mlsBleManager!!.isOpenBluetooth) {
        showToast("Please turn on bluetooth")
      } else {
        hasScanResults = false
        //search lifesense bluetooth
        rnDeviceList.clear()
        tempList!!.clear()
        mlsBleManager!!.searchLsDevice(mSearchCallback, getDeviceTypes(), getBroadcastType())

        initScanResultsTimer(0)
      }
      promise.resolve(mapMessageStats("SCAN_BEGAN"))
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }

  @ReactMethod
  fun stopScan(promise: Promise) {
    try {
      Log.i(MODULE_NAME, "Stop scanning for devices.")
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }

  @ReactMethod
  fun connectToDevice(uuid: String,promise: Promise) {
    try {

      Log.i(MODULE_NAME, "Connect device with" + uuid  + "address.")
      Log.i(MODULE_NAME, "UUID device with $uuid address.")

      if(tempList == null || tempList!!.isEmpty()) {
        promise.resolve(mapMessageStats("UNKNOWN_DEVICE"))
        return
      }

      // to get the result as list
      var deviceList: List<LsDeviceInfo> = tempList!!.filter { s -> s.deviceName == uuid }

      val device = deviceList[0]

      Log.d(MODULE_NAME,"" + "====>" + device + "<====" )

      mlsBleManager!!.stopSearch()
      //TODO: Show pairing sign
      Log.d(MODULE_NAME,"select device info :" + device.toString())
      if (device.getPairStatus() == 1) { //set custom broacast Id to device,if need

        //User setting information pairing
        if (DeviceTypeConstants.FAT_SCALE == device.getDeviceType()) {
          setWeightUserInfoOnPairingMode()
          //show pairing menu
          mlsBleManager!!.startPairing(device, mPairCallback)
        }
      } else if (device.getProtocolType() == "A4" || device.getProtocolType() == "GENERIC_FAT") {
        Log.d(MODULE_NAME, "======> add device information <======")
        Log.d(MODULE_NAME, "======> " + device + "     <======")
        Log.d(MODULE_NAME, "======> add device information <======")
        device.setDeviceId(device.getDeviceName()) //set the device id to save ,when
        val runner = AsyncTaskRunner(reactContext, device)
        runner.execute()
      } else {
        val broadcastId: String = device.getBroadcastID()
        val deviceInfo = SettingInfoManager.getPairedDeviceInfoByBroadcastID(reactContext, broadcastId)
        if (deviceInfo != null) {
          Log.d(MODULE_NAME, "======> paired device information <======")
          Log.d(MODULE_NAME, "======> " + deviceInfo + "        <======")
          Log.d(MODULE_NAME, "======> paired device information <======")
        } else {
          Log.d(MODULE_NAME, "======> unpaired device information <======")
          Log.d(MODULE_NAME, "======> " + deviceInfo + "          <======")
          Log.d(MODULE_NAME, "======> unpaired device information <======")
        }
      }

      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }

  @ReactMethod
  fun pairUser(user: ReadableMap,promise: Promise) {
    try {
      Log.i(MODULE_NAME, "Start data collection.")
//            if (mUserArrayList.get(i) != null && !TextUtils.isEmpty(mUserArrayList.get(i).getName())) {
//                mSelectedUser = i
      if(mDeviceUserList != null) {
        val userNumber = user.getInt("key")
        val userName = user.getString("value")
        mlsBleManager!!.bindDeviceUser(userNumber, userName)
      }

//            }
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }

  @ReactMethod
  fun startCollection(promise: Promise) {
    try {
      Log.i(MODULE_NAME, "Start data collection.")
      intializeBMIReciever()
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }

  @ReactMethod
  fun stopCollection(promise: Promise) {
    try {
      Log.i(MODULE_NAME, "Stop data collection.")
      promise.resolve(null)
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }

  @ReactMethod
  fun disconnectFromDevice(broadcastID: String?,promise: Promise) {
    try {
      Log.i(MODULE_NAME, "disconnectFromDevice")
      //LONG CLICK ON PAIRED DEVICE TO DISCONNECT/REMOVE/DESTROY DEVICE FROM PAIRED LIST
//            val tempItem = parent.getAdapter().getItem(position) as PairedDeviceListItem
//            SHOW IN RN TO REMOVE DEVICE AND PASS THE BROADCAST ID
//            val title = tempItem.deviceInfo.deviceName + tempItem.deviceInfo.broadcastID
//            val msg: String = mMultiLanguageSupport.getLabel(UILabelsKeys.DO_YOU_REALLY_WANT_TO_DELETE_IT)
      val delBroadcastId = broadcastID

      val delete = SettingInfoManager.deletePairedDeviceInfo(reactContext, delBroadcastId)

      if (mlsBleManager != null) {
        mlsBleManager!!.stopSearch()
        mlsBleManager!!.stopDataReceiveService()
        if (scanResultTimer != null) {
          scanResultTimer!!.cancel()
        }
      }
      MedCheck.getInstance().unregisterCallBack(reactContext)

      if (delete) { //update the ble measured device list
        mlsBleManager!!.deleteMeasureDevice(delBroadcastId)
        //REMOVE DEVICE FROM LIST
        //SHOW EVENT THAT DEVICE IS DELETED
        showToast("DELETE WAS SUCCESSFULL FOR" + delBroadcastId);
        showToast("DELETE WAS SUCCESSFULL" + delBroadcastId)

        if (mDeviceListItems!!.size == 0) {
          mlsBleManager!!.stopDataReceiveService()
        }
      }
      promise.resolve(Arguments.makeNativeMap(mapOf(
        "delete" to true
      )))
    } catch (e: Exception) {
      promise.reject(UNKNOWN_ERROR, e)
    }
  }


}
