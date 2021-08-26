import React, { Component } from 'react';
import {
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  Platform,
  ActivityIndicator,
  Alert,
  PermissionsAndroid,
} from 'react-native';

import styles from './style';

import _ from 'lodash';
import MedcheckSdk from 'react-native-medcheck-sdk';
export interface WScaleDevice {
  id: String;
  deviceId: String;
  deviceSn: String;
  deviceType: String;
  modelNumber: String;
  peripheralIdentifier: String;
  deviceName: String;
  state: String;
}

export interface BmiReading {
  device_data: {
    bmi: String,
    bmi_weight: String,
    bmr: String,
    bone_mass: String,
    fat_per: String,
    muscle_per: String,
    water_per: String,
  };
  device_id: String;
  is_manual: String;
  reading_notes: String;
  reading_time: String;
  user_family_id: String;
  user_id: String;
}

export interface WScaleUser {
  key: String;
  value: String;
}

const medKit = new MedcheckSdk();
class ConnectScreen extends Component {
  focusListener;
  blurListener;
  onDeviceFoundListener;
  onDeviceConnectListener;
  onSearchFinishListener;
  onCollectionFoundListener;
  onScanFinishedListener;
  onUserListFoundListener;

  state = {
    loading: false,
    message: '',
    devices: [],
    userList: [],
    isDialogVisible: false,
    bmi_weight: '',
    bmi: '',
    muscle_percent: '',
    fat_per: '',
    bone_mass: '',
    water_per: '',
  };

  setModalVisible(visible) {
    this.setState({ modalVisible: visible });
  }
  async requestCameraPermission() {
    try {
      const granted = await PermissionsAndroid.requestMultiple(
        [
          PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
          PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
        ],
        {
          title: 'Medlives requires access to location',
          message:
            'Medlives needs access to your location' +
            'so we can give better device results.',
          buttonNeutral: 'Ask Me Later',
          buttonNegative: 'Cancel',
          buttonPositive: 'OK',
        }
      );

      if (
        granted['android.permission.ACCESS_COARSE_LOCATION'] &&
        granted['android.permission.WRITE_EXTERNAL_STORAGE'] === 'granted'
      ) {
        this.startSearch();
      } else {
        Alert.alert('Permission denied');
      }
    } catch (err) {
      console.warn(err);
    }
  }

  _handleDeviceFound = (devicelist: [WScaleDevice]) => {
    console.log(
      'TCL: componentName -> _handleDeviceFound -> devicelist',
      devicelist
    );
    this.setState({
      loading: false,
      message: 'Device found',
    });

    if (devicelist[0]) {
      this.setState({
        message: 'Device found',
        devices: _.uniqBy(devicelist, 'deviceName'),
      });
    }
  };

  _handleDeviceConnected = (device: WScaleDevice) => {
    console.log(
      'TCL: componentName -> _handleDeviceConnected -> device',
      device
    );
    if (device) {
      this.setState({
        loading: false,
        message: 'Device paired',
        devices: [device],
      });
    }
  };

  _handleSearchFinish = () => {
    this.setState({
      loading: false,
    });
  };
  _handleScanFinished = () => {
    this.setState({
      loading: false,
    });
  };

  _handleCollectionData = (readings) => {
    console.log(
      'TCL: componentName -> _handleCollectionData -> readings',
      readings
    );
    this.setState({
      loading: false,
    });
    //MARK: open popup
    if (typeof readings === []) {
      console.log('obj is array----==============');
      this.setState({
        isDialogVisible: true,
        bmi_weight: readings[0].data.device_data.bmi_weight,
        bmi: readings[0].data.device_data.bmi,
        muscle_percent: readings[0].data.device_data.muscle_per,
        fat_per: readings[0].data.device_data.fat_per,
        bone_mass: readings[0].data.device_data.bone_mass,
        water_per: readings[0].data.device_data.water_per,
      });
      this.WS_SendBmiDataToServer();
    } else {
      console.log(readings.data);
      this.setState({
        isDialogVisible: true,
        bmi_weight: readings.data.device_data.bmi_weight,
        bmi: readings.data.device_data.bmi,
        muscle_percent: readings.data.device_data.muscle_per,
        fat_per: readings.data.device_data.fat_per,
        bone_mass: readings.data.device_data.bone_mass,
        water_per: readings.data.device_data.water_per,
      });
      this.WS_SendBmiDataToServer();
    }

    // readings.data.device_data.bmi
    // readings.data.device_data.bmr
    // readings.data.device_data.water_per

    // readings.data.device_data.bone_mass
    // readings.data.device_data.fat_per

    // readings.data.device_data.bmi_weight
    // readings.data.device_data.muscle_per
  };

  _handleUserList = (userList: [WScaleUser]) => {
    console.log('TCL: componentName -> _handleUserList -> res', userList);
    this.setState({
      loading: false,
      message: 'Select user to pair',
      userList: userList.sort(
        (item1, item2) => parseFloat(item1.key) - parseFloat(item2.key)
      ),
    });
  };

