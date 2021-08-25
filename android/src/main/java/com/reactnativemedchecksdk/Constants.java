package com.reactnativemedchecksdk;

import java.util.Calendar;

/**
 * Created by ln-168 on 1/8/17.
 */

public class Constants {

    public final static long TIME_OUT_TIME = 3000;

    public static final String DEVICE_TYPE_ANDROID = "2";

    public static final String ROLE_ID_DOCTOR = "2";
    public static final String ROLE_ID_USER = "3";
    public static final String ROLE_ID_STAFF = "5";

    public static final String SUCCESS = "1";
    public static final String FAILURE = "0";

    public static final String YES = "Y";
    public static final String NO = "N";

    public static final String BLOOD_PRESSURE = "Blood Pressure";
    public static final String GLUCOSE = "Glucose";
    public static final String BMI = "Weight and BMI";//Weight and
    public static final String ECG = "Ecg";
    public static final String SPO2 = "Spo2";
    public static final String TEMP = "Temp";
    public static final String WELLNESS_SCORE_ZERO= "0.0";



    public final static String MIME_TYPE_PDF = "application/pdf";
    public final static String MIME_TYPE_CSV = "text/csv";

    public static final String DOCTOR_REQUEST_PENDING = "1";
    public static final String DOCTOR_REQUEST_ACCEPTED = "2";
    public static final String DOCTOR_REQUEST_DECLINED = "3";

