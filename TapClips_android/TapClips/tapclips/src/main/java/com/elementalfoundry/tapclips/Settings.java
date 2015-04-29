package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.os.AsyncTask;
import android.os.Environment;
import android.util.Log;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.gcm.GoogleCloudMessaging;
import com.google.gson.internal.LinkedTreeMap;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.TimeZone;
import java.util.UUID;

/**
 * Created by mdbranth on 5/7/14.
 */
public class Settings {
    private static Settings sSettings;
    private ArrayList<TCListItem> mSettingsArray;
    private final static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;
    private static final String PROPERTY_APP_VERSION = "appVersion";
    private static final String PROPERTY_REG_ID = "registration_id";
    private static final String MIN_LENGTH_SECONDS = "server_minLengthSeconds";
    private static final String MAX_LENGTH_SECONDS = "server_maxLengthSeconds";
    private static final String DEFAULT_LENGTH_SECONDS = "server_defaultLengthSeconds";
    private static final String POST_TAP_DELAY_MS = "server_postTapDelayMS";
    private static final String ANDROID_EXPLORE_URL = "server_androidExploreUrl";
    private static final String DEFAULT_SHARE_TEXT = "server_defaultShareText";
    private static final String USERID = "userID";
    private static final String TC_USERID = "tcUserId";
    private static final String SESSION_TOKEN = "sessionToken";
    private static final String CLIP_URL = "clipUrl";
    private static final String TEAM_ID = "server_teamid";
    private static final String CLIP_DIR = "TapClips";
    private static final String ACCEPTED_TERMS_AND_CONDITIONS = "acceptedTermsAndConditions";
    private static final String NUM_CLIPS_SAVED = "numClipsSaved";

    public static final String S3_CLIP_BASE = "https://s3.amazonaws.com/tclip.tv/";
    public static final String APP_ID = "Android TC";
    public static final String REQUEST_SIGNATURE = "42";
    public static final String BASE_URL = "https://api.tapclips.com";
    public static final String[] INSECURE_URLS = {"https://192.168.1.11:5000", "https://dev.sprio.net"};
    public static final String TAG = "SPRIO";

    private Context mContext;
    private HashMap<String, String> typeaheads = new HashMap<String, String>();

    private Settings() {
        mSettingsArray = new ArrayList<TCListItem>();
        mSettingsArray.add(new MoveAllVideosSetting());
        mSettingsArray.add(new Subtitle("Support"));
        mSettingsArray.add(new RateAppSetting());
        mSettingsArray.add(new FeedbackSetting());
        sSettings = this;
    }

    public static Settings get() {
        if (null == sSettings) sSettings = new Settings();
        return sSettings;
    }

    public ArrayList<TCListItem> getArray() {
        return mSettingsArray;
    }

    // Take care of getting push token / registering with API etc
    public void init(final Context context, final Activity activity) {
        mContext = context;

        new AsyncTask<String, Void, String>() {
            HashMap<String, String> mTypeAheads = new HashMap<String, String>();

            @Override
            protected String doInBackground(String... params) {
                final SharedPreferences prefs = getAppPreferences(context);
                SharedPreferences.Editor editor = prefs.edit();

                // Uncomment this once we have a project ID for GCM for tapclips
                String regid = getRegistrationId(context);
                if (regid == null || regid == "") {
                    if (checkPlayServices(context, activity)) {
                        regid = register(activity);
                    }
                }

                // TODO: maybe be smart and not do this everytime?
                loginUser(regid);

                Api api = new Api();

                try {
                    Api.GetSettingsResponse settingsResponse = (Api.GetSettingsResponse)api.MakeApiCall("/api/2.0/getAllInfo", new Api.GetSettingsParams(), Api.GetSettingsResponse.class);
                    if (settingsResponse != null && settingsResponse.success) {
                        LinkedTreeMap<String, LinkedTreeMap<String, String>> typeAheads = (LinkedTreeMap<String, LinkedTreeMap<String, String>>)settingsResponse.response.settings.tapClipsTypeaheads;
                        for (String key : typeAheads.keySet()) {
                            LinkedTreeMap<String, String> value = typeAheads.get(key);
                            mTypeAheads.put(key, value.get("replace"));
                        }

                        for (int i = 0; i < settingsResponse.response.settings.tapClips.length; i++) {
                            editor.putString("server_" + settingsResponse.response.settings.tapClips[i].id, settingsResponse.response.settings.tapClips[i].value);
                        }
                    }
                    Log.d(TAG, settingsResponse.toString());
                } catch (Exception ex) {
                    Log.e(TAG, "Failed to get settings", ex);
                }

                ShareUrlManager.get().getShareUrl(null);

                editor.commit();
                return "";
            }

            @Override
            protected void onPostExecute(String msg) {
                typeaheads = mTypeAheads;
            }
        }.execute(null, null, null);
    }

