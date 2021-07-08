import { NativeModules } from 'react-native';

type MedcheckSdkType = {
  multiply(a: number, b: number): Promise<number>;
};

const { MedcheckSdk } = NativeModules;

export default MedcheckSdk as MedcheckSdkType;
