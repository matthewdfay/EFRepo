package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.media.MediaScannerConnection;
import android.os.AsyncTask;
import android.util.Log;
import android.view.View;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.UUID;

/**
 * Created by mdbranth on 6/25/14.
 */
public class MoveAllVideosSetting extends Setting {
    public MoveAllVideosSetting() {
        super(R.drawable.icon_save, "Move All Videos");
    }

    @Override
    public void performAction(final Activity context) {
        final View saving = context.findViewById(R.id.movingClipsToCameraRoll);
        saving.setVisibility(View.VISIBLE);
        saving.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {

            }
        });

        new AsyncTask<Void, Void, Void>() {
            private boolean mError = false;
            private boolean mNoClips = false;

            @Override
            protected Void doInBackground(Void... nothing) {
                File[] allClips = FileManager.getAllClips();
                if (allClips.length == 0) {
                    mNoClips = true;
                    return null;
                }

                try {
                    for (int i = 0; i < allClips.length; i++) {
                        SaveToCameraRoll(allClips[i], context);
                        FileManager.deleteClip(allClips[i]);
                    }
                } catch (Exception ex) {
                    Log.e(Settings.TAG, "Error moving clips to camera roll: ", ex);
                    mError = true;
                }

                return null;
            }

            @Override
            protected void onPostExecute(Void nothing) {
                if (mNoClips) {
                    TCToast.showErrorToast("No clips to move.", context);
                } else if (mError) {
                    TCToast.showErrorToast("Error moving clips to Camera Roll.", context);
                } else {
                    TCToast.showToast("Clips moved to Camera Roll", context);
                }
                saving.setVisibility(View.INVISIBLE);
            }
        }.execute(null, null, null);
    }

    public static void SaveToCameraRoll (File file, Activity activity) throws Exception {
        File editedFile = FileManager.getEditedFile(file);
        File fileToShare = file;
        if (editedFile.exists()) {
            fileToShare = editedFile;
        }

        File dest = new File(Settings.get().getGalleryClipDir(), UUID.randomUUID().toString() + ".mp4");
        dest.createNewFile();

        ClipEdit edit = new ClipEdit();
        edit.fastPlay(fileToShare.getAbsolutePath(), FileManager.getStreamableFile(file).getAbsolutePath());


        InputStream in = new FileInputStream(FileManager.getStreamableFile(file));
        OutputStream out = new FileOutputStream(dest);

        byte[] buf = new byte[1024];
        int len;
        while ((len = in.read(buf)) > 0) {
            out.write(buf, 0, len);
        }
        in.close();
        out.close();

        MediaScannerConnection.scanFile(activity, new String[]{dest.getAbsolutePath()}, null, null);
    }
}