    // TODO: Decouple Settings and API, right now they both call each other
    public void loginUser(String regid) {
        String userId = getUserId();
        String timezone = TimeZone.getDefault().getID();

        Api.LoginParams params = new Api.LoginParams(userId, timezone);
        params.token = regid;
        Api api = new Api();
        Api.LoginResponse result = (Api.LoginResponse)api.MakeApiCall("/api/2.0/unauth/loginUser", params, Api.LoginResponse.class);

        if (null != result &&
                null != result.response &&
                null != result.response.userId &&
                "" != result.response.userId &&
                null != result.response.sessionToken &&
                "" != result.response.sessionToken) {
            final SharedPreferences prefs = getAppPreferences(mContext);
            SharedPreferences.Editor editor = prefs.edit();
            editor.putString(TC_USERID, result.response.userId);
            editor.putString(SESSION_TOKEN, result.response.sessionToken);
            editor.commit();
        }
    }

    public File getClipDir() {
        if (!Environment.getExternalStorageState().equalsIgnoreCase(Environment.MEDIA_MOUNTED)) {
            return  null;
        }

        return mContext.getExternalFilesDir(null);
    }

    public File getGalleryClipDir() {
        if (!Environment.getExternalStorageState().equalsIgnoreCase(Environment.MEDIA_MOUNTED)) {
            return  null;
        }

        File result = new File(Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_PICTURES), CLIP_DIR);

        if (!result.exists()) {
            result.mkdir();
        }

