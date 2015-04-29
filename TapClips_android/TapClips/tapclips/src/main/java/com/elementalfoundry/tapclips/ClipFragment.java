package com.elementalfoundry.tapclips;


import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.support.v4.app.FragmentManager.OnBackStackChangedListener;
import android.support.v4.app.FragmentStatePagerAdapter;
import android.support.v4.view.PagerAdapter;
import android.support.v4.view.ViewPager;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;

import com.flurry.android.FlurryAgent;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;

public class ClipFragment extends Fragment {
    private static final String ARG_FILE_NAME = "file_path";
    private static final String ARG_OPEN_SHARE = "open_share";
    private static final String ARG_SHARE_TYPE = "share_type";

    private String mInitialFilePath;
    private boolean mOpenShare;
    private String mShareType;

    private GlobalEventsListener mListener;
    private ViewPager mPager;
    private PagerAdapter mPagerAdapter;
    private File[] mFiles;
    private ImageButton mLeftArrow;
    private ImageButton mRightArrow;
    private ImageButton mDeleteButton;
    private ImageButton mBackToCameraButton;
    private View mBottomButtons;
    private ImageButton mOpenSendButton;
    private ScreenSlidePageFragment[] slideFrags;


    private boolean mFirstPlayed = false;
    private boolean mFirstBackOccurred = false;
    private boolean mShowControlsOnFirstBack = true;
    private boolean mAutoStartFirstClip = true;

    private OnBackStackChangedListener mBackListener;

    public static ClipFragment newInstance(File file, boolean openShare, String shareType) {
        ClipFragment fragment = new ClipFragment();
        Bundle args = new Bundle();
        args.putString(ARG_FILE_NAME, file.getAbsolutePath());
        args.putBoolean(ARG_OPEN_SHARE, openShare);
        args.putString(ARG_SHARE_TYPE, shareType);
        fragment.setArguments(args);
        return fragment;
    }

