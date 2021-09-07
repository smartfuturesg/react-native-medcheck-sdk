import React, { Component } from 'react';
import {
  Text,
  View,
  TouchableOpacity,
  ScrollView,
  Platform,
  ActivityIndicator,
  Alert,
} from 'react-native';

import styles from './style';

import _ from 'lodash';
import MedcheckSdk from 'react-native-medcheck-sdk';

import { PermissionsAndroid } from 'react-native';

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

const DEVICE_TYPE = {
  DEVICE_BLOOD_PRESSURE: 1,
  DEVICE_BLOOD_GLUCOSE: 2,
  DEVICE_BODY_MASS_INDEX: 3,
};

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
    readings: null,
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
          PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
        ],
        {
          title: 'App requires access to location',
          message:
            'App needs access to your location' +
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
        this.setState({
          loading: false,
        });
        Alert.alert('Permission denied');
      }
    } catch (err) {
      this.setState({
        loading: false,
      });
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
    console.log('Search finish');
    this.setState({
      loading: false,
    });
  };
  _handleScanFinished = () => {
    console.log('Scan finish');
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
        readings: readings,
      });
    } else {
      console.log(readings.data);
      this.setState({
        readings: readings,
      });
    }
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
  }

  startSearch = () => {
    var config = {
      id: 214,
      first_name: 'john',
      dob: '08-Aug-1997',
      weight: 80,
      height: '160',
      gender: 'm',
      deviceType: DEVICE_TYPE.DEVICE_BLOOD_GLUCOSE,
    };
    medKit
      .initialize(config)
      .then((res) => {
        console.log('TCL: componentName -> componentDidMount -> res', res);
        if (!res.status) {
          // Alert.alert('Please turn on bluetooth');

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
              loading: true,
            });
            this.setState({
              devices: [],
            });
          })
          .catch((error) => {
            this.setState({
              loading: false,
            });
            console.log(
              'TCL: componentName -> componentDidMount -> error',
              error
            );
          });
      })
      .catch((error) => {
        this.setState({
          loading: false,
        });
        console.log(
          'TCL: componentName -> componentDidMount -> error11',
          error
        );
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

  renderBmiDetailsPopup() {
    const readingContainer = {
      alignItems: 'center',
      backgroundColor: '#E78491',
    };
    const readingText = {
      color: 'white',
      alignSelf: 'center',
      marginTop: 16,
    };

    return (
      <View style={[styles.container]}>
        <TouchableOpacity
          style={styles.container}
          activeOpacity={1}
          onPress={() => this.setState({ isDialogVisible: false })}
        >
          <View style={[styles.modal_container]}>
            <View style={styles.modal_body}>
              <View style={readingContainer}>
                <Text style={readingText}>
                  {JSON.stringify(this.state.readings)}
                </Text>
              </View>
            </View>
          </View>
        </TouchableOpacity>
      </View>
    );
  }

  scanDevices = () => {
    this.setState({
      loading: true,
    });

    if (Platform.OS === 'ios') {
      this.startSearch();
    } else {
      this.requestCameraPermission();
    }
  };

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
              style={{ width: '100%' }}
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
                      <Text>
                        {item.deviceName === 'HL158HC BLE' ||
                        item.deviceName === 'SFBPBLE'
                          ? 'Blood Pressure'
                          : item.deviceName === 'HL568HC BLE' ||
                            item.deviceName === 'SFBGBLE'
                          ? 'Glucose'
                          : 'Weight & BMI Scale'}
                      </Text>
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
              {this.state.readings ? this.renderBmiDetailsPopup() : null}
            </ScrollView>
          </View>
        </View>
      </>
    );
  }
}

export default ConnectScreen;
