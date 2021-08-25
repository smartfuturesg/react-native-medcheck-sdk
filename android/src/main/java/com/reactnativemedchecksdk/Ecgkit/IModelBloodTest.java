package com.reactnativemedchecksdk.Ecgkit;

import android.os.Parcelable;


public interface IModelBloodTest<T> extends Parcelable {

    String getType();

    T getObject();

}