    public ClipFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mInitialFilePath = getArguments().getString(ARG_FILE_NAME);
            mOpenShare = getArguments().getBoolean(ARG_OPEN_SHARE, false);
            mShareType= getArguments().getString(ARG_SHARE_TYPE, "");
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fragment_clip, container, false);

        mBottomButtons = v.findViewById(R.id.bottomControls);

        mBackToCameraButton = (ImageButton)v.findViewById(R.id.backToCamera);
        mBackToCameraButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FlurryAgent.logEvent("Dismiss preview by camera icon");
                mListener.onHideClipPreview();
                return;
            }
        });

        mDeleteButton = (ImageButton)v.findViewById(R.id.deleteButton);
        mDeleteButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FlurryAgent.logEvent("Delete Clip Initiated");
                AlertDialog.Builder alertDialogBuilder = new AlertDialog.Builder(getActivity());
                alertDialogBuilder
                        .setTitle("Delete")
                        .setMessage("Are you sure you want to delete this TapClip?")
                        .setCancelable(false)
                        .setPositiveButton("Yes", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                File f = mFiles[mPager.getCurrentItem()];

                                try {
                                    FileManager.deleteClip(f);
                                    FlurryAgent.logEvent("Delete Clip Succeeded");
                                    mListener.onClipDeleted();
                                    if (mFiles.length == 1) {
                                        mListener.onHideClipPreview();
                                        return;
                                    }

                                    ArrayList<File> files = new ArrayList<File>(Arrays.asList(mFiles));
                                    files.remove(mPager.getCurrentItem());
                                    mFiles = new File[files.size()];
                                    mFiles = files.toArray(mFiles);

                                    ArrayList<ScreenSlidePageFragment> frags = new ArrayList<ScreenSlidePageFragment>(Arrays.asList(slideFrags));
                                    frags.remove(mPager.getCurrentItem());
                                    slideFrags = new ScreenSlidePageFragment[frags.size()];
                                    slideFrags = frags.toArray(slideFrags);

                                    // This gets the next one to autoplay
                                    mFirstPlayed = false;

                                    mPagerAdapter.notifyDataSetChanged();

                                    showHideArrows();
                                } catch (Exception ex) {
                                    FlurryAgent.logEvent("Delete Clip Failed");
                                    Log.e(Settings.TAG, "Exception deleting clip: ", ex);
                                    TCToast.showErrorToast("Error deleting clip.", getActivity());
                                }
                            }
                        })
                        .setNegativeButton("No", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialogInterface, int i) {
                                dialogInterface.cancel();
                            }
                        });
                AlertDialog dialog = alertDialogBuilder.create();
                dialog.show();
            }
        });

        mLeftArrow = (ImageButton)v.findViewById(R.id.leftArrow);
        mRightArrow = (ImageButton)v.findViewById(R.id.rightArrow);

        mFiles = FileManager.getAllClips();

        int currentFile = 0;
        for (int i = 0; i < mFiles.length; i++) {
            if(mFiles[i].getAbsolutePath().equals(mInitialFilePath)) {
                currentFile = i;
                break;
            }
        }

        slideFrags = new ScreenSlidePageFragment[mFiles.length];

        // Instantiate a ViewPager and a PagerAdapter.
        mPager = (ViewPager) v.findViewById(R.id.pager);
        mPagerAdapter = new ScreenSlidePagerAdapter(getFragmentManager());
        mPager.setAdapter(mPagerAdapter);
        mPager.setOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                try {
                    if (slideFrags != null && slideFrags[position] != null) slideFrags[position].startVideo();
                } catch (Exception ex) {
                    Log.e("SPRIO", "Error starting", ex);
                }
            }

            @Override
            public void onPageScrollStateChanged(int state) {
                if (state != ViewPager.SCROLL_STATE_IDLE) {
                    for (int i = 0; i < slideFrags.length; i++) {
                        if (slideFrags[i] != null) {
                            try {
                                slideFrags[i].stopVideoNoButton();
                                slideFrags[i].hideSeekBar();

                            } catch (Exception ex) {
                                Log.e("SPRIO", "Error stopping", ex);
                            }
                        }
                    }
                } else {
                    showControls();
                }

                if (state == ViewPager.SCROLL_STATE_DRAGGING) {
                    hideControls();
                }
                Log.d("SPRIO", "**** PAGE SCROLL STATE CHANGED " + state);
            }
        });

        mPager.setCurrentItem(currentFile);
        showHideArrows();

        mLeftArrow.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mPager.setCurrentItem(mPager.getCurrentItem() - 1);
            }
        });

        mRightArrow.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mPager.setCurrentItem(mPager.getCurrentItem() + 1);
            }
        });

        mOpenSendButton = (ImageButton)v.findViewById(R.id.openSendButton);
        mOpenSendButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openSend(false, null);
            }
        });

        mBackListener = new OnBackStackChangedListener() {
            @Override
            public void onBackStackChanged() {
                FragmentManager fm = getFragmentManager();

                if(fm != null && fm.getBackStackEntryCount() == 1) {
                    if(!mFirstBackOccurred) {
                        // Hacky, but this fragment being added actually makes this called,
                        // and I don't want it to run
                        mFirstBackOccurred = true;
                        if(!mShowControlsOnFirstBack) return;
                    }
                    fm.removeOnBackStackChangedListener(mBackListener);
                    showControls();
                }
            }
        };

        if (mOpenShare) {
            mAutoStartFirstClip = false;
            mShowControlsOnFirstBack = false;
            openSend(true, mShareType);
            mOpenShare = false;
        }

        return v;
    }

    private void openSend(boolean openDetail, String shareType) {
        try {
            if(slideFrags[mPager.getCurrentItem()] != null) {
                slideFrags[mPager.getCurrentItem()].stopVideoNoButton();
            }
        } catch (Exception ex) {
            Log.e("SPRIO", "Error stopping", ex);
        }


        FragmentManager fm = getFragmentManager();

        hideControls();

        Fragment shareFrag = ShareFragment.newInstance(mFiles[mPager.getCurrentItem()].getAbsolutePath(), openDetail, shareType);

        fm.beginTransaction()
                .add(R.id.sendScreenContainer, shareFrag)
                .addToBackStack("SHARE")
                .commit();

        // see if i can move this to oncreate
        fm.addOnBackStackChangedListener(mBackListener);
    }

    private void showControls() {
        showHideArrows();
        mBottomButtons.setVisibility(View.VISIBLE);
        mBackToCameraButton.setVisibility(View.VISIBLE);
        if(slideFrags[mPager.getCurrentItem()] != null)
            slideFrags[mPager.getCurrentItem()].showSeekBar();
    }

    private void hideControls() {
        mLeftArrow.setVisibility(View.INVISIBLE);
        mRightArrow.setVisibility(View.INVISIBLE);
        mBottomButtons.setVisibility(View.INVISIBLE);
        mBackToCameraButton.setVisibility(View.INVISIBLE);
        if(slideFrags[mPager.getCurrentItem()] != null)
            slideFrags[mPager.getCurrentItem()].hideSeekBar();
    }

    private void showHideArrows() {
        int current = mPager.getCurrentItem();
        if (current == 0) {
            mLeftArrow.setVisibility(View.INVISIBLE);
        } else {
            mLeftArrow.setVisibility(View.VISIBLE);
        }

        if (current == mFiles.length - 1) {
            mRightArrow.setVisibility(View.INVISIBLE);
        } else {
            mRightArrow.setVisibility(View.VISIBLE);
        }
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

    /**
     * A simple pager adapter that represents 5 {@link ScreenSlidePageFragment} objects, in
     * sequence.
     */
    private class ScreenSlidePagerAdapter extends FragmentStatePagerAdapter {
        public ScreenSlidePagerAdapter(FragmentManager fm) {
            super(fm);
        }

        @Override
        public Fragment getItem(int position) {

            DisplayMetrics displayMetrics = getActivity().getResources().getDisplayMetrics();

            int height = new Double(displayMetrics.heightPixels * .8).intValue();
            int width = new Double(displayMetrics.widthPixels * .8).intValue();

            boolean start = false;
            if(!mFirstPlayed && position == mPager.getCurrentItem()) {
                if (mAutoStartFirstClip) start = true;

                // Go back to defaults
                mAutoStartFirstClip = true;
                mFirstPlayed = true;
            }

            ScreenSlidePageFragment frag = ScreenSlidePageFragment.create(start, width, height, mFiles[position].getAbsolutePath());
            slideFrags[position] = frag;
            return frag;
        }

        @Override
        public int getItemPosition(Object object) {
            return PagerAdapter.POSITION_NONE;
        }

        @Override
        public int getCount() {
            return mFiles.length;
        }
    }
}