    public static final String[] month = new String[]{"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
    public static final String[] days = new String[]{"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    public static final String[] daysFullName = new String[]{"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};
    public static final Integer[] daysOfWeek = new Integer[]{Calendar.SUNDAY, Calendar.MONDAY, Calendar.TUESDAY,
            Calendar.WEDNESDAY, Calendar.THURSDAY, Calendar.FRIDAY, Calendar.SATURDAY};

    public final static String BLE_STATUS_NONE = "None";
    public final static String BLE_STATUS_CONNECTED = "Connected";

    public final static String USER_PREFERENCE = "UserPreference";
    public final static String END_USER_PREFERENCE = "EndUserPreference";
    public final static String DEVICE_FCM_TOKEN = "device_fcm_token";

    //public final static String DATE_TIME_FORMAT_BGM = "dd-MM-yy hh:mm a";
    public final static String DATE_TIME_FORMAT_LOCAL = "dd-MM-yyyy hh:mm a";
    public final static String DATE_TIME_FORMAT_CHART = "dd-MMM-yyyy hh:mm a";
    public final static String DATE_TIME_FORMAT_CSV = "dd-MM-yyyy_hh:mm_a";

    public final static String DATE_FORMAT_DOB_MONTH_YEAR_ONLY = "MMM-yyyy";

    public final static String DATE_FORMAT_DOB = "dd-MMM-yyyy";
    public final static String TIME_FORMAT = "hh:mm a";

    public final static String DATE_FORMAT_DAILY = "dd-MMM-yyyy";
    public final static String DATE_FORMAT_WEEKLY = "w-yyyy";
    public final static String DATE_FORMAT_MONTHLY = "MMM-yyyy";

    public final static String DAILY = "Daily";
    public final static String WEEKLY = "Weekly";
    public final static String MONTHLY = "Monthly";
    public final static String ALL_DATA = "All Data";

    public final static String DATE_FORMAT_DAILY_CHART = "dd-MMM-yyyy";
    public final static String DATE_FORMAT_WEEKLY_CHART = "'Week' w\nyyyy";
    public final static String DATE_FORMAT_MONTHLY_CHART = "MMM-yyyy";
    public final static String DATE_FORMAT_ALL_DATA_CHART = "dd-MMM-yy\nhh:mm a";

    public final static String DATE_TIME_FORMAT_REQUEST = "dd-MMM-yyyy HH:mm";
    public final static String DATE_TIME_FORMAT_RESPONSE = "dd-MMM-yyyy hh:mm a";
    public static final String SELECTED_LANGUAGE = "selected_lang";
    public static final String IS_RESOURCE_BUNDLE_LOADED = "is_resource_bundle_loaded";

    public static final String QUESTION_TYPE_TEXT = "text";
    public static final String QUESTION_TYPE_RADIO = "radio";
    public static final String QUESTION_TYPE_CHECKBOX = "checkbox";
    public static final String QUESTION_TYPE_DROPDOWN = "dropdown";

    public static final String GENDER_MALE = "m";
    public static final String GENDER_ATHELET_MALE = "am";
    public static final String GENDER_FEMALE = "f";
    public static final String GENDER_ATHELET_FEMALE = "af";

    public final static String AGE = "age";
    public final static String HEIGHT = "height";
    public final static String MACADDRESS = "macaddress";
    public final static String GENDER = "gender";
    public final static String LANGAUGE = "langauge";
    public final static String COMPANYID = "companyId";
    public static boolean EcgChartFrom = true;//to check ecg

  public static final int USER_ROLE = 3;
  public static final int CONSULTANT_ROLE = 2;

  public static final String CHECK_ME = "Checkme";
  public static final String MED_CHECK = "MedCheck";

  public static final String CONSULTANT_TYPE = "1";

  public final static String IS_OPEN_FIRST_TIME = "is_open_first_time";
  public final static String IS_APP_KILLED = "is_app_killed";
  public final static String IS_CALL_CANCELLED_PREVIOUSLY = "is_call_cancelled_previously";

  public final static String LAST_NOTIFICATION = "last_notification";
  public final static String USER_ADDRESS = "user_address";
  public final static String PATIENT_ID = "PATIENT_ID";
  public final static String CONSULTANT_ID = "CONSULTANT_ID";
  public final static String WALLET_BALANCE = "WALLET_BALANCE";
  public final static String SLEEP_ANSWERES = "SLEEP_ANSWERES";
  public final static String CALL_RATE = "CALL_RATE";
  public final static String START_TIME = "START_TIME";
  public final static String DATA_SHARED = "DATA_SHARED";

  public final static String CONSULTANT_AVAILABLE = "1";
  public final static String CONSULTANT_UNAVAILABLE = "0";

  public final static String FITBIT_LUANCH_DATE = "2017-09-25";
  public final static String FITBIT = "fitbit";
  public final static String GOOGLE_FIT = "googleFit";

    public interface EXTRAS {
        String DATA = "DATA";
        String ROLE = "ROLE";
        String DEVICE_ADDRESS = "DEVICE_ADDRESS";
        String DOCTOR_ID = "DOCTOR_ID";
        String IS_ADD = "IS_ADD";
        String DOCTOR_DATA = "DOCTOR_DATA";
        String QUESTION_OBJECT = "QUESTION OBJECT";
        String PATIENT_ID = "PATIENT_ID";
        String DEVICE_TYPE = "DEVICE_TYPE";
        String WEIGHT_DATA_A3 = "WEIGHTDATA_A3";
        String HEADER = "HEADER";
        String URL = "URL";
        String PDFURL = "PDF_URL";
        String TITLE = "TITLE";
        String MESSAGE = "MESSAGE";
        String REMINDER = "REMINDER";
        String COLOR = "COLOR";

        String PRODUCT_ID = "PRODUCT_ID";
        String PRODUCT_TYPE = "PRODUCT_TYPE";
        String IS_FROM_CONSULTANT = "IS_FROM_CONSULTANT";
        String ANSWER_OBJECT = "ANSWER OBJECT";

        String EXTRA_DISABLE_BACK = "DISABLE_BACK";
        String EXTRA_CALLER_NAME = "EXTRA_CALLER_NAME";
        String EXTRA_CALLER_PROFILE_PIC = "EXTRA_CALLER_PROFILE_PIC";
        String EXTRA_CONSULTANT_ID = "EXTRA_CONSULTANT_ID";

        String EXTRA_CALL_ID = "EXTRA_CALL_ID";
    }

    public interface RequestCode {
      // permission
      int REQUEST_CODE_CONTACTS_PERMISSION = 100;
      int REQUEST_CODE_LOCATION_PERMISSION = 101;
      int REQUEST_CODE_CAMERA_PERMISSION = 102;
      int REQUEST_CODE_GALLERY_PERMISSION = 103;
      int REQUEST_CODE_STORAGE_PERMISSION = 104;

      // activity for start result
      int REQUEST_CODE_OPEN_SETTING = 50;
      int REQUEST_CODE_ENABLE_BLUETOOTH = 51;
      int REQUEST_CODE_DEVICE_CONNECT = 52;
      int REQUEST_CODE_ENABLE_LOCATION = 53;
      int REQUEST_CODE_OPEN_SETTING_CAMERA = 54;
      int REQUEST_CODE_OPEN_SETTING_STORAGE = 55;

      int REQUEST_CODE_CAMERA = 56;
      int REQUEST_CODE_GALLERY = 57;
      int REQUEST_CODE_CROP_IMAGE = 58;

      int REQUEST_CODE_ADD_CONTACT = 59;
      int REQUEST_CODE_ADD_DOCTOR = 60;
      int REQUEST_CODE_UPDATE_DETAILS = 61;
      int REQUEST_CODE_ASSIGN_READING_TO_USER = 62;
      int REQUEST_CODE_ADD_REMINDER = 63;
      int REQUEST_CODE_ADD_USER = 64;
      int REQUEST_CODE_MOVE_TO_USER_READING_ACTIVITY = 65;
      int REQUEST_CODE_EDIT_DOCTOR_PROFILE = 66;
      int REQUEST_CODE_PLACE_PICKER = 67;
      int REQUEST_CODE_MANUAL_READING_ADDED = 68;
      int REQUEST_OAUTH_REQUEST_GOOGLE_FIT_CODE = 1001;
  }
}
