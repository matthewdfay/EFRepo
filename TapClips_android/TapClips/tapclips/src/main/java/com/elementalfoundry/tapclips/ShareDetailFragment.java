package com.elementalfoundry.tapclips;


import android.app.Activity;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.TextView;

import com.amazonaws.util.StringUtils;

import java.io.File;


/**
 * A simple {@link Fragment} subclass.
 * Use the {@link ShareDetailFragment#newInstance} factory method to
 * create an instance of this fragment.
 *
 */
public class ShareDetailFragment extends Fragment {
    public static final String SHARE_TYPE_FACEBOOK = "fb";
    public static final String SHARE_TYPE_TWITTER = "twitter";
    public static final String SHARE_TYPE_SPRIO = "sprio";

    private static final String ARG_TITLE = "title";
    private static final String ARG_SHARE_TYPE = "type";
    private static final String ARG_FILE_PATH = "file path";

    private String mFilePath;
    private String mTitle;
    private String mShareType;
    private File mFile;
    private GlobalEventsListener mListener;
    private String mSprioTeamID;
    private boolean mDefaultTextSet = false;

    public static ShareDetailFragment newInstance(String title, String shareType, String filePath) {
        ShareDetailFragment fragment = new ShareDetailFragment();
        Bundle args = new Bundle();
        args.putString(ARG_TITLE, title);
        args.putString(ARG_SHARE_TYPE, shareType);
        args.putString(ARG_FILE_PATH, filePath);
        fragment.setArguments(args);
        return fragment;
    }
    public ShareDetailFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mTitle = getArguments().getString(ARG_TITLE);
            mShareType = getArguments().getString(ARG_SHARE_TYPE);
            mFile = new File(getArguments().getString(ARG_FILE_PATH));
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fragment_share_detail, container, false);
        v.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // Here to prevent clicks on lower elements
            }
        });

        TextView titleView = (TextView)v.findViewById(R.id.titleTextView);
        titleView.setText("Share to " + mTitle);

        View backButton = v.findViewById(R.id.backIcon);
        backButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FragmentManager fm = getFragmentManager();
                fm.popBackStack();
            }
        });

        final EditText editText = (EditText)v.findViewById(R.id.shareText);
        editText.setOnFocusChangeListener(new View.OnFocusChangeListener() {
            @Override
            public void onFocusChange(View view, boolean b) {
                if (b) {
                    if (!mDefaultTextSet) {
                        mDefaultTextSet = true;
                        editText.setText(Settings.get().getDefaultShareText());
                    }
                }
            }
        });
        editText.addTextChangedListener(new TextWatcher() {
            String mLastSeenText = "";

            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i2, int i3) {

            }

            @Override
            public void onTextChanged(CharSequence charSequence, int start, int before, int count) {
                if (count > 0) {
                    String text = editText.getText().toString();
                    if (text.equals(mLastSeenText)) return;
                    mLastSeenText = text;
                    char lastTyped = charSequence.charAt(start + count - 1);
                    if (lastTyped == ' ') {
                        String[] words = text.split(" ");
                        boolean changeMade = false;
                        for(int i = 0; i < words.length; i++) {
                            String word = words[i];
                            if (Settings.get().getTypeaheads().containsKey(word)) {
                                words[i] = Settings.get().getTypeaheads().get(word);
                                changeMade = true;
                            }
                        }

                        if (changeMade) {
                            String newText = StringUtils.join(" ", words);
                            if (text.endsWith(" ")) newText += " ";
                            editText.setText(newText);
                            editText.setSelection(newText.length());
                        }
                    }
                }
            }

            @Override
            public void afterTextChanged(Editable editable) {

            }
        });

        View sendButton = v.findViewById(R.id.sendButton);
        sendButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String description = editText.getText().toString();
                if (mShareType.equals(SHARE_TYPE_FACEBOOK)) {
                    mListener.postToS3AndShare(mFile, description, true, false, false, null);
                } else if (mShareType.equals(SHARE_TYPE_TWITTER)) {
                    mListener.postToS3AndShare(mFile, description, false, true, false, null);
                } else if (mShareType.equals(SHARE_TYPE_SPRIO)) {
                    if(mSprioTeamID != null && !"".equals(mSprioTeamID)) {
                        mListener.postToS3AndShare(mFile, description, false, false, true, mSprioTeamID);
                    }
                }

                FragmentManager fm = getFragmentManager();
                fm.popBackStack();
                fm.popBackStack();
                fm.popBackStack();
            }
        });

        final View busyScreen = v.findViewById(R.id.busyScreen);
        busyScreen.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
            }
        });

        if (mShareType.equals(SHARE_TYPE_SPRIO)) {
            busyScreen.setVisibility(View.VISIBLE);
            SprioManager.get().chooseSprioTeam(getActivity(), new SprioManager.OnTeamChosen() {
                @Override
                public void teamChosen(String teamId) {
                    busyScreen.setVisibility(View.INVISIBLE);
                    mSprioTeamID = teamId;
                }

                @Override
                public void error() {
                    TCToast.showErrorToast("Error sharing to Sprio.", getActivity());
                    FragmentManager fm = getFragmentManager();
                    if (fm != null) fm.popBackStack();
                }

                @Override
                public void cancelled() {
                    FragmentManager fm = getFragmentManager();
                    if (fm != null) fm.popBackStack();
                }
            });
        }

        return v;
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
