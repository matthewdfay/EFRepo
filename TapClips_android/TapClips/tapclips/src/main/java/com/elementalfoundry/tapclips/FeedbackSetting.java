package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.content.Intent;

/**
 * Created by mdbranth on 5/8/14.
 */
public class FeedbackSetting extends Setting {
    public FeedbackSetting() {
        super(R.drawable.icon_email, "Feedback");
    }

    @Override
    public void performAction(Activity context) {
        Intent intent = new Intent(Intent.ACTION_SEND);
        intent.setType("plain/text");
        intent.putExtra(Intent.EXTRA_EMAIL, new String[] { "support@tapclips.com" });
        intent.putExtra(Intent.EXTRA_SUBJECT, "TapClips Support");
        intent.putExtra(Intent.EXTRA_TEXT,
                "User Id = " +
                        Settings.get().getUserId() +
                        "\nApp Version = " + Settings.getAppVersion(context) + "\r\n\r\n");
        context.startActivity(Intent.createChooser(intent, ""));
    }
}
