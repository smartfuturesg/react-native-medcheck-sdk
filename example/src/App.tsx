import * as React from 'react';

import { StyleSheet, View, Text } from 'react-native';
import MedcheckSdk from 'react-native-medcheck-sdk';

import ConnectScreen from './ConnectScreen';

const medKit = new MedcheckSdk();
export default function App() {
  const [result, setResult] = React.useState<number | undefined>();

  // React.useEffect(() => {}, []);
  return <ConnectScreen />;
  return (
    <View style={styles.container}>
      <Text>Result: {result}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  box: {
    width: 60,
    height: 60,
    marginVertical: 20,
  },
});
