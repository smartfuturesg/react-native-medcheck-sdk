import { NativeModules, NativeEventEmitter } from 'react-native';
import type { UserDetails, WScaleUser } from './UserDetails';
import { EventEmitter } from 'events';

export interface WScaleDevice {
  id: string;
  deviceId: string;
  deviceSn: string;
  deviceType: string;
  modelNumber: string;
  peripheralIdentifier: string;
  deviceName: string;
  state: string;
}

export interface UserType {
  username: string;
  key: string;
}

export interface Reading {
  device_data: {
    bmi: String;
    bmi_weight: String;
    bmr: String;
    bone_mass: String;
    fat_per: String;
    muscle_per: String;
    water_per: String;
  };
  device_id: String;
  is_manual: String;
  reading_notes: String;
  reading_time: String;
  user_family_id: String;
  user_id: String;
}

export interface Device {
  id: number;
  address: string;
  name: string;
  state: number;
  modelName: string;
  manufacturer: string;
}

export type DATA = 'data';
export type DEVICE_FOUND = 'deviceFound';
export type DEVICE_CONNECTED = 'deviceConnected';
export type DEVICE_DISCONNECTED = 'deviceDisconnected';
export type AMBIGUOUS_DEVICE_FOUND = 'ambiguousDeviceFound';
export type SCAN_FINISHED = 'scanFinished';
export type COLLECTION_FINISHED = 'collectionFinished';
export type USER_LIST_FOUND = 'userListFound';

export type DEVICE_EVENTS =
  | DEVICE_FOUND
  | DEVICE_CONNECTED
  | DEVICE_DISCONNECTED
  | AMBIGUOUS_DEVICE_FOUND;
export type STATE_EVENTS = SCAN_FINISHED | COLLECTION_FINISHED;
export type USER_LIST_EVENTS = USER_LIST_FOUND;
export type EVENTS = DATA | DEVICE_EVENTS | STATE_EVENTS | USER_LIST_EVENTS;

// type MedcheckSdkType = {
//   initialize(user: UserDetails): Promise<object>;
//   startScan(): Promise<void>;
//   stopScan(): Promise<void>;
//   stopReceivingData(): Promise<void>;
//   connectToDevice(uuid: string): Promise<void>;
//   disconnectFromDevice(uuid: string): Promise<void>;
//   pairUser(user: WScaleUser): Promise<void>;
//   startCollection(): Promise<void>;
//   findPeriphral(): Promise<void>;
// };

interface MedcheckSdk {
  on(event: DATA, fn: (reading: Reading) => void): this;
  on(event: DEVICE_EVENTS, fn: (device: WScaleDevice) => void): this;
  on(event: USER_LIST_EVENTS, fn: (userList: [UserType]) => void): this;
  on(event: STATE_EVENTS, fn: () => void): this;
  once(event: DATA, fn: (reading: Reading) => void): this;
  once(event: DEVICE_EVENTS, fn: (device: Device) => void): this;
  once(event: USER_LIST_EVENTS, fn: (userList: [UserType]) => void): this;
  once(event: STATE_EVENTS, fn: () => void): this;
  emit(event: DATA, data: Reading): boolean;
  emit(event: DEVICE_EVENTS, data: Device): boolean;
  emit(event: USER_LIST_EVENTS, fn: (userList: [UserType]) => void): this;
  emit(event: STATE_EVENTS): boolean;
  removeListener(event: EVENTS, fn: (...args: any[]) => void): this;
  removeAllListeners(event: EVENTS): this;
}

const medcheckModule = NativeModules.MedcheckSdk;
const eventEmitter = new NativeEventEmitter(medcheckModule);
const { EVENTS } = medcheckModule;

class MedcheckSdk extends EventEmitter {
  constructor() {
    super();

    for (const e of EVENTS) {
      eventEmitter.addListener(e, (d) => {
        d !== null ? this.emit(e, d) : this.emit(e);
      });
    }
  }

  public initialize(user: UserDetails): Promise<void> {
    return medcheckModule.initialize(user);
  }

  public stopScan(): Promise<void> {
    return medcheckModule.stopScan();
  }

  public stopReceivingData(): Promise<void> {
    return medcheckModule.stopReceivingData();
  }

  public startScan(): Promise<void> {
    return medcheckModule.startScan();
  }

  public connectToDevice(device: WScaleDevice): Promise<void> {
    return medcheckModule.connectToDevice(device.deviceName);
  }

  public disconnectFromDevice(device: Device): Promise<void> {
    return medcheckModule.disconnectFromDevice(device.id);
  }

  public pairUser(user: WScaleUser): Promise<void> {
    return medcheckModule.pairUser(user);
  }

  public startCollection(): Promise<void> {
    return medcheckModule.startCollection();
  }

  public clearCollection(): Promise<void> {
    return medcheckModule.clearCollection();
  }

  public timeSyncBPMDevice(): Promise<void> {
    return medcheckModule.timeSyncBPMDevice();
  }

  public findPeriphral() {
    return medcheckModule.findPeriphral();
  }
}

export default MedcheckSdk;
// export default MedcheckSdk as MedcheckSdkType;
