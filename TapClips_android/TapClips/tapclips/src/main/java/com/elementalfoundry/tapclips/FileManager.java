package com.elementalfoundry.tapclips;

import android.os.Environment;
import android.util.Log;

import java.io.File;
import java.io.FileFilter;
import java.util.Comparator;

/**
 * Created by mdbranth on 5/30/14.
 */
public class FileManager {

    public static File[] getAllClips() {
        File[] files = Settings.get().getClipDir().listFiles(new FileFilter() {
            @Override
            public boolean accept(File file) {
                return file.getName().startsWith("V_") && file.getName().endsWith(".mp4");
            }
        });
        java.util.Arrays.sort(files, new Comparator<File>() {
            @Override
            public int compare(File file, File file2) {
                return file.lastModified() > file2.lastModified() ? -1 : 1;
            }
        });

        return files;
    }

    public static File getEditedFile(File clip) {
        String name = getNameFromMediaFullPath(clip.getPath());
        String editedPath =  getEditedPath(name);
        return new File(editedPath);
    }

    public static File getStreamableFile(File clip) {
        String name = getNameFromMediaFullPath(clip.getPath());
        String streamablePath = getStreamablePath(name);
        return new File(streamablePath);
    }

    public static File getCoverPhoto(File clip) {
        String name = getNameFromMediaFullPath(clip.getPath());
        String ciPath = getCoverPhotoPath(name);
        return new File(ciPath);
    }

    public static File getThumbnail(File clip) {
        String name = getNameFromMediaFullPath(clip.getPath());
        String thumbPath = getThumbPath(name);
        return new File(thumbPath);
    }

    public static void deleteClip(File clip) {
        File editedFile = getEditedFile(clip);
        if(editedFile.exists()) {
            editedFile.delete();
        }

        File coverPhoto = getCoverPhoto(clip);
        if(coverPhoto.exists()) {
            coverPhoto.delete();
        }

        File thumb = getThumbnail(clip);
        if(thumb.exists()) {
            thumb.delete();
        }

        File streamable = getStreamableFile(clip);
        if(streamable.exists()) {
            streamable.delete();
        }

        ClipInfoManager.deleteInfoForClip(clip);

        clip.delete();
    }

    public static String getMediaFullPath(String path, String prefix, String name, String ext) {
        File mediaFile;
        mediaFile = new File(path + File.separator + prefix + "_" + name + "." + ext);
        return mediaFile.toString();
    }

    public static String getCoverPhotoPath(String ts) {
        return getMediaFullPath(getOutputMediaDirectory(), "C", ts, "jpg");
    }

    public static String getThumbPath(String ts) {
        return getMediaFullPath(getOutputMediaDirectory(), "T", ts, "jpg");
    }

    public static String getVideoPath(String ts) {
        return getMediaFullPath(getOutputMediaDirectory(), "V", ts, "mp4");
    }

    public static String getEditedPath(String ts) {
        return getMediaFullPath(getOutputMediaDirectory(), "E", ts, "mp4");
    }

    public static String getStreamablePath(String ts) {
        return getMediaFullPath(getOutputMediaDirectory(), "S", ts, "mp4");
    }


    public static String getNameFromMediaFullPath(String fullPath) {
        String result = null;
        try {
            File f = new File(fullPath);
            result = f.getName();
            if (result.contains("_")) {
                int index = result.indexOf("_");
                result = result.substring(index + 1);
            }

            if(result.contains(".")) {
                String[] parts2 = result.split("\\.");
                result = parts2[0];
            }
        } catch (Exception ex) {
        }

        return result;
    }

    // TODO: only do the check once
    public static String getOutputMediaDirectory(){
        // To be safe, you should check that the SDCard is mounted
        // using Environment.getExternalStorageState() before doing this.
        if (!Environment.getExternalStorageState().equalsIgnoreCase(Environment.MEDIA_MOUNTED)) {
            return  null;
        }

        File mediaStorageDir = Settings.get().getClipDir();
        // This location works best if you want the created images to be shared
        // between applications and persist after your app has been uninstalled.

        // Create the storage directory if it does not exist
        if (! mediaStorageDir.exists()){
            Log.d(Settings.TAG, "CREATE");
            if (! mediaStorageDir.mkdirs()) {
                Log.d("CameraSample", "failed to create directory");
                return null;
            }
        }
        return mediaStorageDir.getPath();
    }
}
