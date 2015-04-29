package com.elementalfoundry.tapclips;


import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentActivity;
import android.support.v4.app.FragmentManager;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageButton;

import com.facebook.Session;
import com.facebook.SessionState;
import com.flurry.android.FlurryAgent;

import java.io.File;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;


public class ShareFragment extends Fragment {
    private static final String ARG_FILE_PATH = "file path";
    private static final String ARG_SHARE_TYPE = "share_type";
    private static final String ARG_OPEN_DETAIL = "open_share_detail";
    private String mFileName;
    private String mShareType;
    private boolean mOpenShareDetail;

    private GlobalEventsListener mListener;
    private boolean mBlockShareInteraction = false;
    private File mFile;
    private View mShareProgressBar;

    public static ShareFragment newInstance(String filePath, boolean openShareDetail, String shareType) {
        ShareFragment fragment = new ShareFragment();
        Bundle args = new Bundle();
        args.putString(ARG_FILE_PATH, filePath);
        args.putBoolean(ARG_OPEN_DETAIL, openShareDetail);
        args.putString(ARG_SHARE_TYPE, shareType);
        fragment.setArguments(args);
        return fragment;
    }
    public ShareFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mFileName = getArguments().getString(ARG_FILE_PATH);
            mOpenShareDetail = getArguments().getBoolean(ARG_OPEN_DETAIL, false);
            mShareType = getArguments().getString(ARG_SHARE_TYPE, "");
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        FlurryAgent.logEvent("Share Selected");

