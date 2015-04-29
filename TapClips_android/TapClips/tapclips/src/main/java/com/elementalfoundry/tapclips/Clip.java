package com.elementalfoundry.tapclips;

import java.io.File;

/**
 * Created by mdbranth on 5/13/14.
 */
public class Clip extends TCListItem {
    private File mFile;

    public Clip(File file) {
        mFile = file;
    }

    public File getFile() {
        return mFile;
    }
}
