package com.elementalfoundry.tapclips;

import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Handler;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.View;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.FrameLayout;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.facebook.Session;
import com.flurry.android.FlurryAgent;

import java.io.File;
import java.net.URLEncoder;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FragmentActivity implements GlobalEventsListener {
    private static String TAG = "SPRIO";
    private LinearLayout mDrawer;
    private FrameLayout mDrawerContents;
    private ImageButton mSettingsButton;
    private ImageButton mClipsButton;
    private ImageButton mExploreButton;
    private ClipRecorder mClipRecorder;
    private Fragment mSettingsFragment;
    private ClipsFragment mClipsFragment;
    private boolean mClipsVisible;
    private boolean mSettingsVisible;
    private boolean mExploreVisible;
    private View mExploreView;
    private WebView mExploreWevView;
    private View mExploreProgressBar;
    private Fragment mClipFragment;
    private Fragment mTermsAndConditionsFragment;
    private FrameLayout mPreviewContainer;
    private View mCurrentPreview;
    private int mVideosSaving = 0;
    private int mVideosUploading = 0;
    private View mShutter;
    private View mFirstTimeShutter;
    private TextView mFirstTimeShutterText;
    private View mMainClickBlocker;
    private View mLiveImage;
    private boolean mDrawerOpen = false;
    private TimerTick mTimer = null;
    private int mDrawerContentWidth;
    private View mBusyIndicator;
    private View mPreview;
    private View mLinkingInProgress;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d(TAG, "*** onCreate");
        Settings.get().init(getApplicationContext(), this);
        super.onCreate(savedInstanceState);



        if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT) {
            setContentView(R.layout.turn_phone);
            return;
        }

        setContentView(R.layout.activity_main);

        DisplayMetrics displayMetrics = getApplicationContext().getResources().getDisplayMetrics();

        mDrawer = (LinearLayout) findViewById(R.id.drawer);
        mDrawerContents = (FrameLayout) findViewById(R.id.drawerContents);

        mBusyIndicator = findViewById(R.id.uploadingProgress);

        Bitmap clipsImage = BitmapFactory.decodeResource(getResources(), R.drawable.icon_clips);
        mDrawerContentWidth = displayMetrics.widthPixels - clipsImage.getWidth() - new Float(20 * displayMetrics.density).intValue();
        //mDrawerContents.getLayoutParams().width = new Double(dpWidth * .4 * displayMetrics.density).intValue();

        mPreview = findViewById(R.id.cameraPreview_surfaceView);

        mShutter = findViewById(R.id.shutter);
        mFirstTimeShutter = findViewById(R.id.firstTimeShutter);
        mFirstTimeShutterText = (TextView)findViewById(R.id.firstTimeShutterText);
        showCorrectShutter();
        mLiveImage = findViewById(R.id.liveImage);
        mMainClickBlocker = findViewById(R.id.mainClickBlocker);
        mMainClickBlocker.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FlurryAgent.logEvent("Drawer Closed By Background Tap");
                closeDrawer(true);
            }
        });

        mLinkingInProgress = findViewById(R.id.linkingInProgress);
        mLinkingInProgress.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {

            }
        });

        FragmentManager fm = getSupportFragmentManager();
        mSettingsFragment = fm.findFragmentById(R.id.settingsFragmentContainer);
        if(mSettingsFragment == null) {
            mSettingsFragment = new SettingsFragment();
            fm.beginTransaction()
                    .add(R.id.settingsFragmentContainer, mSettingsFragment)
                    .hide(mSettingsFragment)
                    .commit();
        }

        // Maybe create this on demand (dont want to load the page until necessary)
        mExploreView = findViewById(R.id.exploreContainer);
        TextView exploreTitle = (TextView)mExploreView.findViewById(R.id.titleText);
        exploreTitle.setText("Explore");
        mExploreProgressBar = mExploreView.findViewById(R.id.titleProgress);
        mExploreWevView = (WebView)findViewById(R.id.exploreWebView);
        mExploreWevView.getSettings().setJavaScriptEnabled(true);
        mExploreWevView.setWebViewClient(new WebViewClient() {
            @Override
            public void onPageFinished(WebView view, String url) {
                super.onPageFinished(view, url);
                mExploreProgressBar.setVisibility(View.INVISIBLE);
            }

        });
        mExploreWevView.setWebChromeClient(new WebChromeClient());

        mClipsFragment = (ClipsFragment)fm.findFragmentById(R.id.clipsFragmentContainer);
        if (mClipsFragment == null) {
            mClipsFragment = new ClipsFragment();
            fm.beginTransaction()
                    .add(R.id.clipsFragmentContainer, mClipsFragment)
                    .commit();
        }

        mClipsVisible = true;
        mSettingsVisible = false;
        mExploreVisible = false;

        mDrawer.setTranslationX(mDrawerContentWidth);

        mSettingsButton = (ImageButton) findViewById(R.id.settingsButton);
        mSettingsButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                try {
                    FragmentManager fm = getSupportFragmentManager();
                    if (mDrawer.getTranslationX() == 0) {
                        if (mSettingsVisible) {
                            FlurryAgent.logEvent("Drawer Closed By Button Settings");
                            closeDrawer(true);
                        } else {
                            FlurryAgent.logEvent("Drawer switched to Settings");
                            hideAllDrawer();
                            mSettingsButton.setImageResource(R.drawable.icon_settings_selected);
                            fm.beginTransaction()
                                    .show(mSettingsFragment)
                                    .commit();
                            mSettingsVisible = true;
                        }
                    } else {
                        FlurryAgent.logEvent("Drawer Opened Settings");
                        openDrawerToSettings();
                    }
                } catch (Exception ex) {
                    Log.e("SPRIO", ex.toString());
                }
            }
        });

        mExploreButton = (ImageButton) findViewById(R.id.exploreButton);
        mExploreButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                try {
                    if (mDrawer.getTranslationX() == 0) {
                        if (mExploreVisible) {
                            FlurryAgent.logEvent("Drawer Closed By Button Explorer");
                            closeDrawer(true);
                        } else {
                            FlurryAgent.logEvent("Drawer switched to Explorer");
                            hideAllDrawer();
                            mExploreButton.setImageResource(R.drawable.icon_tapclips_selected);
                            mExploreView.setVisibility(View.VISIBLE);
                            mExploreVisible = true;
                            mExploreProgressBar.setVisibility(View.VISIBLE);
                            appendInfoToUrl(Settings.get().getExploreUrl(), new OnAppendUrlInfo() {
                                @Override
                                public void onUrlInfoAppended(String url) {
                                    mExploreWevView.loadUrl(url);
                                }
                            });
                        }
                    } else {
                        FlurryAgent.logEvent("Drawer Opened Explorer");
                        openDrawerToExplore();
                    }
                } catch (Exception ex) {

                }
            }
        });

        mClipsButton = (ImageButton) findViewById(R.id.clipsButton);
        mClipsButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                try {
                    FragmentManager fm = getSupportFragmentManager();
                    if (mDrawer.getTranslationX() == 0) {
                        if (mClipsVisible) {
                            FlurryAgent.logEvent("Drawer Closed By Button Videos");
                            closeDrawer(true);
                        } else {
                            FlurryAgent.logEvent("Drawer switched to Videos");
                            mClipsFragment.notifyDataSetChanged();
                            hideAllDrawer();
                            mClipsButton.setImageResource(R.drawable.icon_folder_selected);
                            fm.beginTransaction()
                                    .show(mClipsFragment)
                                    .commit();
                            mClipsVisible = true;
                        }
                    } else {
                        FlurryAgent.logEvent("Drawer Opened Videos");
                        mClipsFragment.notifyDataSetChanged();
                        openDrawerToVideos();
                    }
                } catch (Exception ex) {
                    Log.e(Settings.TAG, ex.toString());
                }
            }
        });
        mClipRecorder = new ClipRecorder(this, this);

        if (!Settings.get().getAcceptedTermsAndConditions()) {
            mDrawer.setVisibility(View.INVISIBLE);
            mTermsAndConditionsFragment = fm.findFragmentById(R.id.termsAndConditionsContainer);
            mLiveImage.setVisibility(View.INVISIBLE);
            mShutter.setVisibility(View.INVISIBLE);
            mFirstTimeShutter.setVisibility(View.INVISIBLE);
            mFirstTimeShutterText.setVisibility(View.INVISIBLE);
            if (mTermsAndConditionsFragment == null) {
                mTermsAndConditionsFragment = new TermsAndConditionsFragment();
                fm.beginTransaction()
                        .add(R.id.termsAndConditionsContainer, mTermsAndConditionsFragment)
                        .commit();
            }
        }

        fm.addOnBackStackChangedListener(new FragmentManager.OnBackStackChangedListener() {
            @Override
            public void onBackStackChanged() {
                FragmentManager fm = getSupportFragmentManager();

                if (mTermsAndConditionsFragment == null && fm.getBackStackEntryCount() == 0) {
                    mPreview.setVisibility(View.VISIBLE);
                    mSecondsSaved = 0;
                    mClipRecorder.start();
                    showCorrectShutter();
                    setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR);
                }
            }
        });

        mPreviewContainer = (FrameLayout) findViewById(R.id.previewContainer);
    }

    private void appendInfoToUrl(final String url, final OnAppendUrlInfo listener) {
        new AsyncTask<Void, Void, Void>() {
            private String mUrl = url;
            @Override
            protected Void doInBackground(Void... nothing) {
                try {
                    // TODO: Don't login if session token exists and is valid
                    Settings.get().loginUser("");
                    mUrl += (mUrl.indexOf("?") == -1) ? "?" : "&";
                    mUrl += "id=" + URLEncoder.encode(Settings.get().getUserId(), "UTF-8");

                    if (mUrl.startsWith("https://tclip.tv")
                            || mUrl.startsWith("http://tclip.tv")
                            || mUrl.startsWith("https://tapclips.com")
                            || mUrl.startsWith("http://tapclips.com")) {
                        mUrl += "&t=" + URLEncoder.encode(Settings.get().getSessionToken(), "UTF-8");
                    }
                } catch (Exception ex) {
                }

                return null;
            }

            @Override
            protected void onPostExecute(Void nothing) {
                listener.onUrlInfoAppended(mUrl);
            }
        }.execute(null, null, null);
    }

    interface OnAppendUrlInfo {
        public void onUrlInfoAppended(String url);
    }

    private void openDrawerToExplore() {
        FragmentManager fm = getSupportFragmentManager();
        hideAllDrawer();
        mExploreButton.setImageResource(R.drawable.icon_tapclips_selected);
        mExploreView.setVisibility(View.VISIBLE);
        mExploreVisible = true;
        mExploreProgressBar.setVisibility(View.VISIBLE);
        appendInfoToUrl(Settings.get().getExploreUrl(), new OnAppendUrlInfo() {
            @Override
            public void onUrlInfoAppended(String url) {
                mExploreWevView.loadUrl(url);
            }
        });
        openDrawer(true, true);
    }

    private void openDrawerToSettings() {
        FragmentManager fm = getSupportFragmentManager();
        hideAllDrawer();
        mSettingsButton.setImageResource(R.drawable.icon_settings_selected);
        fm.beginTransaction()
                .show(mSettingsFragment)
                .commit();
        mSettingsVisible = true;
        openDrawer(true, true);
    }

    private void openDrawerToVideos() {
        FragmentManager fm = getSupportFragmentManager();
        hideAllDrawer();
        mClipsButton.setImageResource(R.drawable.icon_folder_selected);
        fm.beginTransaction()
                .show(mClipsFragment)
                .commit();
        mClipsVisible = true;
        openDrawer(true, true);
    }

    private void hideAllDrawer() {
        FragmentManager fm = getSupportFragmentManager();
        mClipsButton.setImageResource(R.drawable.icon_folder);
        mSettingsButton.setImageResource(R.drawable.icon_settings);
        mExploreButton.setImageResource(R.drawable.icon_tapclips);
        mExploreView.setVisibility(View.INVISIBLE);

        fm.beginTransaction()
                .hide(mSettingsFragment)
                .hide(mClipsFragment)
                .commit();

        mClipsVisible = false;
        mExploreVisible = false;
        mSettingsVisible = false;
    }

    private void showCorrectShutter() {
        if (mSecondsSaved < 3 || Settings.get().getNumTapClipsTaken() >= 10 && false) {
            mShutter.setVisibility(View.VISIBLE);
            mFirstTimeShutter.setVisibility(View.INVISIBLE);
            mFirstTimeShutterText.setVisibility(View.INVISIBLE);
        } else {
            mShutter.setVisibility(View.INVISIBLE);
            mFirstTimeShutter.setVisibility(View.VISIBLE);
            mFirstTimeShutterText.setVisibility(View.VISIBLE);
        }
    }

    private void hideShutter() {
        mShutter.setVisibility(View.INVISIBLE);
        mFirstTimeShutter.setVisibility(View.INVISIBLE);
        mFirstTimeShutterText.setVisibility(View.INVISIBLE);
    }

    public void onAcceptedTermsAndConditions() {
        Settings.get().acceptTermsAndConditions();
        FragmentManager fm = getSupportFragmentManager();
        fm.beginTransaction()
                .remove(mTermsAndConditionsFragment)
                .commit();

        mTermsAndConditionsFragment = null;
        mDrawer.setVisibility(View.VISIBLE);
        mLiveImage.setVisibility(View.VISIBLE);
        showCorrectShutter();
    }


    protected void openDrawer(boolean animate, final boolean partial) {
        mDrawerOpen = true;
        mMainClickBlocker.setVisibility(View.VISIBLE);
        mShutter.setVisibility(View.INVISIBLE);
        mFirstTimeShutter.setVisibility(View.INVISIBLE);
        mFirstTimeShutterText.setVisibility(View.INVISIBLE);
        mLiveImage.setVisibility(View.INVISIBLE);
        if (animate) {
            TranslateAnimation anim = new TranslateAnimation(0, -mDrawerContentWidth, 0, 0);
            anim.setDuration(200);
            anim.setFillAfter(false);
            anim.setAnimationListener(new Animation.AnimationListener() {
                @Override
                public void onAnimationStart(Animation animation) {
                }

                @Override
                public void onAnimationEnd(Animation animation) {
                    animation = new TranslateAnimation(0.0f, 0.0f, 0.0f, 0.0f);
                    animation.setDuration(1);
                    mDrawer.startAnimation(animation);
                    openDrawer(false, partial);
                }

                @Override
                public void onAnimationRepeat(Animation animation) {
                }
            });
            mDrawer.startAnimation(anim);
        } else {
            mDrawer.setTranslationX(0);
        }
    }

    protected void closeDrawer(boolean animate) {
        mDrawerOpen = false;
        mMainClickBlocker.setVisibility(View.INVISIBLE);
        showCorrectShutter();
        mLiveImage.setVisibility(View.VISIBLE);
        if (animate) {
            TranslateAnimation anim = new TranslateAnimation(0, mDrawerContentWidth, 0, 0);
            anim.setDuration(200);
            anim.setFillAfter(false);
            anim.setAnimationListener(new Animation.AnimationListener() {
                @Override
                public void onAnimationStart(Animation animation) {

                }

                @Override
                public void onAnimationEnd(Animation animation) {
                    animation = new TranslateAnimation(0.0f, 0.0f, 0.0f, 0.0f);
                    animation.setDuration(1);
                    mDrawer.startAnimation(animation);
                    closeDrawer(false);
                }

                @Override
                public void onAnimationRepeat(Animation animation) {
                }
            });
            mDrawer.startAnimation(anim);
        } else {
            mDrawer.setTranslationX(mDrawerContentWidth);
            mClipsButton.setImageResource(R.drawable.icon_folder);
            mSettingsButton.setImageResource(R.drawable.icon_settings);
            mExploreButton.setImageResource(R.drawable.icon_tapclips);
        }
    }

    public void onShowClip(File clip, boolean openToShare, String shareType) {
        Log.d("SPRIO", "Showing clip");
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);

        if (mTimer != null) {
            mTimer.stop = true;
        }
        mClipRecorder.stop();
        closeDrawer(false);

        FragmentManager fm = getSupportFragmentManager();
        mClipFragment = fm.findFragmentById(R.id.clipViewerFragmentContainer);

        if(mClipFragment == null) {
            mClipFragment = ClipFragment.newInstance(clip, openToShare, shareType);
            fm.beginTransaction()
                    .add(R.id.clipViewerFragmentContainer, mClipFragment)
                    .addToBackStack("CLIP DETAIL")
                    .commit();
        }

        mPreview.setVisibility(View.INVISIBLE);
    }

    public void onHideClipPreview() {
        hideClipPreview();
    }

    private void hideClipPreview() {
        FragmentManager fm = getSupportFragmentManager();
        fm.popBackStack();
        mClipFragment = null;
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Session.getActiveSession().onActivityResult(this, requestCode, resultCode, data);
    }

    public void onClipDeleted() {
        mClipsFragment.notifyDataSetChanged();
    }

    private Handler mHandler = new Handler();
    private int mSecondsSaved = 0;

    public void onStartSaving() {
        mTimer = new TimerTick();
        mHandler.postDelayed(mTimer, 0);
    }

    private class TimerTick implements Runnable {
        public boolean stop = false;
        @Override
        public void run() {
            if (stop) return;
            mSecondsSaved++;

            runOnUiThread(new Runnable() {
                @Override
                public void run() {

                    mFirstTimeShutterText.setText("Tap to save last " + mSecondsSaved + " seconds");
                    if (!mDrawerOpen && mTermsAndConditionsFragment == null) showCorrectShutter();
                }
            });

            if (mSecondsSaved < Settings.get().getMaxLengthSeconds()) {
                mTimer = new TimerTick();
                mHandler.postDelayed(mTimer, 1000);
            }
        }
    }

    public void onUserTapped(int recordState) {

        Animation anim = new AlphaAnimation(1f, 0f);
        anim.setDuration(300);
        final View v = findViewById(R.id.cameraFlash);

        if(recordState == GlobalEventsListener.CLIP_RECORDER_BUSY_WRITING ||
                recordState == GlobalEventsListener.CLIP_RECORDER_NOT_RECORDING) {
            v.setBackgroundColor(Color.RED);
        } else {
            v.setBackgroundColor(Color.WHITE);
        }

        v.setVisibility(View.VISIBLE);
        anim.setAnimationListener(new Animation.AnimationListener() {
                                      @Override
                                      public void onAnimationStart(Animation animation) {

                                      }

                                      @Override
                                      public void onAnimationEnd(Animation animation) {
                                          Animation anim2 = new AlphaAnimation(0f, 0f);
                                          anim2.setDuration(1);
                                          v.startAnimation(anim2);
                                          v.setVisibility(View.INVISIBLE);
                                      }

                                      @Override
                                      public void onAnimationRepeat(Animation animation) {

                                      }
                                  }

        );

        v.startAnimation(anim);

        if(recordState == GlobalEventsListener.CLIP_RECORDER_END_TIME_SET) {

            mVideosSaving++;

            if (mCurrentPreview != null) {
                dismissCurrentPreview();
            }

            mCurrentPreview = getLayoutInflater().inflate(R.layout.preview, mPreviewContainer, false);
            mCurrentPreview.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                }
            });
            mPreviewContainer.addView(mCurrentPreview);

            TranslateAnimation slideInAnim = new TranslateAnimation(120, 0, 0, 0);
            slideInAnim.setDuration(200);
            slideInAnim.setFillAfter(false);
            mCurrentPreview.startAnimation(slideInAnim);
        }
    }

    private void dismissCurrentPreview() {
        final View p = mCurrentPreview;
        mCurrentPreview = null;

        TranslateAnimation anim = new TranslateAnimation(0, 120, 0, 0);
        anim.setDuration(200);
        anim.setFillAfter(false);

        anim.setAnimationListener(new Animation.AnimationListener() {
            @Override
            public void onAnimationStart(Animation animation) {
            }

            @Override
            public void onAnimationEnd(Animation animation) {
                mPreviewContainer.removeView(p);
            }

            @Override
            public void onAnimationRepeat(Animation animation) {

            }
        });

        p.startAnimation(anim);
    }

    public void clipSaved(final String ts, int duration) {
        int length = 0;

        if (ts != null) {
            String clipPath = FileManager.getVideoPath(ts);

            try {
                // Do initial clipssing to default length
                int durationSeconds = new Long(duration / 1000).intValue();
                int startTime = 0;

                Map<String, String> articleParams = new HashMap<String, String>();
                articleParams.put("duration", "" + durationSeconds);
                FlurryAgent.logEvent("Video Captured", articleParams);

                if (durationSeconds > Settings.get().getDefaultLengthSeconds()) {
                    boolean error = false;
                    int startSecond = durationSeconds - Settings.get().getDefaultLengthSeconds();
                    startTime = startSecond * 1000;
                    File editedFile = FileManager.getEditedFile(new File(clipPath));
                    try {
                        new ClipEdit().edit(clipPath, editedFile.getAbsolutePath(), startTime, duration);
                    } catch (Exception ex) {
                        error = true;
                        startTime = 0;
                        Log.e("SPRIO", "Error doing initial edit: ", ex);
                    }
                }

                ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip(new File(clipPath));
                info.awsClipFrameUrl = "";
                info.awsClipUrl = "";
                info.startTime = startTime;
                info.endTime = duration;
                length = (duration - startTime) / 1000;
                ClipInfoManager.saveInfoForClip(new File(clipPath), info);
            } catch (Exception ex) {
                Log.d(Settings.TAG, "Exception doing initial clip: ", ex);
            }
        }

        final int finalLength = length;

        this.runOnUiThread(new Runnable() {
            public void run() {
                mClipsFragment.notifyDataSetChanged();

                final View thumbViewer = (View)findViewById(R.id.thumbViewer);

                Settings.get().incrementNumTapClipsTaken();
                showCorrectShutter();
                
                mVideosSaving--;
                Handler handler = new Handler();
                if(mVideosSaving == 0) {
                    if (null == ts) {
                        dismissCurrentPreview();
                        return;
                    }

                    final String clipPath = FileManager.getVideoPath(ts);

                    final View p = mCurrentPreview;

                    ImageView pImageView = (ImageView)p.findViewById(R.id.previewImageView);
                    pImageView.setImageURI(Uri.parse(FileManager.getThumbnail(new File(clipPath)).getAbsolutePath()));

                    TextView durationView = (TextView)p.findViewById(R.id.clipDuration);
                    durationView.setText(String.format(":%02d", finalLength));

                    View previewClickMe = p.findViewById(R.id.previewClickMe);
                    previewClickMe.setVisibility(View.VISIBLE);
                    previewClickMe.setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View view) {
                            onShowClip(new File(clipPath), false, null);
                        }
                    });

                    handler.postDelayed(new Runnable() {
                        public void run() {
                            if (p.equals(mCurrentPreview)) {
                                dismissCurrentPreview();
                            }
                        }
                    }, 8000);
                }
            }
        });
    }

    public void onStartUploadingVideo() {
        mVideosUploading++;
        mBusyIndicator.setVisibility(View.VISIBLE);
    }

    public void onFinishedUploadingVideo() {
        mVideosUploading--;
        if (mVideosUploading == 0) {
            mBusyIndicator.setVisibility(View.INVISIBLE);
        }
    }

    public void postToS3AndShare(final File file,
                                 final String description,
                                 final boolean shareToFacebook,
                                 final boolean shareToTwitter,
                                 final boolean shareToSprio,
                                 final String teamId) {
        onStartUploadingVideo();
        new AsyncTask<Void, Void, Void>() {
            public boolean error = false;

            // TODO: should probably do some code sharing with postToS3AndUploadUrl
            // Storing these as local variables prevents issues when clipfragment
            // is no longer visible
            FragmentActivity a = MainActivity.this;

            @Override
            protected Void doInBackground(Void... nothing) {
                try {
                    ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip(file);
                    String clipAwsUrl;
                    String frameAwsUrl;

                    if (info.awsClipUrl == null || info.awsClipUrl.equals("")) {
                        Log.d(Settings.TAG, "Uploading video to S3");
                        S3Uploader.S3TaskResult result = new S3Uploader(a, null).postVideoToS3(file);
                        if (result.getErrorMessage() != null) {
                            error = true;
                            return null;
                        }

                        clipAwsUrl = result.getClipUrl();
                        frameAwsUrl = result.getFrameUrl();
                    } else {
                        Log.d(Settings.TAG, "Video already uploaded S3");
                        clipAwsUrl = info.awsClipUrl;
                        frameAwsUrl = info.awsClipFrameUrl;
                    }

                    MediaMetadataRetriever retriever = new MediaMetadataRetriever();
                    retriever.setDataSource(FileManager.getStreamableFile(file).getPath());
                    String time = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
                    int duration = Integer.parseInt(time);

                    String widthString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH);
                    String heightString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT);
                    retriever.release();
                    int width = Integer.parseInt(widthString);
                    int height = Integer.parseInt(heightString);

                    Api.PostParamsWithShareInfo params = new Api.PostParamsWithShareInfo();
                    params.attachments = new Api.PostParamsWithShareInfo.Attachment[1];
                    Api.PostParamsWithShareInfo.Attachment attachment = new Api.PostParamsWithShareInfo.Attachment();
                    attachment.url = Settings.S3_CLIP_BASE + clipAwsUrl;
                    attachment.imgUrl = Settings.S3_CLIP_BASE + frameAwsUrl;
                    attachment.size = new int[2];
                    attachment.size[0] = width;
                    attachment.size[1] = height;
                    attachment.duration = (float) duration / 1000.0f;
                    params.attachments[0] = attachment;
                    params.share = new Api.PostParamsWithShareInfo.ShareDict();

                    if (shareToFacebook) {
                        params.share.fb = new Api.PostParamsWithShareInfo.FacebookInfo();
                        params.share.fb.token = Session.getActiveSession().getAccessToken();
                        FlurryAgent.logEvent("Shared via Facebook");
                    }

                    if (shareToTwitter) {
                        params.share.twitter = new Api.PostParamsWithShareInfo.TwitterInfo();
                        params.share.twitter.oauth_token = TwitterManager.get().getOauthToken();
                        params.share.twitter.oauth_token_secret = TwitterManager.get().getOauthSecret();
                        FlurryAgent.logEvent("Shared via Twitter");
                    }

                    if (shareToSprio) {
                        params.share.sprio = new Api.PostParamsWithShareInfo.SprioInfo();
                        params.share.sprio.teamId = teamId;
                    }
                    params.description = description;

                    Api api = new Api();
                    Api.ApiResponse postResponse = (Api.ApiResponse) api.MakeApiCall("/api/2.0/createFeedPost", params, Api.ApiResponse.class);
                    if (postResponse == null || !postResponse.success) error = true;
                } catch (Exception ex) {
                    Log.e(Settings.TAG, "Error sharing: ", ex);
                    error = true;
                }

                return null;
            }

            @Override
            protected void onPostExecute(Void nothing) {
                if (error) {
                    TCToast.showErrorToast("Error sharing clip.", a);
                } else {
                    TCToast.showToast("Post Completed.", a);
                }

                onFinishedUploadingVideo();
            }
        }.execute(null, null, null);
    }
    public void postToS3AndUploadUrl(final Api.GetTapClipsUrlResponse response, final File file) {
        onStartUploadingVideo();
        new AsyncTask<Void, Void, Void>() {
            public boolean error = false;

            // Storing these as local variables prevents issues when clipfragment
            // is no longer visible
            FragmentActivity a = MainActivity.this;

            @Override
            protected Void doInBackground(Void... nothing) {
                ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip(file);
                String clipAwsUrl;
                String frameAwsUrl;

                if (info.awsClipUrl == null || info.awsClipUrl.equals("")) {
                    Log.d(Settings.TAG, "Uploading video to S3");
                    S3Uploader.S3TaskResult result = new S3Uploader(a, null).postVideoToS3(file);
                    if(result.getErrorMessage() != null) {
                        error = true;
                        return null;
                    }

                    clipAwsUrl = result.getClipUrl();
                    frameAwsUrl = result.getFrameUrl();
                } else {
                    Log.d(Settings.TAG, "Video already uploaded S3");
                    clipAwsUrl = info.awsClipUrl;
                    frameAwsUrl = info.awsClipFrameUrl;
                }

                MediaMetadataRetriever retriever = new MediaMetadataRetriever();
                retriever.setDataSource(FileManager.getStreamableFile(file).getPath());
                String time = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
                int duration = Integer.parseInt(time);

                String widthString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH);
                String heightString = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT);
                retriever.release();
                int width = Integer.parseInt(widthString);
                int height = Integer.parseInt(heightString);

                Api.PostParamsWithShortUrl params = new Api.PostParamsWithShortUrl();
                params.attachments = new Api.PostParamsWithShortUrl.Attachment[1];
                Api.PostParamsWithShortUrl.Attachment attachment = new Api.PostParamsWithShortUrl.Attachment();
                attachment.url = Settings.S3_CLIP_BASE + clipAwsUrl;
                attachment.imgUrl = Settings.S3_CLIP_BASE + frameAwsUrl;
                attachment.size = new int[2];
                attachment.size[0] = width;
                attachment.size[1] = height;
                attachment.duration = (float)duration / 1000.0f;
                params.attachments[0] = attachment;
                params.shortUrlInfo = new Api.PostParamsWithShortUrl.ShortUrlInfo();
                params.shortUrlInfo.url = response.response.url;
                params.shortUrlInfo.date = response.response.date;
                params.shortUrlInfo.signature = response.response.signature;

                Api api = new Api();
                Api.ApiResponse postResponse = (Api.ApiResponse)api.MakeApiCall("/api/2.0/createFeedPost", params, Api.ApiResponse.class);
                if (postResponse == null || !postResponse.success) error = true;

                return null;
            }

            @Override
            protected void onPostExecute(Void nothing) {
                if (error) {
                    TCToast.showErrorToast("Error sharing clip.", a);
                } else {
                }

                onFinishedUploadingVideo();
            }
        }.execute(null, null, null);
    }

    private static File mFileToShare = null;
    public void shareToTwitter(File fileToShare, Fragment shareFragment) {

        if (TwitterManager.get().isAuthorized()) {
            FragmentManager fm = getSupportFragmentManager();
            Fragment shareDetailsFrag = ShareDetailFragment.newInstance("Twitter", ShareDetailFragment.SHARE_TYPE_TWITTER, fileToShare.getAbsolutePath());
            fm.beginTransaction()
                    .add(R.id.sendScreenDetailsContainer, shareDetailsFrag)
                    .remove(shareFragment)
                    .addToBackStack(null)
                    .commit();
        } else {
            mFileToShare = fileToShare;
            TwitterManager.get().requestAuthorization(this);
        }
    }

    public void shareToSprio(final File fileToShare, final Fragment shareFragment, final OnCompleteListener listener) {
        new AsyncTask<Void, Void, Void>() {
            boolean mError = false;
            boolean mLinked = false;

            protected Void doInBackground(Void... nothing) {
                try {
                    mLinked = SprioManager.get().isLinked();
                } catch (Exception ex) {
                    mError = true;
                }

                return null;
            }

            protected void onPostExecute(Void nothing) {
                if (!mError){
                    if (!mLinked) {
                        mFileToShare = fileToShare;
                        SprioManager.get().LinkAccount(MainActivity.this);
                    } else {
                        FragmentManager fm = getSupportFragmentManager();
                        Fragment shareDetailsFrag = ShareDetailFragment.newInstance("Sprio", ShareDetailFragment.SHARE_TYPE_SPRIO, fileToShare.getAbsolutePath());
                        fm.beginTransaction()
                                .add(R.id.sendScreenDetailsContainer, shareDetailsFrag)
                                .remove(shareFragment)
                                .addToBackStack(null)
                                .commit();
                    }

                    if (listener != null) listener.onComplete();
                } else {
                    TCToast.showErrorToast("Error posting to Sprio.", MainActivity.this);
                    if (listener != null) listener.onError();
                }
            }
        }.execute(null, null, null);
    }

    @Override
    protected void onStart() {
        Log.d(TAG, "*** onStart");
        super.onStart();
        FlurryAgent.onStartSession(this, "5TBWMJY3YJPRBW2TKW4J");
    }

    @Override
    protected void onResume() {
        Log.d(TAG, "*** onResume");

        // TODO: Clear out mFileToShare
        super.onResume();
        if (mClipRecorder != null && mClipFragment == null) {
            mClipRecorder.setClipLength(Settings.get().getMaxLengthSeconds());
            mClipRecorder.start();
        }

        boolean portrait = getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT;
        if (portrait) return;

        Intent intent = getIntent();
        Uri data = intent.getData();
        intent.setData(null);
        if (data != null) {
            String uri = data.toString();
            final EFUri efuri = new EFUri(uri);
            if (efuri != null) {
                if (efuri.getAction().equals("web")) {
                    String url = efuri.getParam("url");
                    if (efuri.getParam("token").equals("1")) {
                        appendInfoToUrl(url, new OnAppendUrlInfo() {
                            @Override
                            public void onUrlInfoAppended(String url) {
                                String title = efuri.getParam("title");
                                openSimpleWebView(url, title);
                            }
                        });
                    } else {
                        String title = efuri.getParam("title");
                        openSimpleWebView(url, title);
                    }
                } else if (efuri.getAction().equals("explore")) {
                    openDrawerToExplore();
                } else if (efuri.getAction().equals("settings")) {
                    openDrawerToSettings();
                } else if (efuri.getAction().equals("videos")) {
                    openDrawerToVideos();
                } else if (efuri.getAction().equals("twitterAuth")) {
                    hideShutter();
                    mLinkingInProgress.setVisibility(View.VISIBLE);
                    new AsyncTask<Void, Void, Void>() {
                        boolean mError = false;

                        protected Void doInBackground(Void... nothing) {
                            try {
                                TwitterManager.get().completeAuthorization(efuri);
                            } catch (Exception ex) {
                                Log.e(Settings.TAG, "***** Exception getting access token: ", ex);
                                mError = true;
                            }

                            return null;
                        }

                        protected void onPostExecute(Void nothing) {
                            mLinkingInProgress.setVisibility(View.INVISIBLE);
                            showCorrectShutter();
                            if (!mError) {
                                onShowClip(mFileToShare, true, ShareDetailFragment.SHARE_TYPE_TWITTER);
                            } else {
                                TCToast.showErrorToast("Error linking Twitter account.", MainActivity.this);
                            }
                        }
                    }.execute(null, null, null);
                } else if (efuri.getAction().equals("sprioAuth")) {
                    hideShutter();
                    mLinkingInProgress.setVisibility(View.VISIBLE);
                    new AsyncTask<Void, Void, Void>() {
                        boolean mError = false;

                        protected Void doInBackground(Void... nothing) {
                            try {
                                mError = !SprioManager.get().completeLinkAccount(efuri);
                            } catch (Exception ex) {
                                Log.e(Settings.TAG, "***** Exception associating sprio account with tapclips: ", ex);
                                mError = true;
                            }

                            return null;
                        }

                        protected void onPostExecute(Void nothing) {
                            mLinkingInProgress.setVisibility(View.INVISIBLE);
                            showCorrectShutter();
                            if (!mError) {
                                onShowClip(mFileToShare, true, ShareDetailFragment.SHARE_TYPE_SPRIO);
                            } else {
                                TCToast.showErrorToast("Error linking Sprio account.", MainActivity.this);
                            }
                        }
                    }.execute(null, null, null);
                }
            }
        }
    }

    private void openSimpleWebView(String url, String title) {
        Fragment frag = SimpleWebViewer.newInstance(url, title);
        FragmentManager fm = getSupportFragmentManager();
        fm.beginTransaction()
                .add(R.id.mainActivityWebViewContainer, frag)
                .addToBackStack(null)
                .commit();
    }

    @Override
    protected void onPause() {
        Log.d(TAG, "*** onPause");
        if (mClipRecorder != null) {
            mClipRecorder.stop();
        }

        if (mTimer != null) mTimer.stop = true;
        mSecondsSaved = 0;
        if (mShutter != null) {
            showCorrectShutter();
        }

        super.onPause();
    }

    @Override
    protected void onStop() {
        Log.d(TAG, "*** onStop");
        super.onStop();
        FlurryAgent.onEndSession(this);
    }

    @Override
    protected void onDestroy() {
        Log.d(TAG, "*** onDestroy");
        if (mClipRecorder != null) {
            mClipRecorder.destroy();
        }
        super.onDestroy();
    }
}