        mFile = new File(mFileName);

        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fragment_share, container, false);

        v.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // I'm here just to block clicks from slipping through
            }
        });

        View backButton = v.findViewById(R.id.backIcon);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FlurryAgent.logEvent("Share Canceled");
                FragmentManager fm = getFragmentManager();
                fm.popBackStack();
            }
        });

        mShareProgressBar = v.findViewById(R.id.shareProgressBar);

        final View sendEmail = v.findViewById(R.id.sendClipInEmail);
        sendEmail.setOnClickListener(new View.OnClickListener() {
            final File file = mFile;

            @Override
            public void onClick(View view) {
                if (mBlockShareInteraction) return;
                mBlockShareInteraction = true;
                mShareProgressBar.setVisibility(View.VISIBLE);

                new AsyncTask<Void, Void, Void>() {
                    private Api.GetTapClipsUrlResponse mResponse;

                    @Override
                    protected Void doInBackground(Void... nothing) {
                        Api api = new Api();
                        mResponse = (Api.GetTapClipsUrlResponse)api.MakeApiCall("/api/2.0/getTapClipsUrl", null, Api.GetTapClipsUrlResponse.class);

                        return null;
                    }

                    @Override
                    protected void onPostExecute(Void nothing) {
                        try {
                            FragmentManager fm = getFragmentManager();
                            fm.popBackStack();

                            if (mResponse != null && mResponse.success && mResponse.response.url != null && !mResponse.response.url.equals("")) {
                                Intent intent = new Intent(Intent.ACTION_SEND);
                                intent.setType("plain/text");
                                intent.putExtra(Intent.EXTRA_TEXT, mResponse.response.url + "?src=email");
                                ShareFragment.this.startActivity(Intent.createChooser(intent, ""));
                                mListener.postToS3AndUploadUrl(mResponse, mFile);
                            } else {
                                Log.e(Settings.TAG, "Error getting share url");
                                TCToast.showErrorToast("Error sharing clip.", getActivity());
                            }
                        } finally {
                            mBlockShareInteraction = false;
                            mShareProgressBar.setVisibility(View.INVISIBLE);
                            FlurryAgent.logEvent("Shared via Email");
                        }
                    }
                }.execute(null, null, null);
            }
        });

        final View sendSms = v.findViewById(R.id.sendClipInMessage);
        sendSms.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (mBlockShareInteraction) return;
                mBlockShareInteraction = true;
                mShareProgressBar.setVisibility(View.VISIBLE);

                new AsyncTask<Void, Void, Void>() {
                    private Api.GetTapClipsUrlResponse mResponse;

                    @Override
                    protected Void doInBackground(Void... nothing) {
                        Api api = new Api();
                        mResponse = (Api.GetTapClipsUrlResponse)api.MakeApiCall("/api/2.0/getTapClipsUrl", null, Api.GetTapClipsUrlResponse.class);

                        return null;
                    }

                    @Override
                    protected void onPostExecute(Void nothing) {
                        try {
                            FragmentManager fm = getFragmentManager();
                            fm.popBackStack();

                            if (mResponse != null && mResponse.success && mResponse.response.url != null && !mResponse.response.url.equals("")) {
                                Intent sendIntent = new Intent(Intent.ACTION_VIEW);
                                sendIntent.setData(Uri.parse("sms:"));
                                sendIntent.putExtra("sms_body", mResponse.response.url + "?src=txt");
                                ShareFragment.this.startActivity(sendIntent);
                                mListener.postToS3AndUploadUrl(mResponse, mFile);
                            } else {
                                Log.e(Settings.TAG, "Error getting share url");
                                TCToast.showErrorToast("Error sharing clip.", getActivity());
                            }
                        } finally {
                            mBlockShareInteraction = false;
                            mShareProgressBar.setVisibility(View.INVISIBLE);
                            FlurryAgent.logEvent("Shared via SMS");
                        }
                    }
                }.execute(null, null, null);
            }
        });

        final View saveButton = v.findViewById(R.id.saveClip);
        saveButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (mBlockShareInteraction) return;


                mBlockShareInteraction = true;
                mShareProgressBar.setVisibility(View.VISIBLE);

                new AsyncTask<Void, Void, Void>() {
                    private boolean mError = false;
                    @Override
                    protected Void doInBackground(Void... nothing) {
                        try {
                            MoveAllVideosSetting.SaveToCameraRoll(mFile, getActivity());
                            FlurryAgent.logEvent("Explicit Save to Camera Roll");
                        }
                        catch (Exception ex) {
                            mError = true;
                        }
                        return null;
                    }

                    @Override
                    protected void onPostExecute(Void nothing) {
                        if (mError) {
                            TCToast.showErrorToast("Error saving clip.", getActivity());
                        } else {
                            TCToast.showToast("Clip saved to camera roll.", getActivity());
                        }

                        mBlockShareInteraction = false;
                        mShareProgressBar.setVisibility(View.INVISIBLE);
                    }
                }.execute(null, null, null);
            }
        });

        final View facebookShareButton = v.findViewById(R.id.facebookShareButton);
        facebookShareButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openShareDetail(ShareDetailFragment.SHARE_TYPE_FACEBOOK);
            }
        });

        final View twitterShareButton = v.findViewById(R.id.twitterShareButton);
        twitterShareButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openShareDetail(ShareDetailFragment.SHARE_TYPE_TWITTER);
            }
        });

        final View sprioShareButton = v.findViewById(R.id.sprioShareButton);
        sprioShareButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openShareDetail(ShareDetailFragment.SHARE_TYPE_SPRIO);
            }
        });

        if (mOpenShareDetail) {
            openShareDetail(mShareType);
            mOpenShareDetail = false;
        }

        return v;
    }

    private void openShareDetail(String shareType) {
        if (mBlockShareInteraction) return;
        mBlockShareInteraction = true;
        if(shareType == ShareDetailFragment.SHARE_TYPE_TWITTER) {
            try {
                mListener.shareToTwitter(mFile, ShareFragment.this);
            } catch (Exception ex) {
                Log.e(Settings.TAG, "Error connecting to twitter: " + ex);
            }

            mBlockShareInteraction = false;
        } else if (shareType == ShareDetailFragment.SHARE_TYPE_FACEBOOK) {
            try {
                final FragmentActivity activity = getActivity();
                Session.openActiveSession(activity, true, new Session.StatusCallback() {

                    // callback when session changes state
                    @Override
                    public void call(Session session, SessionState state, Exception exception) {
                        if (session.isOpened()) {
                            Log.d(Settings.TAG, "********* Facebook Session opened");

                            List<String> PERMISSIONS = Arrays.asList("publish_actions");

                            // Check for publish permissions
                            List<String> permissions = session.getPermissions();
                            if (!isSubsetOf(PERMISSIONS, permissions)) {
                                Log.d(Settings.TAG, "****** Facebook Publish permission not found - asking");
                                Session.NewPermissionsRequest newPermissionsRequest = new Session.NewPermissionsRequest(
                                        getActivity(), PERMISSIONS);
                                session.requestNewPublishPermissions(newPermissionsRequest);
                                return;
                            } else {
                                Log.d(Settings.TAG, "****** Facebook Publish permission found");
                                FragmentManager fm = getFragmentManager();
                                Fragment shareDetailsFrag = ShareDetailFragment.newInstance("Facebook", ShareDetailFragment.SHARE_TYPE_FACEBOOK, mFile.getAbsolutePath());
                                fm.beginTransaction()
                                        .add(R.id.sendScreenDetailsContainer, shareDetailsFrag)
                                        .remove(ShareFragment.this)
                                        .addToBackStack(null)
                                        .commit();
                            }
                        }
                    }
                });
            } catch (Exception ex) {
                Log.e(Settings.TAG, "Error opening facebook session: ", ex);
            }

            mBlockShareInteraction = false;
        } else if (shareType == ShareDetailFragment.SHARE_TYPE_SPRIO) {
            try {
                mListener.shareToSprio(mFile, ShareFragment.this, new GlobalEventsListener.OnCompleteListener() {
                    @Override
                    public void onComplete() {
                        mBlockShareInteraction = false;
                    }

                    @Override
                    public void onError() {
                        mBlockShareInteraction = false;
                    }
                });
            } catch (Exception ex) {
                mBlockShareInteraction = false;
            }
        }


    }

    private boolean isSubsetOf(Collection<String> subset,
                               Collection<String> superset) {
        for (String string : subset) {
            if (!superset.contains(string)) {
                return false;
            }
        }
        return true;
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
}
