package com.elementalfoundry.tapclips;

import android.support.v4.app.Fragment;

import java.io.File;

/**
 * Created by mdbranth on 5/13/14.
 */
public interface GlobalEventsListener {
    public static final int CLIP_RECORDER_NOT_RECORDING = 0;
    public static final int CLIP_RECORDER_BUSY_WRITING = 1;
    public static final int CLIP_RECORDER_END_TIME_SET = 2;
    public static final int CLIP_RECORDER_END_TIME_RESET = 3;

    public void onShowClip(File clip, boolean openToShare, String shareType);

    public void onClipDeleted();

    public void onHideClipPreview();

    public void onUserTapped(int recordState);

    public void clipSaved(String ts, int duration);

    public void onAcceptedTermsAndConditions();

    public void onStartSaving();

    public void onStartUploadingVideo();

    public void onFinishedUploadingVideo();

    public void postToS3AndUploadUrl(final Api.GetTapClipsUrlResponse response, final File file);

    public void postToS3AndShare(File file,
                                 String description,
                                 boolean shareToFacebook,
                                 boolean shareToTwitter,
                                 boolean shareToSprio,
                                 String teamId);

    public void shareToTwitter(File file, Fragment shareFragment);

    public void shareToSprio(File file, Fragment shareFragment, OnCompleteListener listener);

    public interface OnCompleteListener {
        public void onComplete();

        public void onError();
    }
}
