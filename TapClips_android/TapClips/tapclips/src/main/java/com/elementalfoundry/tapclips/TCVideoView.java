package com.elementalfoundry.tapclips;

import android.content.Context;
import android.media.MediaPlayer;
import android.os.Handler;
import android.util.AttributeSet;
import android.widget.VideoView;

/**
 * Created by mdbranth on 5/27/14.
 */
public class TCVideoView extends VideoView {
    private Handler mHandler = new Handler();
    private MediaPlayer.OnCompletionListener mListener;
    private OnProgressListener mProgListener;
    private String mVideoPath;

    public TCVideoView(Context context) {
        super(context);
    }

    public TCVideoView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public TCVideoView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    @Override
    public void setVideoPath(String path) {
        mVideoPath = path;
        super.setVideoPath(path);
    }

    @Override
    public void start() {
        super.start();
        mHandler.postDelayed(new TimerTick(), 20);
    }

    @Override
    public void pause() {
        super.pause();
    }

    @Override
    public void stopPlayback() {
        super.stopPlayback();
    }

    @Override
    public void setOnCompletionListener(MediaPlayer.OnCompletionListener listener) {
        mListener = listener;
        super.setOnCompletionListener(listener);
    }

    public void setOnProgressListener(OnProgressListener listener) {
        mProgListener = listener;
    }

    private class TimerTick implements Runnable {
        @Override
        public void run() {
            if (isPlaying()) {
                int maxPosition = getDuration();
                int pos = getCurrentPosition();
                mProgListener.onProgress((float)pos/(float)maxPosition);
                mHandler.postDelayed(new TimerTick(), 20);
            }
        }
    }

    public static interface OnProgressListener {
        public void onProgress(float percent);
    }
}
