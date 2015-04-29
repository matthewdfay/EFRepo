package com.elementalfoundry.tapclips;

/**
 * Created by mdbranth on 5/7/14.
 */
public class Subtitle extends TCListItem {
    private String mText;

    public Subtitle(String text) {
        super();
        mText = text;
    }

    public String getText() {
        return mText;
    }

}
