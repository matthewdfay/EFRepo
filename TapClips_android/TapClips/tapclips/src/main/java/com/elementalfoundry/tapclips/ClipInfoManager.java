package com.elementalfoundry.tapclips;

import com.google.gson.Gson;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;

/**
 * Created by mdbranth on 5/20/14.
 */
public class ClipInfoManager {

    public static ClipInfo getInfoForClip(File file) {
        ClipInfo result;
        File infoFile = getClipInfoFile(file);
        if (infoFile.exists()) {
            try {
                Gson gson = new Gson();
                StringBuilder jsonBuilder = new StringBuilder();
                BufferedReader br = new BufferedReader(new FileReader(infoFile));
                String line;

                while ((line = br.readLine()) != null) {
                    jsonBuilder.append(line);
                    jsonBuilder.append('\n');
                }

                result = gson.fromJson(jsonBuilder.toString(), ClipInfo.class);
            } catch (Exception ex) {
                result = new ClipInfo();
            }
        } else {
            result = new ClipInfo();
        }

        return result;
    }

    public static void saveInfoForClip(File clipFile, ClipInfo info) {
        try {
            Gson gson = new Gson();
            File infoFile = getClipInfoFile(clipFile);
            if(infoFile.exists()) infoFile.delete();
            infoFile.createNewFile();
            FileWriter writer = new FileWriter(infoFile);
            writer.write(gson.toJson(info));
            writer.close();
        } catch (Exception ex) {
        }
    }

    public static void deleteInfoForClip(File clipFile) {
        File infoFile = getClipInfoFile(clipFile);
        if (infoFile.exists()) {
            infoFile.delete();
        }
    }

    private static File getClipInfoFile(File clipFile) {
        String name = clipFile.getName();
        int pos = name.lastIndexOf(".");
        if (pos > 0) {
            name = name.substring(0, pos);
        }

        return new File(Settings.get().getClipDir(), name + ".json");
    }

    public static class ClipInfo {
        public String awsClipUrl;
        public String awsClipFrameUrl;
        public int startTime;
        public int endTime;
    }
}
