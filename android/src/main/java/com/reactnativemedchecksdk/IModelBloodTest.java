package com.reactnativemedchecksdk;

import android.os.Parcelable;


public interface IModelBloodTest<T> extends Parcelable {

    String getType();

    T getObject();

}
