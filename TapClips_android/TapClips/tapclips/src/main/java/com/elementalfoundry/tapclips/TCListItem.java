package com.elementalfoundry.tapclips;

import android.app.Activity;

/**
 * Created by mdbranth on 5/7/14.
 */
public class TCListItem {
    private String mName;

    public TCListItem() {
        mName = "";
    }

    public TCListItem(String name) {
        mName = name;
    }

    @Override
    public String toString() {
        return mName;
    }

    public void performAction(Activity context) {
    }
}
