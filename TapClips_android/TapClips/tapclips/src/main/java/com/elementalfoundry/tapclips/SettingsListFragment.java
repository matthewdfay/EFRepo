package com.elementalfoundry.tapclips;

import android.support.v4.app.ListFragment;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import java.util.ArrayList;

/**
 * Created by mdbranth on 5/7/14.
 */
public class SettingsListFragment extends ListFragment {
    private ArrayList<TCListItem> mItems;
    TCListAdapter mAdapter;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mItems = Settings.get().getArray();
        mAdapter = new TCListAdapter(mItems);
        setListAdapter(mAdapter);
    }

    @Override
    public void onListItemClick(ListView l, View v, int position, long id) {
        mItems.get(position).performAction(getActivity());
        mAdapter.notifyDataSetChanged();
    }

    public class TCListAdapter extends ArrayAdapter<TCListItem> {
        public TCListAdapter(ArrayList<TCListItem> items) {
            super(getActivity(), 0, items);
        }

        public View getView(int position, View convertView, ViewGroup parent) {
            try {
                TCListItem item = getItem(position);

                if (item instanceof Subtitle) {
                    Subtitle subtitle = (Subtitle)item;
                    if (convertView == null) {
                        convertView = getActivity().getLayoutInflater().inflate(R.layout.list_item_subtitle, null);
                    }

                    TextView subtitleText = (TextView) convertView.findViewById(R.id.listItemSubtitleText);
                    subtitleText.setText(subtitle.getText());
                } else if (item instanceof ToggleSetting) {
                    ToggleSetting toggle = (ToggleSetting)item;
                    if (convertView == null) {
                        convertView = getActivity().getLayoutInflater().inflate(R.layout.list_item_toggle_setting, null);
                    }

                    TextView text = (TextView) convertView.findViewById(R.id.settingText);
                    text.setText(toggle.getSet() ? toggle.getActiveDisplayString() : toggle.getDisplayString());

                    ImageView img = (ImageView) convertView.findViewById(R.id.settingImage);
                    img.setImageResource(toggle.getSet() ? toggle.getActiveIconId() : toggle.getIconId());

                    ImageView checkImg = (ImageView) convertView.findViewById(R.id.checkImage);
                    checkImg.setImageResource(toggle.getSet() ? R.drawable.checkbox_actv : R.drawable.checkbox_nrml);
                } else if (item instanceof Setting) {
                    Setting setting = (Setting)item;
                    if (convertView == null) {
                        convertView = getActivity().getLayoutInflater().inflate(R.layout.list_item_setting, null);
                    }

                    TextView text = (TextView) convertView.findViewById(R.id.settingText);
                    text.setText(setting.getDisplayString());

                    ImageView img = (ImageView) convertView.findViewById(R.id.settingImage);
                    img.setImageResource(setting.getIconId());
                }
            } catch (Exception ex) {}

            return convertView;
        }
    }

}
