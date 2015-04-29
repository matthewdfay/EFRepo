package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentManager;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;


public class SettingsFragment extends Fragment {

    public static SettingsFragment newInstance() {
        SettingsFragment fragment = new SettingsFragment();
        Bundle args = new Bundle();
        fragment.setArguments(args);
        return fragment;
    }
    public SettingsFragment() {
        // Required empty public constructor
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        if (getArguments() != null) {
        }
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View v = inflater.inflate(R.layout.fragment_settings, container, false);
        TextView title = (TextView)v.findViewById(R.id.titleText);
        title.setText("Settings");

        FragmentManager fm = getFragmentManager();

        Fragment listFragment = fm.findFragmentById(R.id.listFragmentContainer);
        if (listFragment == null) {
            listFragment = new SettingsListFragment();
            fm.beginTransaction()
                    .add(R.id.listFragmentContainer, listFragment)
                    .commit();
        }

        return v;
    }

    public void onButtonPressed(Uri uri) {
    }

    @Override
    public void onAttach(Activity activity) {
        super.onAttach(activity);
    }

    @Override
    public void onDetach() {
        super.onDetach();
    }
}
