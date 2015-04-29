package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageInfo;
import android.os.AsyncTask;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.webkit.WebView;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GooglePlayServicesUtil;
import com.google.android.gms.gcm.GoogleCloudMessaging;

import java.io.File;
import java.net.URLEncoder;
import java.util.TimeZone;
import java.util.UUID;

/**
 * Created by mdbranth on 5/7/14.
 */
public class Settings {
    private static Settings sSettings;
    private final static int PLAY_SERVICES_RESOLUTION_REQUEST = 9000;
    private static final String PROPERTY_APP_VERSION = "appVersion";
    private static final String PROPERTY_REG_ID = "registration_id";
    private static final String MIN_LENGTH_SECONDS = "server_minLengthSeconds";
    private static final String MAX_LENGTH_SECONDS = "server_maxLengthSeconds";
    private static final String USERID = "userID";
    private static final String TC_USERID = "tcUserId";
    private static final String SESSION_TOKEN = "sessionToken";
    private static final String CLIP_URL = "clipUrl";
    private static final String TEAM_ID = "server_teamid";
    private static final String CLIP_DIR = "TapClips";
    private static final String GALLERY_CLIP_DIR = "Gallery";

    public static final String S3_CLIP_BASE = "https://s3.amazonaws.com/tclip.tv/";
    public static final String APP_ID = "Android TC";
    public static final String REQUEST_SIGNATURE = "42";
    public static final String BASE_URL = "https://www.sprio.net";
    public static final String[] INSECURE_URLS = {"https://192.168.1.14:5000", "https://dev.sprio.net"};
    public static final String TAG = "SPRIO";

    private Context mContext;

    private Settings() {

        sSettings = this;
    }

    public static Settings get() {
        if (null == sSettings) sSettings = new Settings();
        return sSettings;
    }


    // Take care of getting push token / registering with API etc
    public void init(final Context context, final Activity activity) {
        mContext = context;

        new AsyncTask<String, Void, String>() {
            String mSessionId;
            String mAndroidComingSoonUrl;

            @Override
            protected String doInBackground(String... params) {
                final SharedPreferences prefs = getAppPreferences(context);
                SharedPreferences.Editor editor = prefs.edit();

                String regid = getRegistrationId(context);
                if (regid == null || regid == "") {
                    if (checkPlayServices(context, activity)) {
                        regid = register(activity);
                    }
                }

                // TODO: maybe be smart and not do this everytime?
                mSessionId = loginUser(regid);

                Api api = new Api();

                try {
                    Api.SettingsResponse response = (Api.SettingsResponse)api.MakeApiCall("/api/2.0/unauth/getAllSettings", null, Api.SettingsResponse.class);

                    if (response != null && response.response != null && null != response.response.tapClips) {
                        for (int i = 0; i < response.response.tapClips.length; i++) {
                            editor.putString("server_" + response.response.tapClips[i].id, response.response.tapClips[i].value);
                            if (response.response.tapClips[i].id.equals("androidComingSoonUrl")) {
                                mAndroidComingSoonUrl = response.response.tapClips[i].value;
                            }
                        }
                        Log.d(TAG, response.toString());
                    }
                } catch (Exception ex) {
                    Log.e(TAG, "Failed to get settings", ex);
                }

                editor.commit();

                return "";
            }

            @Override
            protected void onPostExecute(String msg) {

                try {
                    if (mSessionId == null) {
                        mSessionId = "";
                    }

                    if (mAndroidComingSoonUrl == null || mAndroidComingSoonUrl.equals("")) {
                        mAndroidComingSoonUrl = "http://tapclips.tumblr.com/";
                    }

                    mAndroidComingSoonUrl += (mAndroidComingSoonUrl.contains("?") ? "&" : "?");
                    mAndroidComingSoonUrl += "sessionToken=" + URLEncoder.encode(mSessionId, "UTF-8");

                    WebView w = (WebView) activity.findViewById(R.id.webView);
                    w.getSettings().setJavaScriptEnabled(true);
                    w.loadUrl(mAndroidComingSoonUrl);
                    w.setVisibility(View.VISIBLE);
                }
                catch (Exception ex) {

                }
            }
        }.execute(null, null, null);
    }

    // TODO: Decouple Settings and API, right now they both call each other
    public String loginUser(String regid) {
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
            return result.response.sessionToken;
        }

        return "";
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

    private String register(Context context) {
        String regid = null;
        try {
            GoogleCloudMessaging gcm = GoogleCloudMessaging.getInstance(context);
            regid = gcm.register("440395818928");
            storeRegistrationId(context, regid);
        } catch (Exception ex) {
            Log.d(TAG, "Exception getting token: ", ex);
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

    private static int getAppVersion(Context context) {
        try {
            PackageInfo packageInfo = context.getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0);
            return packageInfo.versionCode;
        } catch (Exception e) {
            // should never happen
            throw new RuntimeException("Could not get package name: " + e);
        }
    }

    private boolean checkPlayServices(Context context, Activity activity) {
        int resultCode = GooglePlayServicesUtil.isGooglePlayServicesAvailable(context);
        if (resultCode != ConnectionResult.SUCCESS) {
            if (GooglePlayServicesUtil.isUserRecoverableError(resultCode)) {
                GooglePlayServicesUtil.getErrorDialog(resultCode, activity,
                        PLAY_SERVICES_RESOLUTION_REQUEST).show();
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
