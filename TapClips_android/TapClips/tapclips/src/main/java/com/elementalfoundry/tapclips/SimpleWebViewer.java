package com.elementalfoundry.tapclips;


import android.support.v4.app.FragmentManager;
import android.os.Bundle;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebChromeClient;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.TextView;


public class SimpleWebViewer extends Fragment {
    private static final String ARG_URL = "paramUrl";
    private static final String ARG_TITLE = "paramTitle";

    private String mUrl;
    private String mTitle;

    public static SimpleWebViewer newInstance(String url, String title) {
        SimpleWebViewer fragment = new SimpleWebViewer();
        Bundle args = new Bundle();
        args.putString(ARG_URL, url);
        args.putString(ARG_TITLE, title);
        fragment.setArguments(args);
        return fragment;
    }
    public SimpleWebViewer() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
            mUrl = getArguments().getString(ARG_URL);
            mTitle = getArguments().getString(ARG_TITLE);
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fragment_simple_web_viewer, container, false);

        TextView titleView = (TextView)v.findViewById(R.id.simpleWebViewTitle);
        titleView.setText(mTitle);

        WebView wv = (WebView)v.findViewById(R.id.simpleWebViewView);
        wv.getSettings().setJavaScriptEnabled(true);
        wv.setWebViewClient(new WebViewClient());
        wv.setWebChromeClient(new WebChromeClient());
        wv.loadUrl(mUrl);

        View done = v.findViewById(R.id.simpleWEbViewDone);
        done.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FragmentManager fm = getFragmentManager();
                fm.popBackStack();
            }
        });

        return v;
    }


}
