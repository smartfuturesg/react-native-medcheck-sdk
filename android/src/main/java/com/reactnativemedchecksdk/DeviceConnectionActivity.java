package com.reactnativemedchecksdk;

  import android.bluetooth.BluetoothDevice;
  import android.content.Context;
  import android.content.Intent;
  import android.os.Bundle;
  import android.text.TextUtils;
  import android.util.Log;
  import android.view.MenuItem;
  import android.view.View;
  import android.widget.Button;
  import android.widget.LinearLayout;
  import android.widget.TextView;
  import android.widget.Toast;

  import com.getmedcheck.lib.MedCheck;
  import com.getmedcheck.lib.MedCheckActivity;
  import com.getmedcheck.lib.constant.Constants;
  import com.getmedcheck.lib.events.EventClearCommand;
  import com.getmedcheck.lib.events.EventReadingProgress;
  import com.getmedcheck.lib.model.BleDevice;
  import com.getmedcheck.lib.model.BloodGlucoseData;
  import com.getmedcheck.lib.model.BloodPressureData;
  import com.getmedcheck.lib.model.IDeviceData;
  import com.getmedcheck.lib.utils.StringUtils;

  import java.text.DecimalFormat;
  import java.text.SimpleDateFormat;
  import java.util.ArrayList;
  import java.util.Locale;

  import no.nordicsemi.android.support.v18.scanner.ScanResult;

public class DeviceConnectionActivity extends MedCheckActivity implements View.OnClickListener {

  public static void start(Context context, BleDevice bleDevice) {
    Intent starter = new Intent(context, DeviceConnectionActivity.class);
    starter.putExtra("DATA", bleDevice);
    context.startActivity(starter);
  }

  private BleDevice mBleDevice;
  private TextView mTvDeviceName;
  private TextView mTvConnectionState;
  private Button mBtnConnect, mBtnReadData, mBtnClearData, mBtnTimeSync, mBtnDisconnect;
  private LinearLayout mLlCoreOperations, mLlBLEDeviceOperation;
  private TextView mTvResult;
  private boolean mAllPermissionsReady;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_device_connection);

    if (getIntent() != null && getIntent().hasExtra("DATA")) {
      mBleDevice = getIntent().getParcelableExtra("DATA");
    }
    initView();
    requestLocationPermission();
  }

  private void initView() {
    if (getSupportActionBar() != null) {
      getSupportActionBar().setDisplayHomeAsUpEnabled(true);
      getSupportActionBar().setDisplayShowHomeEnabled(true);
      if (mBleDevice != null && !TextUtils.isEmpty(mBleDevice.getDeviceName())) {
        getSupportActionBar().setTitle(mBleDevice.getDeviceName());
      } else {
        getSupportActionBar().setTitle("Device Connection");
      }
    }

    mTvDeviceName = findViewById(R.id.tvDeviceName);
    mTvConnectionState = findViewById(R.id.tvStatus);
    mLlCoreOperations = findViewById(R.id.llCoreOperations);
    mLlBLEDeviceOperation = findViewById(R.id.llBLEDeviceOperation);

    mBtnConnect = findViewById(R.id.btnConnect);
    mBtnConnect.setOnClickListener(this);
    mBtnReadData = findViewById(R.id.btnReadData);
    mBtnReadData.setOnClickListener(this);
    mBtnClearData = findViewById(R.id.btnClearData);
    mBtnClearData.setOnClickListener(this);
    mBtnTimeSync = findViewById(R.id.btnTimeSync);
    mBtnTimeSync.setOnClickListener(this);
    mBtnDisconnect = findViewById(R.id.btnDisconnect);
    mBtnDisconnect.setOnClickListener(this);

    mTvResult = findViewById(R.id.tvResult);

    if (mBleDevice != null) {
      mTvDeviceName.setText(mBleDevice.getDeviceName());
    }

    registerCallback();
  }

  @Override
  public boolean onOptionsItemSelected(MenuItem item) {
    if (item.getItemId() == android.R.id.home) {
      onBackPressed();
    }
    return super.onOptionsItemSelected(item);
  }

  @Override
  protected void onPermissionGrantedAndBluetoothOn() {
    mAllPermissionsReady = true;
    mLlCoreOperations.setVisibility(View.VISIBLE);
  }

  @Override
  protected void onDeviceClearCommand(int state) {
    super.onDeviceClearCommand(state);
    switch (state) {
      case EventClearCommand.CLEAR_START:
        mTvResult.setText("Clear Start");
        break;
      case EventClearCommand.CLEAR_COMPLETE:
        mTvResult.setText("Clear Successfully Completed");
        break;
      case EventClearCommand.CLEAR_FAIL:
        mTvResult.setText("Clear Fail");
        break;
    }
  }

  @Override
  protected void onDeviceConnectionStateChange(BleDevice bleDevice, int status) {
    super.onDeviceConnectionStateChange(bleDevice, status);
    if (bleDevice.getMacAddress().equals(mBleDevice.getMacAddress()) && status == 1) {
      mLlBLEDeviceOperation.setVisibility(View.VISIBLE);
    }
  }

  @Override
  protected void onDeviceDataReadingStateChange(int state, String message) {
    super.onDeviceDataReadingStateChange(state, message);
    mTvConnectionState.setText(message);
    mBtnConnect.setEnabled(!(state == EventReadingProgress.COMPLETED));
  }

  @Override
  protected void onDeviceDataReceive(BluetoothDevice device, ArrayList<IDeviceData> deviceData, String json, String deviceType) {
    super.onDeviceDataReceive(device, deviceData, json, deviceType);
    if (deviceData == null) {
      return;
    }

    Log.e("MedcheckJson", "onDeviceDataReceive: "+ json );

    if (deviceData.size() == 0) {
      mTvResult.setText("No Data Found!");
      return;
    }

    StringBuilder stringBuilder = new StringBuilder();
    stringBuilder.append("Type: ").append(deviceType).append("\n\n");
    SimpleDateFormat sdf = new SimpleDateFormat("dd-MM-yyyy HH:mm", Locale.ENGLISH);

    for (IDeviceData deviceDatum : deviceData) {

      if (deviceDatum.getType().equals(Constants.TYPE_BPM)) {
        BloodPressureData bloodPressureData = (BloodPressureData) deviceDatum;

        stringBuilder.append("SYS: ").append(bloodPressureData.getSystolic()).append(" mmHg, ");
        stringBuilder.append("DIA: ").append(bloodPressureData.getDiastolic()).append(" mmHg, ");
        stringBuilder.append("PUL: ").append(bloodPressureData.getHeartRate()).append(" min\n");
        stringBuilder.append("IHB: ").append(bloodPressureData.getIHB()).append(", ");
        stringBuilder.append("DATE: ").append(sdf.format(bloodPressureData.getDateTime()));
        stringBuilder.append("\n------------------------\n");

      } else if (deviceDatum.getType().equals(Constants.TYPE_BGM)) {
        BloodGlucoseData bloodGlucoseData = (BloodGlucoseData) deviceDatum;

        DecimalFormat df = new DecimalFormat("0.0");
        float val = 0;
        if (StringUtils.isNumber(bloodGlucoseData.getHigh())) {
          val = Float.parseFloat(bloodGlucoseData.getHigh()) / 18f;
        }

        stringBuilder.append(df.format(val)).append(" mmol/L (").append(bloodGlucoseData.getHigh()).append(" mg/dL)\n");
        stringBuilder.append(bloodGlucoseData.getAcPcStringValue()).append("\n");
        stringBuilder.append("DATE: ").append(sdf.format(bloodGlucoseData.getDateTime()));
        stringBuilder.append("\n------------------------\n");
      }

    }

    mTvResult.setText(stringBuilder.toString());

  }

  @Override
  public void onClick(View v) {
    switch (v.getId()) {
      case R.id.btnConnect:
        if (mAllPermissionsReady) {
          checkDeviceOnline();
        } else {
          Toast.makeText(this, "Some of the Permissions are missing", Toast.LENGTH_SHORT).show();
        }
        break;
      case R.id.btnReadData:
        readData();
        break;
      case R.id.btnClearData:
        clearData();
        break;
      case R.id.btnTimeSync:
        timeSync();
        break;
      case R.id.btnDisconnect:
        disconnectDevice();
        break;
    }
  }

  @Override
  protected void onDeviceScanResult(ScanResult scanResult) {
    super.onDeviceScanResult(scanResult);
  }


  private void connectDevice() {
    if (mBleDevice == null || !mAllPermissionsReady || TextUtils.isEmpty(mBleDevice.getMacAddress())) {
      return;
    } else {
      MedCheck.getInstance().connect(this, mBleDevice.getMacAddress());
    }
  }

  private void checkDeviceOnline() {
    if (mBleDevice == null || !mAllPermissionsReady || TextUtils.isEmpty(mBleDevice.getMacAddress())) {
      return;
    } else {
      connectDevice();
    }
  }

  private void readData() {
    if (mBleDevice == null || !mAllPermissionsReady || TextUtils.isEmpty(mBleDevice.getMacAddress())) {
      return;
    }
    MedCheck.getInstance().writeCommand(this, mBleDevice.getMacAddress());
  }

  private void clearData() {
    if (mBleDevice == null || !mAllPermissionsReady || TextUtils.isEmpty(mBleDevice.getMacAddress())) {
      return;
    }
    MedCheck.getInstance().clearDevice(this, mBleDevice.getMacAddress());
  }

  private void timeSync() {
    if (mBleDevice == null || !mAllPermissionsReady || TextUtils.isEmpty(mBleDevice.getMacAddress())) {
      return;
    }
    MedCheck.getInstance().timeSyncDevice(this, mBleDevice.getMacAddress());
  }

  private void disconnectDevice() {
    if (mBleDevice == null || !mAllPermissionsReady || TextUtils.isEmpty(mBleDevice.getMacAddress())) {
      return;
    }
    MedCheck.getInstance().disconnectDevice(this);
  }
}
