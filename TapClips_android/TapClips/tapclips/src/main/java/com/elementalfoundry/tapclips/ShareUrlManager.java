package com.elementalfoundry.tapclips;

import android.os.AsyncTask;

/**
 * Created by mdbranth on 5/20/14.
 */
public class ShareUrlManager {
    private static ShareUrlManager sManager;

    private ShareUrlManager() {}

    public static ShareUrlManager get() {
        if (sManager == null) {
            sManager = new ShareUrlManager();
        }

        return sManager;
    }

    public void getShareUrl(final ShareUrlListener listener) {
        if(Settings.get().getClipUrl() != null && !Settings.get().getClipUrl().equals("")) {
            if(listener != null) listener.OnShareUrlRetrieved(Settings.get().getClipUrl());
            return;
        }

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
                if (mResponse == null) {
                    if(listener != null) {
                        listener.OnErrorGettingShareUrl("Unknown Error");
                    }
                    return;
                }

                if (mResponse.success) {
                    if (listener != null) {
                        listener.OnShareUrlRetrieved(mResponse.response.url);
                    }

                    Settings.get().setClipUrl(mResponse.response.url);

                    return;
                }

                if (!mResponse.success && listener != null) {
                    if (mResponse.error != null) {
                        listener.OnErrorGettingShareUrl(mResponse.error.message);
                    } else {
                        listener.OnErrorGettingShareUrl("Unknown Error");
                    }
                }
            }
        }.execute(null, null, null);
    }

    public void invalidateUrl() {
        Settings.get().setClipUrl("");
    }

    public interface ShareUrlListener {
        public void OnShareUrlRetrieved(String url);

        public void OnErrorGettingShareUrl(String message);
    }
}
