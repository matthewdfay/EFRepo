package com.elementalfoundry.tapclips;

import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;


public class ClipsFragment extends Fragment {
    private ClipsListFragment mClipsListFragment;

    public static ClipsFragment newInstance() {
        ClipsFragment fragment = new ClipsFragment();
        Bundle args = new Bundle();
        fragment.setArguments(args);
        return fragment;
    }

    public ClipsFragment() {
    }

    public void notifyDataSetChanged() {
        if (null != mClipsListFragment) {
            mClipsListFragment.notifyDataSetChanged();
        }
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View v = inflater.inflate(R.layout.fragment_clips, container, false);
        TextView title = (TextView)v.findViewById(R.id.titleText);
        title.setText("TapClips");

        FragmentManager fm = getFragmentManager();
        mClipsListFragment = (ClipsListFragment)fm.findFragmentById(R.id.clipListFragmentContainer);
        if (mClipsListFragment == null) {
            mClipsListFragment = new ClipsListFragment();
            fm.beginTransaction()
                    .add(R.id.clipListFragmentContainer, mClipsListFragment)
                    .commit();
        }

        return v;
    }

}
