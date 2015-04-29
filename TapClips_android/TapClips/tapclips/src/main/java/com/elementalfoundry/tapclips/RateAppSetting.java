package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;

/**
 * Created by mdbranth on 6/6/14.
 */
public class RateAppSetting extends Setting {
    public RateAppSetting() {
        super(R.drawable.icon_rate, "Rate the App");
    }

    @Override
    public void performAction(Activity context) {
        String packageName = context.getPackageName();

        Uri uri = Uri.parse("market://details?id=" + packageName);
        Intent goToMarket = new Intent(Intent.ACTION_VIEW, uri);
        try {
            context.startActivity(goToMarket);
        } catch (ActivityNotFoundException e) {
            context.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("http://play.google.com/store/apps/details?id=" + packageName)));
        }
    }
}
