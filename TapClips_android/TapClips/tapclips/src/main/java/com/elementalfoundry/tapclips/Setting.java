package com.elementalfoundry.tapclips;

/**
 * Created by mdbranth on 5/7/14.
 */
public class Setting extends TCListItem {
    private int mIconId;
    private String mDisplayString;

    public Setting(int iconId, String displayString) {
        mIconId = iconId;
        mDisplayString = displayString;
    }

    public int getIconId() {
        return mIconId;
    }

    public String getDisplayString() {
        return mDisplayString;
    }
}
