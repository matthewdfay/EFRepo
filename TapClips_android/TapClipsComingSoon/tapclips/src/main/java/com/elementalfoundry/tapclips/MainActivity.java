package com.elementalfoundry.tapclips;

import android.os.Bundle;
import android.support.v4.app.FragmentActivity;
import android.util.Log;

public class MainActivity extends FragmentActivity {

    private static String TAG = "SPRIO";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d(TAG, "*** onCreate");
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Settings.get().init(getApplicationContext(), this);
    }

}
