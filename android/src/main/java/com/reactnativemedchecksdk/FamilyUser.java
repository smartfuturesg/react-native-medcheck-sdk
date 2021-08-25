package com.reactnativemedchecksdk;


import android.os.Parcel;
import android.os.Parcelable;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

public class FamilyUser implements Parcelable {

    public static final Creator<FamilyUser> CREATOR = new Creator<FamilyUser>() {
        @Override
        public FamilyUser createFromParcel(Parcel in) {
            return new FamilyUser(in);
        }

        @Override
        public FamilyUser[] newArray(int size) {
            return new FamilyUser[size];
        }
    };
    @SerializedName("id")
    @Expose
    private int id;
    @SerializedName("user_id")
    @Expose
    private int userId;
    @SerializedName("name")
    @Expose
    private String name;
    @SerializedName("dob")
    @Expose
    private String dob;
    @SerializedName("mobile_no")
    @Expose
    private String mobileNo;
    @SerializedName("weight")
    @Expose
    private String weight;
    @SerializedName("height")
    @Expose
    private String height;
    @SerializedName("profile_picture")
    @Expose
    private String profilePicture;
    @SerializedName("country_code")
    @Expose
    private String countryCode = "";
    @SerializedName("is_diabetics")
    @Expose
    private String isDiabetics;
    @SerializedName("gender")
    @Expose
    private String gender ="m";
    @SerializedName("waist")
    @Expose
    private String waist;

    public FamilyUser() {
    }

    protected FamilyUser(Parcel in) {
        id = in.readInt();
        userId = in.readInt();
        name = in.readString();
        dob = in.readString();
        mobileNo = in.readString();
        weight = in.readString();
        height = in.readString();
        profilePicture = in.readString();
        countryCode = in.readString();
        isDiabetics = in.readString();
        waist = in.readString();
        gender = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(id);
        dest.writeInt(userId);
        dest.writeString(name);
        dest.writeString(dob);
        dest.writeString(mobileNo);
        dest.writeString(weight);
        dest.writeString(height);
        dest.writeString(profilePicture);
        dest.writeString(countryCode);
        dest.writeString(isDiabetics);
        dest.writeString(waist);
        dest.writeString(gender);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getUserId() {
        return userId;
    }

    public void setUserId(int userId) {
        this.userId = userId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDob() {
        return dob;
    }

    public void setDob(String dob) {
        this.dob = dob;
    }

    public String getMobileNo() {
        return mobileNo;
    }

    public void setMobileNo(String mobileNo) {
        this.mobileNo = mobileNo;
    }

    public String getWeight() {
        return weight;
    }

    public void setWeight(String weight) {
        this.weight = weight;
    }

    public String getHeight() {
        return height;
    }

    public void setHeight(String height) {
        this.height = height;
    }

    public String getProfilePicture() {
        return profilePicture;
    }

    public void setProfilePicture(String profilePicture) {
        this.profilePicture = profilePicture;
    }

    public String getCountryCode() {
        return countryCode;
    }

    public void setCountryCode(String countryCode) {
        this.countryCode = countryCode;
    }

    public String getIsDiabetics() {
        return isDiabetics;
    }

    public void setIsDiabetics(String isDiabetics) {
        this.isDiabetics = isDiabetics;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public String getWaist() {
        return waist;
    }

    public void setWaist(String waist) {
        this.waist = waist;
    }

    @Override
    public String toString() {
        return name;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        FamilyUser that = (FamilyUser) o;

        if (id != that.id) return false;
        if (userId != that.userId) return false;
        if (name != null ? !name.equals(that.name) : that.name != null) return false;
        if (dob != null ? !dob.equals(that.dob) : that.dob != null) return false;
        if (mobileNo != null ? !mobileNo.equals(that.mobileNo) : that.mobileNo != null)
            return false;
        if (weight != null ? !weight.equals(that.weight) : that.weight != null) return false;
        if (height != null ? !height.equals(that.height) : that.height != null) return false;
        if (waist != null ? !waist.equals(that.waist) : that.waist != null) return false;
        if (gender != null ? !gender.equals(that.gender) : that.gender != null) return false;
        if (profilePicture != null ? !profilePicture.equals(that.profilePicture) : that.profilePicture != null)
            return false;
        if (countryCode != null ? !countryCode.equals(that.countryCode) : that.countryCode != null)
            return false;
        return isDiabetics != null ? isDiabetics.equals(that.isDiabetics) : that.isDiabetics == null;
    }

    @Override
    public int hashCode() {
        int result = id;
        result = 31 * result + userId;
        result = 31 * result + (name != null ? name.hashCode() : 0);
        result = 31 * result + (dob != null ? dob.hashCode() : 0);
        result = 31 * result + (mobileNo != null ? mobileNo.hashCode() : 0);
        result = 31 * result + (weight != null ? weight.hashCode() : 0);
        result = 31 * result + (height != null ? height.hashCode() : 0);
        result = 31 * result + (profilePicture != null ? profilePicture.hashCode() : 0);
        result = 31 * result + (countryCode != null ? countryCode.hashCode() : 0);
        result = 31 * result + (isDiabetics != null ? isDiabetics.hashCode() : 0);
        result = 31 * result + (waist != null ? waist.hashCode() : 0);
        result = 31 * result + (gender != null ? gender.hashCode() : 0);
        return result;
    }
}
