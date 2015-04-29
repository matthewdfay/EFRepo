package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.media.MediaMetadataRetriever;
import android.media.MediaPlayer;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.MediaController;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.flurry.android.FlurryAgent;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

public class ScreenSlidePageFragment extends Fragment {

    public static final String ARG_WIDTH = "width";
    public static final String ARG_HEIGHT = "height";
    public static final String ARG_CLIP_PATH = "clip_path";
    public static final String ARG_START = "start";

    private int mWidth;
    private int mHeight;
    private String mClipPath;
    private ImageView mPlayPauseButton;
    private TCVideoView mVideoView;
    private boolean bVideoIsBeingTouched = false;
    private Handler mHandler = new Handler();
    private int stopPosition = -1;
    private boolean mStart = false;
    GlobalEventsListener mListener;
    private RangeSeekBar<Float> mSeekBar;
    private int mDurationSeconds;
    private int mDuration;
    private View mProgressBar;
    private int mMaxPosition = -1;
    private int mMinPosition = 0;
    private boolean mEditing = false;
    private TextView mClipLengthView;
    private Bitmap mBackground = null;

    /**
     * Factory method for this fragment class. Constructs a new fragment for the given page number.
     */
    public static ScreenSlidePageFragment create(boolean start, int width, int height, String clipPath) {
        ScreenSlidePageFragment fragment = new ScreenSlidePageFragment();
        Bundle args = new Bundle();
        args.putInt(ARG_WIDTH, width);
        args.putInt(ARG_HEIGHT, height);
        args.putString(ARG_CLIP_PATH, clipPath);
        args.putBoolean(ARG_START, start);

        fragment.setArguments(args);
        return fragment;
    }

    public ScreenSlidePageFragment() {
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
        try {
            mListener = (GlobalEventsListener) activity;
        } catch (ClassCastException e) {
            throw new ClassCastException(activity.toString()
                    + " must implement GlobalEventsListener");
        }
    }

