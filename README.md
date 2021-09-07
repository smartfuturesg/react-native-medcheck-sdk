# react-native-medcheck-sdk

Wrapper for medchecksdk

## Installation

```sh
npm install https://github.com/smartfuturesg/react-native-medcheck-sdk.git --save
```

## Usage

```js
import MedcheckSdk from 'react-native-medcheck-sdk';

// ...
// Pass device type to scan that device type
DEVICE_BLOOD_PRESSURE: 1,
DEVICE_BLOOD_GLUCOSE: 2,
DEVICE_BODY_MASS_INDEX: 3,

const result = await MedcheckSdk.startScan();
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT
