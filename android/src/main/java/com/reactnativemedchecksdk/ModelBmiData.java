package com.reactnativemedchecksdk;

import android.os.Parcel;
import android.os.Parcelable;
import android.text.TextUtils;

/**
 * Created by letsnurture on 18/4/18.
 */

public class ModelBmiData implements IModelBloodTest<ModelBmiData>, Parcelable {

    public static final Creator<ModelBmiData> CREATOR = new Creator<ModelBmiData>() {
        @Override
        public ModelBmiData createFromParcel(Parcel in) {
            return new ModelBmiData(in);
        }

        @Override
        public ModelBmiData[] newArray(int size) {
            return new ModelBmiData[size];
        }
    };
    private long id;
    private String bmi = "";
    private String bmiWeight = "";
    private long dateTime;
    private String fatPer = "";
    private String musclePer = "";
    private String bmr = "";
    private String waterPer = "";
    private String boneMass = "";
    private String userId = "";
    private String readingNotes = "";
    private String assignedUserId = "";

    public ModelBmiData() {
    }

    public ModelBmiData(DeviceDataBmiResponse deviceDataBmiResponse) {
        bmi = deviceDataBmiResponse.getBmi();
        bmiWeight = deviceDataBmiResponse.getBmiWeight();
        boneMass = deviceDataBmiResponse.getBoneMass();
        waterPer = deviceDataBmiResponse.getWaterPer();
        musclePer = deviceDataBmiResponse.getMusclePer();
        fatPer = deviceDataBmiResponse.getFatPer();
        bmr = deviceDataBmiResponse.getBmr();
        readingNotes = deviceDataBmiResponse.getReadingNotes();

        if (!TextUtils.isEmpty(deviceDataBmiResponse.getReadingTime())) {
//            this.dateTime = DateTimeUtils.getTimeFromStringDate(Constants.DATE_TIME_FORMAT_RESPONSE, new SimpleDateFormat(Constants.DATE_TIME_FORMAT_RESPONSE, Locale.ENGLISH).format(deviceDataBmiResponse.getReadingTime()));
            dateTime = DateTimeUtils.getTimeFromStringDate(Constants.DATE_TIME_FORMAT_RESPONSE, deviceDataBmiResponse.getReadingTime());
        }

        if (!TextUtils.isEmpty(deviceDataBmiResponse.getReadingId())) {
            id = Long.parseLong(deviceDataBmiResponse.getReadingId());
        }
    }

    protected ModelBmiData(Parcel in) {
        bmi = in.readString();
        bmiWeight = in.readString();
        boneMass = in.readString();
        waterPer = in.readString();
        musclePer = in.readString();
        fatPer = in.readString();
        bmr = in.readString();
        dateTime = in.readLong();
        id = in.readLong();
        assignedUserId = in.readString();
        userId = in.readString();
        readingNotes = in.readString();
    }

    @Override
    public String getType() {
        return BleConstants.TYPE_BMI;
    }

    @Override
    public ModelBmiData getObject() {
        return null;
    }


    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel parcel, int i) {
        parcel.writeString(bmi);
        parcel.writeString(bmiWeight);
        parcel.writeString(boneMass);
        parcel.writeString(waterPer);
        parcel.writeString(musclePer);
        parcel.writeString(fatPer);
        parcel.writeString(bmr);
        parcel.writeLong(dateTime);
        parcel.writeLong(id);
        parcel.writeString(assignedUserId);
        parcel.writeString(userId);
        parcel.writeString(readingNotes);
    }

    public String getBmi() {
        return bmi;
    }

    public void setBmi(String bmi) {
        this.bmi = bmi;
    }

    public String getBmiWeight() {
        return bmiWeight;
    }

    public void setBmiWeight(String bmiWeight) {
        this.bmiWeight = bmiWeight;
    }

    public String getFatPer() {
        return fatPer;
    }

    public void setFatPer(String fatPer) {
        this.fatPer = fatPer;
    }

    public String getMusclePer() {
        return musclePer;
    }

    public void setMusclePer(String musclePer) {
        this.musclePer = musclePer;
    }

    public String getWaterPer() {
        return waterPer;
    }

    public void setWaterPer(String waterPer) {
        this.waterPer = waterPer;
    }

    public String getBmr() {
        return bmr;
    }

    public void setBmr(String bmr) {
        this.bmr = bmr;
    }

    public String getBoneMass() {
        return boneMass;
    }

    public void setBoneMass(String boneMass) {
        this.boneMass = boneMass;
    }

    public long getDateTime() {
        return dateTime;
    }

    public void setDateTime(long dateTime) {
        this.dateTime = dateTime;
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getAssignedUserId() {
        return assignedUserId;
    }

    public void setAssignedUserId(String assignedUserId) {
        this.assignedUserId = assignedUserId;
    }

    public String getReadingNotes() {
        return readingNotes;
    }

    public void setReadingNotes(String readingNotes) {
        this.readingNotes = readingNotes;
    }
}
