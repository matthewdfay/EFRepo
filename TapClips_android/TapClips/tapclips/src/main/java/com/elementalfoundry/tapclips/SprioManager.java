package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.app.Dialog;
import android.content.ActivityNotFoundException;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.AsyncTask;
import android.support.v4.app.FragmentActivity;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.TextView;

import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;

/**
 * Created by mdbranth on 6/24/14.
 */
public class SprioManager {
    private static SprioManager sManager;
    private static final String SPRIO_APP_URL = "net.sprio.androidapp";

    public static SprioManager get() {
        if (sManager == null) {
            sManager = new SprioManager();
        }

        return sManager;
    }

    private SprioManager() {
    }

    public boolean isLinked() throws Exception {
        Api api = new Api();
        Api.GetUserPreferencesResponse result = (Api.GetUserPreferencesResponse)api.MakeApiCall("/api/2.0/getUserPreferences", null, Api.GetUserPreferencesResponse.class);
        if (result != null && result.success && result.response.all.linkedServiceSprio != null && result.response.all.linkedServiceSprio.userId != null) {
            return true;
        }
        return false;
    }

    public void LinkAccount(Activity mainActivity) {
        if (appInstalled(SPRIO_APP_URL, mainActivity)) {
            PackageManager pm = mainActivity.getPackageManager();
            Intent launchIntent = pm.getLaunchIntentForPackage(SPRIO_APP_URL);

            launchIntent.putExtra("returnUrl", "tapclips://action.launch/sprioAuth");
            mainActivity.startActivity(launchIntent);
        } else {
            Uri uri = Uri.parse("market://details?id=" + SPRIO_APP_URL);
            Intent goToMarket = new Intent(Intent.ACTION_VIEW, uri);
            try {
                mainActivity.startActivity(goToMarket);
            } catch (ActivityNotFoundException e) {
                mainActivity.startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("http://play.google.com/store/apps/details?id=" + SPRIO_APP_URL)));
            }
        }
    }

    public boolean completeLinkAccount(EFUri efuri) throws Exception {
        String sprioToken = efuri.getParam("pushToken");
        Api.LinkServiceParams params = new Api.LinkServiceParams();
        params.type = "sprio-androidPush";
        Api.LinkServiceParams.SprioServiceInfo value = new Api.LinkServiceParams.SprioServiceInfo();
        value.token = sprioToken;
        params.value = value;

        Api api = new Api();
        Api.ApiResponse response = (Api.ApiResponse)api.MakeApiCall("/api/2.0/linkService", params, Api.ApiResponse.class);
        return response != null && response.success;
    }

    private boolean appInstalled(String uri, Activity mainActivity) {
        PackageManager pm = mainActivity.getPackageManager();
        boolean app_installed = false;
        try {
            pm.getPackageInfo(uri, PackageManager.GET_ACTIVITIES);
            app_installed = true;
        }
        catch (PackageManager.NameNotFoundException e) {
            app_installed = false;
        }
        return app_installed ;
    }

    public void chooseSprioTeam(final FragmentActivity mainActivity, final OnTeamChosen onTeamChosen) {
        new AsyncTask<Void, Void, Void>() {
            boolean mError = false;
            Api.GetTeamsResponse mResponse;

            protected Void doInBackground(Void... nothing) {
                try {
                    Api api = new Api();
                    mResponse = (Api.GetTeamsResponse)api.MakeApiCall("/api/2.0/getTeams", null, Api.GetTeamsResponse.class);
                } catch (Exception ex) {
                    mError = true;
                }

                return null;
            }

            protected void onPostExecute(Void nothing) {
                try {
                    if (!mError && mResponse != null && mResponse.success) {
                        final ArrayList<Api.GetTeamsResponse.Team> teams = new ArrayList<Api.GetTeamsResponse.Team>(Arrays.asList(mResponse.response));
                        if (teams.size() == 1) {
                            onTeamChosen.teamChosen(teams.get(0).properties._id);
                            return;
                        }

                        if (teams.size() == 0) {
                            TCToast.showErrorToast("You must have at least one team setup on Sprio.", mainActivity);
                            onTeamChosen.cancelled();
                            return;
                        }

                        final Dialog dialog = new Dialog(mainActivity);
                        dialog.setContentView(R.layout.simple_list);
                        dialog.setTitle("Choose Sprio Team");
                        ListView listView = (ListView) dialog.findViewById(R.id.list);


                        SprioTeamAdapter adapter = new SprioTeamAdapter(mainActivity, teams);
                        listView.setAdapter(adapter);

                        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
                            @Override
                            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                                dialog.dismiss();
                                onTeamChosen.teamChosen(teams.get(i).properties._id);
                            }
                        });

                        dialog.setOnCancelListener(new DialogInterface.OnCancelListener() {
                            @Override
                            public void onCancel(DialogInterface dialogInterface) {
                                onTeamChosen.cancelled();
                            }
                        });

                        dialog.show();

                    } else {
                        onTeamChosen.error();
                    }
                } catch (Exception ex) {
                    onTeamChosen.error();
                }
            }

        }.execute(null, null, null);
    }

    public interface OnTeamChosen {
        public void teamChosen(String teamId);

        public void error();

        public void cancelled();
    }

    public class SprioTeamAdapter extends ArrayAdapter<Api.GetTeamsResponse.Team> {
        Activity mActivity;

        public SprioTeamAdapter(Activity activity, ArrayList<Api.GetTeamsResponse.Team> items) {
            super(activity, 0, items);
            mActivity = activity;
        }

        public View getView(int position, View convertView, ViewGroup parent) {
            try {
                final Api.GetTeamsResponse.Team item = getItem(position);

                convertView = mActivity.getLayoutInflater().inflate(R.layout.list_item_team, null);

                TextView textView = (TextView) convertView.findViewById(R.id.teamName);
                textView.setText(item.properties.moniker);

                TextView titleTextView = (TextView) convertView.findViewById(R.id.teamInfo);
                titleTextView.setText(item.properties.title);

                final ImageView imageView = (ImageView) convertView.findViewById(R.id.teamIcon);

                new AsyncTask<Void, Void, Void>() {
                    Bitmap image = null;

                    protected Void doInBackground(Void... nothing) {
                        try {
                            String iconUrl = item.properties.icon;
                            iconUrl = iconUrl.replace("https:https:", "https:"); // Hack for issue on my local machine
                            URL url = new URL(iconUrl);
                            image = BitmapFactory.decodeStream(url.openConnection().getInputStream());
                        } catch (Exception ex) {
                            Log.d("SPRIO", "Exception downloading image: ", ex);
                        }

                        return null;
                    }

                    protected void onPostExecute(Void nothing) {
                        if (image != null) {
                            try {
                                imageView.setImageBitmap(image);
                            } catch (Exception ex) {

                            }
                        }

                    }
                }.execute(null, null, null);
            } catch (Exception ex) {
                Log.e("SPRIO", "Exception getting team list item: ", ex);
            }

            return convertView;
        }
    }
}
