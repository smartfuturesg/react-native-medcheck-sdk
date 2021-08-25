package com.reactnativemedchecksdk;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;
import com.reactnativemedchecksdk.Ecgkit.DeviceData;

/**
 * Created by letsnurture on 18/4/18.
 */

public class DeviceDataBmiResponse implements DeviceData {

    @SerializedName("reading_id")
    @Expose
    private String readingId = "0";
    @SerializedName("bmi")
    @Expose
    private String bmi;
    @SerializedName("bmi_weight")
    @Expose
    private String bmiWeight;
    @SerializedName("reading_time")
    @Expose
    private String readingTime;

    @SerializedName("bone_mass")
    @Expose
    public String boneMass = "0";
    @SerializedName("water_per")
    @Expose
    public String waterPer = "0";
    @SerializedName("muscle_per")
    @Expose
    public String musclePer = "0";
    @SerializedName("fat_per")
    @Expose
    public String fatPer = "0";

    @SerializedName("bmr")
    @Expose
    public String bmr = "";

    @SerializedName("reading_notes")
    @Expose
    private String readingNotes = "";

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

    public String getReadingTime() {
        return readingTime;
    }

    public void setReadingTime(String readingTime) {
        this.readingTime = readingTime;
    }

    public String getReadingId() {
        return readingId;
    }

    public void setReadingId(String readingId) {
        this.readingId = readingId;
    }

    public String getBoneMass() {
        return boneMass;
    }

    public void setBoneMass(String boneMass) {
        this.boneMass = boneMass;
    }

    public String getWaterPer() {
        return waterPer;
    }

    public void setWaterPer(String waterPer) {
        this.waterPer = waterPer;
    }

    public String getMusclePer() {
        return musclePer;
    }

    public void setMusclePer(String musclePer) {
        this.musclePer = musclePer;
    }

    public String getFatPer() {
        return fatPer;
    }

    public void setFatPer(String fatPer) {
        this.fatPer = fatPer;
    }

    public String getBmr() {
        return bmr;
    }

    public void setBmr(String bmr) {
        this.bmr = bmr;
    }

    public String getReadingNotes() {
        return readingNotes;
    }

    public void setReadingNotes(String readingNotes) {
        this.readingNotes = readingNotes;
    }

    @Override
    public long getDateTime() {
        return DateTimeUtils.getTimeFromStringDate(Constants.DATE_TIME_FORMAT_RESPONSE, readingTime);
    }
}
