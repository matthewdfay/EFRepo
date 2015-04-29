package com.elementalfoundry.tapclips;


import android.app.Activity;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.ImageButton;


/**
 * A simple {@link Fragment} subclass.
 *
 */
public class TermsAndConditionsFragment extends Fragment {

    private WebView mWebView;
    private GlobalEventsListener mListener;


    public TermsAndConditionsFragment() {
        // Required empty public constructor
    }


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View v =  inflater.inflate(R.layout.fragment_terms_and_conditions, container, false);
        v.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // DO nothing - this is here to be a click blocker
            }
        });

        Button termsAndConditionsButton = (Button)v.findViewById(R.id.termsAndConditions);
        Button privacyButton = (Button)v.findViewById(R.id.privacyPolicy);

        termsAndConditionsButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Fragment frag = SimpleWebViewer.newInstance("http://tapclips.com/legal/termsofservice", "Terms of Service");
                FragmentManager fm = getFragmentManager();
                fm.beginTransaction()
                        .add(R.id.simpleWebViewContainer, frag)
                        .addToBackStack(null)
                        .commit();
            }
        });

        privacyButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Fragment frag = SimpleWebViewer.newInstance("http://tapclips.com/legal/privacy", "Privacy");
                FragmentManager fm = getFragmentManager();
                fm.beginTransaction()
                        .add(R.id.simpleWebViewContainer, frag)
                        .addToBackStack(null)
                        .commit();
            }
        });

        ImageButton doneButton = (ImageButton)v.findViewById(R.id.tcAndPDoneButton);
        doneButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mListener.onAcceptedTermsAndConditions();
            }
        });

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
