package com.elementalfoundry.tapclips;

import android.app.Activity;

/**
 * Created by mdbranth on 5/9/14.
 */
public class ToggleSetting extends Setting {
    private String mActiveDisplayString;
    private int mActiveIconId;
    private boolean mSet;

    public ToggleSetting(int iconId, int activeIconId, String displayString, String activeDisplayString, boolean set) {
        super(iconId, displayString);
        mActiveDisplayString = activeDisplayString;
        mActiveIconId = activeIconId;
        mSet = set;
    }

    public String getActiveDisplayString() {
        return mActiveDisplayString;
    }

    public int getActiveIconId() {
        return mActiveIconId;
    }

    public Boolean getSet() {
        return mSet;
    }

    public void setSet(boolean value) {
        mSet = value;
    }

    @Override
    public void performAction(Activity context) {
        super.performAction(context);
        mSet = !mSet;
    }
}