    @Override
    public void onDetach() {
        super.onDetach();
        mListener = null;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mWidth = getArguments().getInt(ARG_WIDTH);
        mHeight = getArguments().getInt(ARG_HEIGHT);
        mClipPath = getArguments().getString(ARG_CLIP_PATH);
        mStart = getArguments().getBoolean(ARG_START);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout containing a title and body text.
        ViewGroup v = (ViewGroup) inflater
                .inflate(R.layout.fragment_screen_slide_page, container, false);

        final RelativeLayout mainLayout = (RelativeLayout)v.findViewById(R.id.mainPageLayout);
        mainLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mListener.onHideClipPreview();
            }
        });

        // Here is some hacky code to get the RangeSeekBar to line up correctly
        // To get the camera image and clip length to align with RangeSeekBar line I made RangeSeekBar line
        // in the center of the RangeSeekBar object. This made the whole RangeSeekBar really tall since the trimmer thumb
        // images hang off the bottom. So I then have to tack on a negative margin to make it reasonable
        // however, I wont know the height until run time. So, I calculate half the height of the RangeSeekBar
        // that would make it right on the top of the scree, subtract half the camera height and a 10dp margin
        // and set that as the negative margin
        Bitmap thumbImage = BitmapFactory.decodeResource(getResources(), R.drawable.trimmer_end);
        int thumbHeight = thumbImage.getHeight();
        Bitmap cameraImage = BitmapFactory.decodeResource(getResources(), R.drawable.icon_camera);
        int cameraHeight = cameraImage.getHeight();

        LinearLayout topControls = (LinearLayout)v.findViewById(R.id.slidePageTopControls);
        RelativeLayout.LayoutParams p = (RelativeLayout.LayoutParams)topControls.getLayoutParams();
        DisplayMetrics metrics = getResources().getDisplayMetrics();
        p.setMargins(0, new Float(-(thumbHeight + RangeSeekBar.pixelTapPadding) + (cameraHeight / 2) + 10 * metrics.density).intValue(), 0, 0);
        topControls.setLayoutParams(p);

        mProgressBar = v.findViewById(R.id.updatingClip);

        mSeekBar = new RangeSeekBar<Float>(0f, 1f, getActivity().getApplicationContext());
        mSeekBar.setNotifyWhileDragging(true);
        mSeekBar.setShowCurrentPosition(true);
        mSeekBar.setOnRangeSeekBarChangeListener(new RangeSeekBar.OnRangeSeekBarChangeListener<Float>() {
            @Override
            public void onRangeSeekBarValuesChanged(RangeSeekBar<?> bar, Float minValue, Float maxValue) {
                try {
                    stopVideoNoButton();
                    hideBackground();
                    setMinMax(minValue, maxValue, false);
                } catch (Exception ex) {
                    Log.e("SPRIO", "Error starting", ex);
                }
                Log.d(Settings.TAG, "User selected new range values: MIN=" + minValue + ", MAX=" + maxValue);
            }

            @Override
            public void onRangeSeekBarValuesSelected(RangeSeekBar<?> bar, final Float minValue, final Float maxValue) {
                try {
                    mEditing = true;
                    setMinMax(minValue, maxValue, true);
                    hideSeekBar();
                    mProgressBar.setVisibility(View.VISIBLE);

                    new AsyncTask<Void, Void, Void>() {
                        private boolean mError = false;
                        @Override
                        protected Void doInBackground(Void... params) {


                            File editedFile = FileManager.getEditedFile(new File(mClipPath));
                            try {
                                new ClipEdit().edit(mClipPath, editedFile.getAbsolutePath(), mMinPosition, mMaxPosition);
                            } catch (Exception ex) {
                                mError = true;
                                Log.e("SPRIO", "Error editing clip file: ", ex);
                            }

                            if (!mError) {
                                // Clear out saved aws info since we dont want to share an old edited file
                                ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip(new File(mClipPath));
                                int origStartTime = info.startTime;
                                int origEndTime = info.endTime;

                                info.awsClipFrameUrl = "";
                                info.awsClipUrl = "";
                                info.startTime = mMinPosition;
                                info.endTime = mMaxPosition;

                                Map<String, String> articleParams = new HashMap<String, String>();
                                articleParams.put("newDuration", (info.endTime - info.startTime) + "");
                                if (origStartTime == info.startTime) {
                                    articleParams.put("originalEnd", origEndTime + "");
                                    articleParams.put("newEnd", info.endTime + "");
                                    if (origEndTime < info.endTime) {
                                        FlurryAgent.logEvent("Edit End to Later", articleParams);
                                    } else {
                                        FlurryAgent.logEvent("Edit End to Earlier", articleParams);
                                    }
                                } else {
                                    articleParams.put("originalStart", origStartTime + "");
                                    articleParams.put("newStart", info.startTime + "");
                                    if (origStartTime < info.startTime) {
                                        FlurryAgent.logEvent("Edit Start to Later", articleParams);
                                    } else {
                                        FlurryAgent.logEvent("Edit Start to Earlier", articleParams);
                                    }
                                }

                                ClipInfoManager.saveInfoForClip(new File(mClipPath), info);
                            }

                            return null;
                        }

                        @Override
                        protected void onPostExecute(Void nothing) {
                            if(mError) {
                                // TODO: show a toast and set progress bar to min and max
                            }

                            mProgressBar.setVisibility(View.INVISIBLE);
                            showSeekBar();
                            mEditing = false;
                            startVideo();
                        }
                    }.execute(null, null, null);


                } catch (Exception ex) {
                    Log.e("SPRIO", "Error starting", ex);
                }
                Log.d(Settings.TAG, "User selected new range values: MIN=" + minValue + ", MAX=" + maxValue);
            }
        });

        FrameLayout seekBarHolder = (FrameLayout)v.findViewById(R.id.scrubContainer);
        seekBarHolder.addView(mSeekBar);

        mPlayPauseButton = (ImageView)v.findViewById(R.id.playPauseButton);
        mPlayPauseButton.setVisibility(View.INVISIBLE);

        mVideoView = (TCVideoView)v.findViewById(R.id.videoView);
        mVideoView.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mediaPlayer) {
                mPlayPauseButton.setImageResource(R.drawable.icon_play);
                mPlayPauseButton.setVisibility(View.VISIBLE);
                mSeekBar.setShowCurrentPosition(false);
            }
        });

        mVideoView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View v, MotionEvent event) {
                if (!bVideoIsBeingTouched) {
                    bVideoIsBeingTouched = true;
                    if (mVideoView.isPlaying()) {
                        // todo: no pause, just replay
                        FlurryAgent.logEvent("Video Paused");
                        mVideoView.pause();
                        stopPosition = mVideoView.getCurrentPosition();
                        mPlayPauseButton.setImageResource(R.drawable.icon_pause);
                        mPlayPauseButton.setVisibility(View.VISIBLE);
                    } else {
                        FlurryAgent.logEvent("Video Restarted");
                        startVideo();
                    }
                    mHandler.postDelayed(new Runnable() {
                        public void run() {
                            bVideoIsBeingTouched = false;
                        }
                    }, 300);
                }
                return true;
            }
        });



        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        retriever.setDataSource(mClipPath);
        String time = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
        retriever.release();

        mDuration = Integer.parseInt(time);
        mDurationSeconds = new Long(mDuration / 1000).intValue();

        ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip(new File(mClipPath));
        if(info.endTime > 0) {
            mSeekBar.setSelectedMinValue(1.0f * info.startTime / mDuration);
            mSeekBar.setSelectedMaxValue(1.0f * info.endTime / mDuration);
        }

        mClipLengthView = (TextView)v.findViewById(R.id.clipLength);
        setClipDurationView((info.endTime - info.startTime) / 1000);

        MediaController c = new MediaController(getActivity());
        c.setVisibility(View.GONE);
        c.setAnchorView(mVideoView);
        mVideoView.setMediaController(c);

        File editedFile = FileManager.getEditedFile(new File(mClipPath));
        if (editedFile.exists()) {
            mVideoView.setVideoPath(editedFile.getAbsolutePath());
        } else {
            mVideoView.setVideoPath(mClipPath);
        }

        mMinPosition = 0;
        mMaxPosition = mDuration;
        mVideoView.requestFocus();
        mVideoView.setZOrderMediaOverlay(true);

        mVideoView.setOnProgressListener(new TCVideoView.OnProgressListener() {
            @Override
            public void onProgress(float percent) {
                mSeekBar.setCurrentPositionPercent(percent);
            }
        });

        if(mStart) {
            mVideoView.start();
        } else {
            hideSeekBar();
            showBackground();
        }

        return v;
    }

    public void showBackground() {
        if (isAdded()) {
            if (mBackground == null) {
                mBackground = BitmapFactory.decodeFile(FileManager.getCoverPhoto(new File(mClipPath)).getAbsolutePath());
            }
            mVideoView.setBackground(new BitmapDrawable(getResources(), mBackground));
        }
    }

    public void hideBackground() {
        mVideoView.setBackground(null);
    }

    public void hideSeekBar() {
        mClipLengthView.setVisibility(View.INVISIBLE);
        mSeekBar.setVisibility(View.INVISIBLE);
    }

    public void showSeekBar() {
        mClipLengthView.setVisibility(View.VISIBLE);
        mSeekBar.setVisibility(View.VISIBLE);
    }

    public void stopVideoNoButton() {
        if (mVideoView.isPlaying()) {
            mVideoView.pause();
        }

        mPlayPauseButton.setVisibility(View.INVISIBLE);
        mSeekBar.setShowCurrentPosition(false);
        showBackground();
    }

    private void setClipDurationView(int seconds) {
        mClipLengthView.setText(String.format("0:%02d", seconds));
    }

    public void setMinMax(Float percentMin, Float percentMax, boolean selected) {
        int newMinSeconds = new Float(mDuration * percentMin / 1000).intValue();
        int newMaxSeconds = new Float(mDuration * percentMax / 1000).intValue();
        int newMin = newMinSeconds * 1000;
        int newMax = newMaxSeconds * 1000;

        if(newMaxSeconds == mDurationSeconds) newMax = mDuration;

        if(newMin != mMinPosition) {
            if (newMin != newMax) {
                mVideoView.setVideoPath(mClipPath);
                mVideoView.seekTo(newMin);
            }
        } else if (newMax != mMaxPosition){
            if (newMin != newMax) {
                mVideoView.setVideoPath(mClipPath);
                mVideoView.seekTo(newMax);
            }
        }

        Log.d("SPRIO", "newMinSeconds: " + newMinSeconds + ", newMaxSeconds: " + newMaxSeconds + ", newMin: " + newMin + ", newMax: " + newMax);

        if (newMax - newMin >= Settings.get().getMinLengthSeconds() * 1000) {
            mMinPosition = newMin;
            mMaxPosition = newMax;
            setClipDurationView(newMaxSeconds - newMinSeconds);
        }

        // Update slider to be on even seconds
        if(selected) {
            mSeekBar.setSelectedMinValue(mMinPosition * 1.0f / mDuration);
            mSeekBar.setSelectedMaxValue(mMaxPosition * 1.0f / mDuration);

            Log.d("SPRIO", "minValue: " + mSeekBar.getSelectedMinValue());
            Log.d("SPRIO", "maxValue: " + mSeekBar.getAbsoluteMaxValue());
        }
    }

    public void startVideo() {
        if (mEditing) return;
        stopVideoNoButton();
        File editedFile = FileManager.getEditedFile(new File(mClipPath));
        if (editedFile.exists()) {
            mVideoView.setVideoPath(editedFile.getAbsolutePath());
        } else {
            mVideoView.setVideoPath(mClipPath);
        }

        mVideoView.seekTo(0);
        mSeekBar.setShowCurrentPosition(true);
        hideBackground();
        mVideoView.start();
    }
}