        return result;
    }

    public boolean getAcceptedTermsAndConditions() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        boolean value = prefs.getBoolean(ACCEPTED_TERMS_AND_CONDITIONS, false);
        return value;
    }

    public void acceptTermsAndConditions() {
        SharedPreferences prefs = getAppPreferences(mContext);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putBoolean(ACCEPTED_TERMS_AND_CONDITIONS, true);
        editor.commit();
    }

    // Used for testing to get fresh tapclips user
    public void clearUserId() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(USERID, "");
        editor.commit();
    }

    public String getUserId() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(USERID, "");
        if ("" == value) {
            SharedPreferences.Editor editor = prefs.edit();
            value = UUID.randomUUID().toString();
            editor.putString(USERID, value);
            editor.commit();
        }

        return value;
    }

    public String getTcUserId() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(TC_USERID, "");
        return value;
    }

    public String getTeamId() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(TEAM_ID, "kPnrUhwMXR000005");
        return value;
    }

    public String getExploreUrl() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(ANDROID_EXPLORE_URL, "http://tclip.tv/x/android?t=1");
        return value;
    }

    public String getDefaultShareText() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        return prefs.getString(DEFAULT_SHARE_TEXT, "");
    }

    public int getMinLengthSeconds() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(MIN_LENGTH_SECONDS, "3");

        int result;

        try {
            result = Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            result = 3;
        }

        return result;
    }

    public int getMaxLengthSeconds() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(MAX_LENGTH_SECONDS, "15");

        int result;

        try {
            result = Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            result = 15;
        }

        return result;
    }

    public int getDefaultLengthSeconds() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(DEFAULT_LENGTH_SECONDS, "8");

        int result;

        try {
            result = Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            result = 8;
        }

        return result;
    }

    public int getDefaultPostTapDelayMs() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        String value = prefs.getString(POST_TAP_DELAY_MS, "500");

        int result;

        try {
            result = Integer.parseInt(value);
        } catch (NumberFormatException ex) {
            result = 500;
        }

        return result;
    }

    public int getNumTapClipsTaken() {
        final SharedPreferences prefs = getAppPreferences(mContext);
        int value = prefs.getInt(NUM_CLIPS_SAVED, 0);
        return value;
    }

    public void incrementNumTapClipsTaken() {
        int currValue = getNumTapClipsTaken();
        currValue++;

        final SharedPreferences prefs = getAppPreferences(mContext);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putInt(NUM_CLIPS_SAVED, currValue);
        editor.commit();
    }

    public void setSessionToken(String token) {
        SharedPreferences prefs = getAppPreferences(mContext);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(SESSION_TOKEN, token);
        editor.commit();
    }

    public String getSessionToken() {
        SharedPreferences prefs = getAppPreferences(mContext);
        String sessionToken = prefs.getString(SESSION_TOKEN, "");
        return sessionToken;
    }

    public String getClipUrl() {
        SharedPreferences prefs = getAppPreferences(mContext);
        String clipUrl = prefs.getString(CLIP_URL, "");
        return clipUrl;
    }

    public void setClipUrl(String value) {
        SharedPreferences prefs = getAppPreferences(mContext);
        SharedPreferences.Editor editor = prefs.edit();

        editor.putString(CLIP_URL, value);
        editor.commit();
    }

    public HashMap<String, String> getTypeaheads() {
        return typeaheads;
    }

    private String register(Context context) {
        String regid = null;
        try {
            GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(context);
            regid = gcm.register("440395818928");
            storeRegistrationId(context, regid);
        } catch (Exception ex) {
        }

        return regid;
    }


    private String getRegistrationId(Context context) {
        final SharedPreferences prefs = getAppPreferences(context);
        String registrationId = prefs.getString(PROPERTY_REG_ID, "");
        if (registrationId == null || registrationId == "") {
            return "";
        }
        // Check if app was updated; if so, it must clear the registration ID
        // since the existing regID is not guaranteed to work with the new
        // app version.
        int registeredVersion = prefs.getInt(PROPERTY_APP_VERSION, Integer.MIN_VALUE);
        int currentVersion = getAppVersion(context);
        if (registeredVersion != currentVersion) {
            return "";
        }
        return registrationId;
    }

    private SharedPreferences getAppPreferences(Context context) {
        // This sample app persists the registration ID in shared preferences, but
        // how you store the regID in your app is up to you.
        return context.getSharedPreferences(MainActivity.class.getSimpleName(),
                Context.MODE_PRIVATE);
    }

    public static int getAppVersion(Context context) {
        try {
            PackageInfo packageInfo = context.getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0);
            return packageInfo.versionCode;
        } catch (Exception e) {
            // should never happen
            throw new RuntimeException("Could not get package name: " + e);
        }
    }

    private boolean checkPlayServices(Context context, final Activity activity) {
        final int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(context);
        if (resultCode != ConnectionResult.SUCCESS) {
            if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        GooglePlayServicesUtil.getErrorDialog(resultCode, activity,
                                PLAY_SERVICES_RESOLUTION_REQUEST).show();
                    }
                });
            } else {
                // TODO: Display message about device not supported
                activity.finish();
            }
            return false;
        }
        return true;
    }

    private void storeRegistrationId(Context context, String regId) {
        final SharedPreferences prefs = getAppPreferences(context);
        int appVersion = getAppVersion(context);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(PROPERTY_REG_ID, regId);
        editor.putInt(PROPERTY_APP_VERSION, appVersion);
        editor.commit();
    }
}