  componentDidUpdate(prevProps, prevState) {
    if (this.state.loading === true) {
      console.log('START TIMER');
      this.timerStop = setTimeout(() => {
        this.setState({ loading: false });
      }, 60000);
    }
  }

  componentWillUnmount() {
    clearTimeout(this.timerStop);
  }

  componentDidMount() {
    this.onDeviceFoundListener = medKit.addListener(
      'deviceFound',
      this._handleDeviceFound
    );
    this.onDeviceConnectListener = medKit.addListener(
      'deviceConnected',
      this._handleDeviceConnected
    );
    this.onSearchFinishListener = medKit.addListener(
      'scanFinished',
      this._handleSearchFinish
    );
    this.onCollectionFoundListener = medKit.addListener(
      'data',
      this._handleCollectionData
    );
    this.onScanFinishedListener = medKit.addListener(
      'collectionFinished',
      this._handleScanFinished
    );
    this.onUserListFoundListener = medKit.addListener(
      'userListFound',
      this._handleUserList
    );

    console.log('LAST CONNECTED DEVICES', this.props.lastDeviceList);
    // if (Platform.OS === 'ios') {
    //   this.startSearch();
    // } else {
    //   this.requestCameraPermission();
    // }
  }

  WS_SendBmiDataToServer = async () => {
    console.log(
      'WS_SendBmiDataToServer',
      this.state.bmi_weight,
      this.state.bmi
    );
    try {
      const jsonData = JSON.stringify({
        data: {
          user_id: '123',
          weight: this.state.bmi_weight,
          bmi: this.state.bmi,
          bodyfat: this.state.fat_per,
          moisturerate: this.state.water_per,
          bonemass: this.state.bone_mass,
          basalmetabolism: '',
          whethertowearshoes: '',
          musclerate: this.state.muscle_percent,
        },
      });
    } catch (error) {
      console.error(error);
    }
  };

  startSearch = () => {
    var userDetails = {
      id: 214,
      first_name: 'john',
      dob: '08-Aug-1997',
      weight: 80,
      height: '160',
      gender: 'm',
    };
    this.setState({
      loading: true,
    });

    medKit
      .initialize(userDetails)
      .then((res) => {
        console.log('TCL: componentName -> componentDidMount -> res', res);
        if (!res.status) {
          Alert.alert('Please turn on bluetooth');
          this.setState({
            message: res.message,
            loading: false,
          });
          return;
        }
        medKit
          .startScan()
          .then((res) => {
            console.log('TCL: componentName -> componentDidMount -> res', res);
            this.setState({
              message: res.message,
              laoding: true,
            });
            this.setState({
              devices: [],
            });
          })
          .catch((error) => {
            this.setState({
              laoding: false,
            });
            console.log(
              'TCL: componentName -> componentDidMount -> error',
              error
            );
          });
      })
      .catch((error) => {
        this.setState({
          laoding: false,
        });
        console.log('TCL: componentName -> componentDidMount -> error', error);
      });
  };

  _connect = (item: WScaleDevice) => {
    console.log('id ======>', item);
    if (!item.state) {
      Alert.alert('Connect device');
      medKit.connectToDevice(item);
    } else {
      Alert.alert('Start Service');
      medKit.startCollection();
    }
  };

  scanDevices() {
    if (Platform.OS === 'ios') {
      this.startSearch();
    } else {
      this.requestCameraPermission();
    }
  }

