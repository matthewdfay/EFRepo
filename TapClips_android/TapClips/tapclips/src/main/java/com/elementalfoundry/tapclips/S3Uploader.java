package com.elementalfoundry.tapclips;

import android.net.Uri;
import android.os.AsyncTask;
import android.support.v4.app.FragmentActivity;
import android.util.Log;

import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.regions.Region;
import com.amazonaws.regions.Regions;
import com.amazonaws.services.s3.AmazonS3Client;
import com.amazonaws.services.s3.model.CannedAccessControlList;
import com.amazonaws.services.s3.model.PutObjectRequest;

import java.io.File;
import java.util.UUID;

/**
 * Created by mdbranth on 5/19/14.
 */
public class S3Uploader {
    private final String BUCKET_KEY = "tclip.tv";
    private final String ACCESS_KEY = "AKIAJ55WWF3KFE4JEVHA";
    private final String SECRET_KEY = "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";
    private FragmentActivity mActivity;
    private OnVideoUploadedListener mListener;

    private AmazonS3Client s3Client = new AmazonS3Client(
            new BasicAWSCredentials(ACCESS_KEY, SECRET_KEY)
    );

    public S3Uploader(FragmentActivity activity, OnVideoUploadedListener listener) {
        mActivity = activity;
        mListener = listener;
        s3Client.setRegion(Region.getRegion(Regions.US_EAST_1));
    }

    public void postVideoToS3Async(File file) {
        new S3PutObjectTask().execute(Uri.parse(file.getPath()));
    }

    public S3TaskResult postVideoToS3(File file) {
        S3TaskResult result = new S3TaskResult();

        try {
            File coverPhoto = FileManager.getCoverPhoto(file);
            File editedFile = FileManager.getEditedFile(file);
            File fileToShare = file;
            if (editedFile.exists()) {
                fileToShare = editedFile;
            }

            ClipEdit edit = new ClipEdit();
            edit.fastPlay(fileToShare.getAbsolutePath(), FileManager.getStreamableFile(file).getAbsolutePath());


            String groupId = "a_" + UUID.randomUUID();
            String clipName = "a_" + UUID.randomUUID() + ".mp4";
            String frameName = "a_" + UUID.randomUUID() + ".jpg";

            result.setClipUrl("upload/clips/" + groupId + clipName);
            result.setFrameUrl("upload/clips/" + groupId + frameName);

            PutObjectRequest por = new PutObjectRequest(
                    BUCKET_KEY, result.getClipUrl(), FileManager.getStreamableFile(file) );
            por.setCannedAcl(CannedAccessControlList.PublicRead);
            s3Client.putObject(por);

            PutObjectRequest por2 = new PutObjectRequest(
                    BUCKET_KEY, result.getFrameUrl(), coverPhoto);
            s3Client.putObject(por2);

            ClipInfoManager.ClipInfo info = ClipInfoManager.getInfoForClip(file);
            info.awsClipUrl = result.getClipUrl();
            info.awsClipFrameUrl = result.getFrameUrl();
            ClipInfoManager.saveInfoForClip(file, info);

        } catch (Exception ex) {
            Log.e("SPRIO", "Exception uploading to S3: ", ex);
            result.setErrorMessage(ex.getMessage());
        }

        return result;
    }

    private class S3PutObjectTask extends AsyncTask<Uri, Void, S3TaskResult> {
        protected S3TaskResult doInBackground(Uri... uris) {
            if (uris == null || uris.length != 1) {
                return null;
            }

            Uri selectedFile = uris[0];
            File file = new File(selectedFile.getPath());

            return postVideoToS3(file);
        }

        protected void onPostExecute(S3TaskResult result) {
            if (mListener != null) {
                if (result.getErrorMessage() == null) {
                    mListener.onVideoUploaded(result.getClipUrl(), result.getFrameUrl());
                } else {
                    mListener.onError(result.getErrorMessage());
                }
            }
        }
    }

    public class S3TaskResult {
        String errorMessage = null;
        String mClipUrl;
        String mFramUrl;

        public String getErrorMessage() {
            return errorMessage;
        }

        public void setErrorMessage(String errorMessage) {
            this.errorMessage = errorMessage;
        }

        public String getClipUrl() {
            return mClipUrl;
        }

        public void setClipUrl(String clipUrl) {
            mClipUrl = clipUrl;
        }

        public String getFrameUrl() {
            return mFramUrl;
        }

        public void setFrameUrl(String frameUrl) {
            mFramUrl = frameUrl;
        }
    }

    public interface OnVideoUploadedListener {
        public void onVideoUploaded(String videoUrl, String frameUrl);

        public void onError(String error);
    }
}
