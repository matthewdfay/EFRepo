package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.support.v4.app.ListFragment;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;

/**
 * Created by mdbranth on 5/12/14.
 */
public class ClipsListFragment extends ListFragment {
    private ArrayList<TCListItem> mItems;
    TCListAdapter mAdapter;
    GlobalEventsListener mListener;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        buildItemsList();
        mAdapter = new TCListAdapter(mItems);
        setListAdapter(mAdapter);
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
    public void onListItemClick(ListView l, View v, int position, long id) {
        TCListItem item = mItems.get(position);
        if (item instanceof Clip) {
            mListener.onShowClip(((Clip) item).getFile(), false, null);
        }
    }

    public void notifyDataSetChanged() {
        buildItemsList();
        mAdapter.notifyDataSetChanged();
    }

    private void buildItemsList() {
        if(mItems == null) {
            mItems = new ArrayList<TCListItem>();
        }
        mItems.clear();

        File[] files = FileManager.getAllClips();

        SimpleDateFormat sdf = new SimpleDateFormat("MMMM d");
        String previousDay = null;
        for (int i = 0; i < files.length; i++) {
            File file = files[i];

            String day = sdf.format(file.lastModified());
            if (!day.equals(previousDay)) {
                mItems.add(new Subtitle(day));
                previousDay = day;
            }

            mItems.add(new Clip(file));
        }
    }

    public class TCListAdapter extends ArrayAdapter<TCListItem> {
        public TCListAdapter(ArrayList<TCListItem> items) {
            super(getActivity(), 0, items);
        }

        public View getView(int position, View convertView, ViewGroup parent) {
            TCListItem item = getItem(position);

            // TODO: put back in re-use of list items if slow
            if (item instanceof Subtitle) {
                Subtitle subtitle = (Subtitle)item;
                convertView = getActivity().getLayoutInflater().inflate(R.layout.list_item_subtitle, null);

                TextView subtitleText = (TextView) convertView.findViewById(R.id.listItemSubtitleText);
                subtitleText.setText(subtitle.getText());
            } else if (item instanceof Clip) {
                Clip clip = (Clip)item;
                convertView = getActivity().getLayoutInflater().inflate(R.layout.list_item_clip, null);
                File coverPhoto = FileManager.getThumbnail(clip.getFile());
                ImageView imageView = (ImageView)convertView.findViewById(R.id.listItemClipPreview);
                imageView.setImageURI(Uri.parse(coverPhoto.getAbsolutePath()));

                ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip((clip.getFile()));
                int seconds = (info.endTime - info.startTime) / 1000;

                TextView lengthView = (TextView)convertView.findViewById(R.id.clipLength);
                lengthView.setText(seconds + " seconds");

                TextView createdView = (TextView)convertView.findViewById(R.id.clipCreation);
                long timeSinceCreated = new Date().getTime() - clip.getFile().lastModified();
                SimpleDateFormat fmt = new SimpleDateFormat("yyyyMMdd");
                if (!fmt.format(new Date().getTime()).equals(fmt.format(clip.getFile().lastModified()))) {
                    SimpleDateFormat sdf = new SimpleDateFormat("h a");
                    createdView.setText("@ " + sdf.format(clip.getFile().lastModified()));
                } else {
                    createdView.setText(TimeUtils.millisToLongDHMS(timeSinceCreated));
                }
            }

            return convertView;
        }
    }
}