  renderBmiDetailsPopup() {
    return (
      <View style={[styles.container]}>
        <TouchableOpacity
          style={styles.container}
          activeOpacity={1}
          onPress={() => this.setState({ isDialogVisible: false })}
        >
          <View style={[styles.modal_container]}>
            <View style={styles.modal_body}>
              <View
                style={{
                  // justifyContent: 'center',
                  alignItems: 'center',
                  // margin: 0,
                  backgroundColor: '#E78491',
                  // flex: 0.6,
                }}
              >
                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                  }}
                >
                  {'Weight & BMI Result'}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                    alignSelf: 'center',
                    marginTop: 16,
                  }}
                >
                  {this.state.bmi_weight}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 16,
                    alignSelf: 'center',
                    marginTop: 0,
                  }}
                >
                  {this.state.bmi_weight == '' ? '' : 'CURRENT | KG'}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                    alignSelf: 'center',
                    marginTop: 8,
                  }}
                >
                  {this.state.bmi}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 16,
                    alignSelf: 'center',
                    marginTop: 0,
                  }}
                >
                  {this.state.bmi == '' ? '' : 'BMI'}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                    alignSelf: 'center',
                    marginTop: 8,
                  }}
                >
                  {this.state.muscle_percent}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 16,
                    alignSelf: 'center',
                    marginTop: 0,
                  }}
                >
                  {this.state.muscle_percent == '' ? '' : 'MuscleMassRatio'}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                    alignSelf: 'center',
                    marginTop: 8,
                  }}
                >
                  {this.state.fat_per}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 16,
                    alignSelf: 'center',
                    marginTop: 0,
                  }}
                >
                  {this.state.fat_per == '' ? '' : 'BodyFatRatio'}
                </Text>

                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                    alignSelf: 'center',
                    marginTop: 8,
                  }}
                >
                  {this.state.bone_mass}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 16,
                    alignSelf: 'center',
                    marginTop: 0,
                  }}
                >
                  {this.state.bone_mass == '' ? '' : 'BoneDensity'}
                </Text>

                <Text
                  style={{
                    color: 'white',
                    fontSize: 24,
                    alignSelf: 'center',
                    marginTop: 8,
                  }}
                >
                  {this.state.water_per}
                </Text>
                <Text
                  style={{
                    color: 'white',
                    fontSize: 16,
                    alignSelf: 'center',
                    marginTop: 0,
                  }}
                >
                  {this.state.water_per == '' ? '' : 'BodywaterRatio'}
                </Text>
                <Text
                  onPress={() => this.setState({ isDialogVisible: false })}
                  style={{
                    fontSize: 20,
                    margin: 8,
                    alignSelf: 'center',
                    width: 150,
                  }}
                >
                  {'Ok'}
                </Text>
              </View>
            </View>
          </View>
        </TouchableOpacity>
      </View>
    );
  }
  render() {
    const devices: [WScaleDevice] = this.state.devices;
    const userList = this.state.userList;
    return (
      <>
        <View style={{ flex: 1 }}>
          <View
            style={{
              marginTop: Platform.OS === 'android' ? 0 : 40,
              width: '100%',
              alignItems: 'center',
              paddingVertical: 20,
              backgroundColor: 'pink',
            }}
          >
            <Text>{'Example'}</Text>
          </View>
          <View
            style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}
          >
            <View style={{ padding: 10 }}>
              {this.state.loading && (
                <ActivityIndicator size="large" color={'#E78491'} />
              )}
              <Text style={{ padding: 5 }}>{this.state.message}</Text>
            </View>
            <ScrollView
              contentContainerStyle={{
                alignItems: 'center',
              }}
              style={{
                width: '100%',
              }}
            >
              <Text style={{ fontSize: 20, marginVertical: 15 }}>
                {'Connect via Bluetooth'}
              </Text>

              {!!devices[0] === false && (
                <View
                  style={{
                    width: '90%',
                    marginTop: 20,
                    paddingBottom: 20,
                    marginBottom: 40,
                    alignItems: 'center',
                    justifyContent: 'center',
                    backgroundColor: 'white',
                  }}
                >
                  <Text
                    style={{
                      paddingHorizontal: 30,
                      fontSize: 16,
                      textAlign: 'center',
                    }}
                  >
                    {'Only MedCheck device can be connected to this Example'}
                  </Text>

                  <TouchableOpacity
                    style={{
                      padding: 16,
                      marginVertical: 20,
                      backgroundColor: 'pink',
                    }}
                    onPress={() => {
                      this.scanDevices();
                    }}
                  >
                    <Text>{'Scan Device'}</Text>
                  </TouchableOpacity>
                </View>
              )}
              {devices.map((item, index) => {
                return (
                  <View
                    key={index}
                    style={{
                      padding: 10,
                      margin: 10,
                      marginBottom: 5,
                      borderRadius: 5,
                      borderWidth: 0.5,
                      flexDirection: 'row',
                    }}
                  >
                    <Text
                      style={{
                        height: 20,
                        width: 20,
                        margin: 5,
                        marginTop: 10,
                        marginStart: 8,
                      }}
                    >
                      {'**'}
                    </Text>
                    <View style={{ flex: 1, flexDirection: 'column' }}>
                      <Text> {'Weight & BMI Scale'} </Text>
                      <Text> {item.deviceName} </Text>
                    </View>
                    {/* <View style={{ margin: 16 }}> */}
                    <Text
                      onPress={() => this._connect(item)}
                      style={{ fontSize: 10 }}
                    >
                      {`${item.state ? 'Paired' : 'Pair'}`}
                    </Text>
                  </View>
                );
              })}
              {userList.map((item, index) => {
                return (
                  <TouchableOpacity
                    onPress={() => {
                      console.log(item);
                      //Save - savePairedUser
                      medKit.pairUser(item);
                    }}
                    key={item.key}
                    style={{
                      padding: 10,
                      margin: 10,
                      marginBottom: 5,
                      borderRadius: 5,
                      borderWidth: 0.5,
                      flexDirection: 'row',
                    }}
                  >
                    <Text> {`P${item.key}: ${item.value}`} </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
          {this.state.isDialogVisible ? this.renderBmiDetailsPopup() : null}
        </View>
      </>
    );
  }
}

export default ConnectScreen;
