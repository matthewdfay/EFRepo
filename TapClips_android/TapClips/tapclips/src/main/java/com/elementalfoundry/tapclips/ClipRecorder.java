package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaCodec;
import android.media.MediaCodecInfo;
import android.media.MediaFormat;
import android.media.MediaMetadataRetriever;
import android.media.MediaMuxer;
import android.media.MediaRecorder;
import android.media.ThumbnailUtils;
import android.opengl.EGL14;
import android.opengl.EGLContext;
import android.opengl.GLSurfaceView;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.Surface;
import android.view.View;

import com.flurry.android.FlurryAgent;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.ref.WeakReference;
import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.Map;
import java.util.NoSuchElementException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import javax.microedition.khronos.opengles.GL10;

/**
 * Created by mark on 5/6/14.
 */
public class ClipRecorder implements SurfaceTexture.OnFrameAvailableListener  {
    private static String TAG = "ClipBuffer";
    private static final boolean VERBOSE = false;           // lots of logging
    private Camera mCamera;
    private Activity mActivity;

    private static final int SUGGESTED_PREVIEW_WIDTH = 640;
    private static final int SUGGESTED_PREVIEW_HEIGHT = 360;

    private CameraHandler mCameraHandler;
    private GLSurfaceView mGLView;
    private CameraSurfaceRenderer mRenderer;
    private ClipBufferManager mClipBufManager;
    private GlobalEventsListener mListener;
    private AudioClipRecorder mAudioClipRecorder;
    private ScaleGestureDetector mSGD;
    private float mScale = 0f;
    private boolean mScaling = false;
    private boolean isStarted = false;

    private int mCameraPreviewWidth, mCameraPreviewHeight;

    public ClipRecorder(Activity activity, GlobalEventsListener listener) {
        mActivity = activity;
        mListener = listener;

        mClipBufManager = new ClipBufferManager(15, listener);
        mAudioClipRecorder = new AudioClipRecorder(mClipBufManager);
        mGLView = (GLSurfaceView) mActivity.findViewById(R.id.cameraPreview_surfaceView);
        mGLView.setEGLContextClientVersion(2);
        mCameraHandler = new CameraHandler(this);
        mRenderer = new CameraSurfaceRenderer(mCameraHandler, mClipBufManager);
        mGLView.setRenderer(mRenderer);
        mGLView.setRenderMode(GLSurfaceView.RENDERMODE_WHEN_DIRTY);

        mGLView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (mScaling) {
                    mScaling = false;
                    return;
                }
                mListener.onUserTapped(mClipBufManager.requestForNewClip());
            }
        });
    }

    public void start() {
        Log.d(TAG, "+++++++++++++++++++ START");
        if (isStarted) {
            Log.w(TAG, "ClipRecorder already started. Ignoring.");
            return;
        }
        isStarted = true;
        openCamera(SUGGESTED_PREVIEW_WIDTH, SUGGESTED_PREVIEW_HEIGHT);
        mClipBufManager.start();
        mAudioClipRecorder.start();
        mGLView.onResume();
        mGLView.queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.setCameraPreviewSize(mCameraPreviewWidth, mCameraPreviewHeight);
            }
        });
    }

    public void stop() {
        if (!isStarted) {
            Log.w(TAG, "ClipRecorder not started. Ignoring.");
            return;
        }
        isStarted = false;
        Log.d(TAG, "+++++++++++++++++++ STOP");
        releaseCamera();
        mGLView.queueEvent(new Runnable() {
            @Override
            public void run() {
                mRenderer.notifyStopping();
            }
        });
        mGLView.onPause();
        mAudioClipRecorder.stop();
        mClipBufManager.stop();
    }

    public void destroy() {
        mCameraHandler.invalidateHandler();
    }

    public void setClipLength(int seconds) {
        mClipBufManager.setClipLength(seconds);
    }

    public int getClipLength(int seconds) {
        return mClipBufManager.getClipLength();
    }

    @Override
    public void onFrameAvailable(SurfaceTexture st) {
        // The SurfaceTexture uses this to signal the availability of a new frame.  The
        // thread that "owns" the external texture associated with the SurfaceTexture (which,
        // by virtue of the context being shared, *should* be either one) needs to call
        // updateTexImage() to latch the buffer.
        //
        // Once the buffer is latched, the GLSurfaceView thread can signal the encoder thread.
        // This feels backward -- we want recording to be prioritized over rendering -- but
        // since recording is only enabled some of the time it's easier to do it this way.
        //
        // Since GLSurfaceView doesn't establish a Looper, this will *probably* execute on
        // the main UI thread.  Fortunately, requestRender() can be called from any thread,
        // so it doesn't really matter.
        if (VERBOSE) Log.d(TAG, "ST onFrameAvailable");
        mGLView.requestRender();
    }

    /**
     * Handles camera operation requests from other threads.  Necessary because the Camera
     * must only be accessed from one thread.
     * <p>
     * The object is created on the UI thread, and all handlers run there.  Messages are
     * sent from other threads, using sendMessage().
     */
    static class CameraHandler extends Handler {
        public static final int MSG_SET_SURFACE_TEXTURE = 0;

        // Weak reference to the Activity; only access this from the UI thread.
        private WeakReference<ClipRecorder> mWeakRef;

        public CameraHandler(ClipRecorder rec) {
            mWeakRef = new WeakReference<ClipRecorder>(rec);
        }

        /**
         * Drop the reference to the activity.  Useful as a paranoid measure to ensure that
         * attempts to access a stale Activity through a handler are caught.
         */
        public void invalidateHandler() {
            mWeakRef.clear();
        }

        @Override  // runs on UI thread
        public void handleMessage(Message inputMessage) {
            int what = inputMessage.what;
            Log.d(TAG, "CameraHandler [" + this + "]: what=" + what);

            ClipRecorder rec = mWeakRef.get();
            if (rec == null) {
                return;
            }

            switch (what) {
                case MSG_SET_SURFACE_TEXTURE:
                    rec.handleSetSurfaceTexture((SurfaceTexture) inputMessage.obj);
                    break;
                default:
                    throw new RuntimeException("unknown msg " + what);
            }
        }
    }

    /**
     * Connects the SurfaceTexture to the Camera preview output, and starts the preview.
     */
    private void handleSetSurfaceTexture(SurfaceTexture st) {
        if (mCamera == null) {
            Log.e(TAG, "Camera is null handleSetSurfaceTexture.");
            return;
        }
        st.setOnFrameAvailableListener(this);
        try {
            mCamera.setPreviewTexture(st);
        } catch (IOException ioe) {
            throw new RuntimeException(ioe);
        }
        mCamera.startPreview();
    }

    /**
     * Attempts to find a preview size that matches the provided width and height (which
     * specify the dimensions of the encoded video).  If it fails to find a match it just
     * uses the default preview size.
     * <p>
     * TODO: should do a best-fit match.
     */
    private static void choosePreviewSize(Camera.Parameters parms, int width, int height) {
        // We should make sure that the requested MPEG size is less than the preferred
        // size, and has the same aspect ratio.
        Camera.Size ppsfv = parms.getPreferredPreviewSizeForVideo();
        if (VERBOSE && ppsfv != null) {
            Log.d(TAG, "Camera preferred preview size for video is " +
                    ppsfv.width + "x" + ppsfv.height);
        }

        for (Camera.Size size : parms.getSupportedPreviewSizes()) {
            if (size.width == width && size.height == height) {
                parms.setPreviewSize(width, height);
                return;
            }
        }

        Log.w(TAG, "Unable to set preview size to " + width + "x" + height);
        if (ppsfv != null) {
            parms.setPreviewSize(ppsfv.width, ppsfv.height);
        }
    }

    /**
     * Opens a camera, and attempts to establish preview mode at the specified width and height.
     * <p>
     * Sets mCameraPreviewWidth and mCameraPreviewHeight to the actual width/height of the preview.
     */
    private void openCamera(int desiredWidth, int desiredHeight) {
        if (mCamera != null) {
            throw new RuntimeException("camera already initialized");
        }

        Camera.CameraInfo info = new Camera.CameraInfo();

        // Try to find a front-facing camera (e.g. for videoconferencing).
        int numCameras = Camera.getNumberOfCameras();
        for (int i = 0; i < numCameras; i++) {
            Camera.getCameraInfo(i, info);
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
//                mCamera = Camera.open(i);
                break;
            }
        }
        if (mCamera == null) {
            Log.d(TAG, "No front-facing camera found; opening default");
            mCamera = Camera.open();    // opens first back-facing camera
        }
        if (mCamera == null) {
            throw new RuntimeException("Unable to open camera");
        }

        if (mActivity.getWindowManager().getDefaultDisplay().getRotation() == Surface.ROTATION_270) {
            mCamera.setDisplayOrientation(180);
        }

        final Camera.Parameters parms = mCamera.getParameters();

        choosePreviewSize(parms, desiredWidth, desiredHeight);

        // Give the camera a hint that we're recording video.  This can have a big
        // impact on frame rate.
        parms.setRecordingHint(true);

        // leave the frame rate set to default
        mCamera.setParameters(parms);

        int[] fpsRange = new int[2];
        Camera.Size mCameraPreviewSize = parms.getPreviewSize();
        parms.getPreviewFpsRange(fpsRange);
        String previewFacts = mCameraPreviewSize.width + "x" + mCameraPreviewSize.height;
        if (fpsRange[0] == fpsRange[1]) {
            previewFacts += " @" + (fpsRange[0] / 1000.0) + "fps";
        } else {
            previewFacts += " @[" + (fpsRange[0] / 1000.0) +
                    " - " + (fpsRange[1] / 1000.0) + "] fps";
        }

        mSGD = new ScaleGestureDetector(mActivity.getApplicationContext(), new ScaleGestureDetector.OnScaleGestureListener() {
            int startZoomValue = 0;
            @Override
            public boolean onScale(ScaleGestureDetector detector) {
                mScaling = true;
                mScale *= detector.getScaleFactor();
                mScale = Math.max(1f, Math.min(mScale, 5f));

                Camera.Parameters p = mCamera.getParameters();
                int zoom = new Float(p.getMaxZoom() * Math.log10(mScale)/Math.log10(5)).intValue();
                p.setZoom(zoom);
                mCamera.setParameters(p);
                return true;
            }

            @Override
            public boolean onScaleBegin(ScaleGestureDetector detector) {
                mScale *= detector.getScaleFactor();
                mScale = Math.max(1f, Math.min(mScale, 5f));
                startZoomValue = (int) ((mScale - 1.0) / 4.0 * 100.0);
                return true;
            }

            @Override
            public void onScaleEnd(ScaleGestureDetector detector) {
                mScale *= detector.getScaleFactor();
                mScale = Math.max(1f, Math.min(mScale, 5f));
                int endZoomValue = (int) ((mScale - 1.0) / 4.0 * 100.0);

                Map<String, String> articleParams = new HashMap<String, String>();
                articleParams.put("zoomPercentStart", "" + startZoomValue);
                articleParams.put("zoomPercentEnd", "" + endZoomValue);
                if (startZoomValue < endZoomValue) {
                    FlurryAgent.logEvent("Pinch zoom in", articleParams);
                } else {
                    FlurryAgent.logEvent("Pinch zoom out", articleParams);
                }
            }

        });

        mGLView.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {
                //motionEvent.setLocation(motionEvent.getRawX(), motionEvent.getRawY());
                mSGD.onTouchEvent(motionEvent);
                return false;
            }
        });

        mCameraPreviewWidth = mCameraPreviewSize.width;
        mCameraPreviewHeight = mCameraPreviewSize.height;
        Log.i(TAG, "Preview size: " + mCameraPreviewWidth + "x" + mCameraPreviewHeight);
    }

    /**
     * Stops camera preview, and releases the camera to the system.
     */
    private void releaseCamera() {
        Log.d(TAG, "releasing camera");
        if (mCamera != null) {
            mCamera.stopPreview();
            mCamera.release();
            mCamera = null;
        }
    }
}

class CameraSurfaceRenderer implements GLSurfaceView.Renderer {
    private static String TAG = "Renderer";
    private SurfaceTexture mSurfaceTexture;
    private ClipRecorder.CameraHandler mCameraHandler;
    private FullFrameRect mFullScreen;
    private final float[] mSTMatrix = new float[16];
    private int mTextureId;
    private VideoEncoder mVideoEncoder;
    private boolean isRecording;
    private ClipBufferManager mClipBufMgr;

    // width/height of the incoming camera preview frames
    private boolean mIncomingSizeUpdated;
    private int mIncomingWidth;
    private int mIncomingHeight;


    public CameraSurfaceRenderer(ClipRecorder.CameraHandler cameraHandler, ClipBufferManager clipMgr) {
        mCameraHandler = cameraHandler;
        mIncomingSizeUpdated = false;
        mIncomingWidth = mIncomingHeight = -1;
        mClipBufMgr = clipMgr;
    }

    /**
     * Records the size of the incoming camera preview frames.
     * <p>
     * It's not clear whether this is guaranteed to execute before or after onSurfaceCreated(),
     * so we assume it could go either way.  (Fortunately they both run on the same thread,
     * so we at least know that they won't execute concurrently.)
     */
    public void setCameraPreviewSize(int width, int height) {
        Log.d(TAG, "setCameraPreviewSize");
        mIncomingWidth = width;
        mIncomingHeight = height;
        mIncomingSizeUpdated = true;
    }

    @Override
    public void onSurfaceCreated(GL10 unused, javax.microedition.khronos.egl.EGLConfig config) {
        Log.d(TAG, "onSurfaceCreated");

        // Set up the texture blitter that will be used for on-screen display.  This
        // is *not* applied to the recording, because that uses a separate shader.
        mFullScreen = new FullFrameRect(
                new Texture2dProgram(Texture2dProgram.ProgramType.TEXTURE_EXT));

        mTextureId = mFullScreen.createTextureObject();

        // Create a SurfaceTexture, with an external texture, in this EGL context.  We don't
        // have a Looper in this thread -- GLSurfaceView doesn't create one -- so the frame
        // available messages will arrive on the main thread.
        mSurfaceTexture = new SurfaceTexture(mTextureId);

        if (mVideoEncoder == null) {
            mVideoEncoder = new VideoEncoder(640, 360, 6000000, mClipBufMgr);
            mVideoEncoder.start(mTextureId);
        }

        // Tell the UI thread to enable the camera preview.
        mCameraHandler.sendMessage(mCameraHandler.obtainMessage(
                ClipRecorder.CameraHandler.MSG_SET_SURFACE_TEXTURE, mSurfaceTexture));
    }

    @Override
    public void onSurfaceChanged(GL10 unused, int width, int height) {
        Log.d(TAG, "onSurfaceChanged " + width + "x" + height);
    }

    @Override
    public void onDrawFrame(GL10 unused) {
        // Latch the latest frame.  If there isn't anything new, we'll just re-use whatever
        // was there before.
        mSurfaceTexture.updateTexImage();

        if (mVideoEncoder != null) {
            if (!isRecording) {
                mVideoEncoder.updateSharedContext(EGL14.eglGetCurrentContext());
                isRecording = true;
            }
            mVideoEncoder.setTextureId(mTextureId);
            mVideoEncoder.frameAvailable(mSurfaceTexture);
        } else {
            Log.e(TAG, "No video encoder!");
        }

        // Draw the video frame.
        mSurfaceTexture.getTransformMatrix(mSTMatrix);
        mFullScreen.drawFrame(mTextureId, mSTMatrix);
    }

    public void notifyStopping() {
        if (mSurfaceTexture != null) {
            Log.d(TAG, "renderer pausing -- releasing SurfaceTexture");
            mSurfaceTexture.release();
            mSurfaceTexture = null;
        }
        if (mFullScreen != null) {
            mFullScreen.release(false);     // assume the GLSurfaceView EGL context is about
            mFullScreen = null;             //  to be destroyed
        }
        if (mVideoEncoder != null) {
            mVideoEncoder.stop();
            mVideoEncoder = null;
        }
        mIncomingWidth = mIncomingHeight = -1;
        isRecording = false;
    }

}

class VideoEncoder implements Runnable {
    private static String TAG = "Encoder";
    private int mWidth, mHeight, mBitRate;
    private EglCore mEglCore;
    private EGLContext mEglContext;
    private Object mReadyFence = new Object();      // guards ready/running
    private boolean mReady;
    private boolean mRunning;
    private volatile MessageHandler mHandler;

    private WindowSurface mInputWindowSurface;
    private FullFrameRect mFullScreen;
    private int mTextureId;

    private static final int MSG_START_RECORDING = 0;
    private static final int MSG_STOP_RECORDING = 1;
    private static final int MSG_FRAME_AVAILABLE = 2;
    private static final int MSG_SET_TEXTURE_ID = 3;
    private static final int MSG_UPDATE_SHARED_CONTEXT = 4;
    private static final int MSG_QUIT = 5;

    // core encoder variables
    private MediaCodec.BufferInfo mBufferInfo;
    private Surface mInputSurface;
    private MediaCodec mEncoder;
    private ClipBufferManager mClipBufManager;

    private static final String MIME_TYPE = "video/avc";
    private static final int FRAME_RATE = 30;
    private static final int IFRAME_INTERVAL = 1;


    public VideoEncoder(int width, int height, int bitRate, ClipBufferManager clipMgr) {
        mWidth = width;
        mHeight = height;
        mBitRate = bitRate;
        mClipBufManager = clipMgr;
    }

    public void start(int textureId) {
        Log.d(TAG, "Encoder: startRecording()");
        synchronized (mReadyFence) {
            if (mRunning) {
                Log.w(TAG, "Encoder thread already running");
                return;
            }
            mRunning = true;
            new Thread(this, "TextureMovieEncoder").start();
            while (!mReady) {
                try {
                    mReadyFence.wait();
                } catch (InterruptedException ie) {
                    // ignore
                }
            }
        }
        mHandler.sendMessage(mHandler.obtainMessage(MSG_START_RECORDING, textureId, 0, null));
    }


    public void stop() {
        mHandler.sendMessage(mHandler.obtainMessage(MSG_STOP_RECORDING));
        mHandler.sendMessage(mHandler.obtainMessage(MSG_QUIT));
    }

    public void setTextureId(int id) {
        synchronized (mReadyFence) {
            if (!mReady) {
                return;
            }
        }
        mHandler.sendMessage(mHandler.obtainMessage(MSG_SET_TEXTURE_ID, id, 0, null));
    }

    /**
     * Tells the video recorder to refresh its EGL surface.  (Call from non-encoder thread.)
     */
    public void updateSharedContext(EGLContext sharedContext) {
        mHandler.sendMessage(mHandler.obtainMessage(MSG_UPDATE_SHARED_CONTEXT, sharedContext));
    }

    public void frameAvailable(SurfaceTexture st) {
        synchronized (mReadyFence) {
            if (!mReady) {
                return;
            }
        }

        float[] transform = new float[16];      // TODO - avoid alloc every frame
        st.getTransformMatrix(transform);
        long timestamp = st.getTimestamp();
        if (timestamp == 0) {
            // Seeing this after device is toggled off/on with power button.  The
            // first frame back has a zero timestamp.
            //
            // MPEG4Writer thinks this is cause to abort() in native code, so it's very
            // important that we just ignore the frame.
            Log.w(TAG, "HEY: got SurfaceTexture with timestamp of zero");
            return;
        }

        mHandler.sendMessage(mHandler.obtainMessage(MSG_FRAME_AVAILABLE,
                (int) (timestamp >> 32), (int) timestamp, transform));
    }

    @Override
    public void run() {
        Log.d(TAG, "Encoder thread starting");
        // Establish a Looper for this thread, and define a Handler for it.
        Looper.prepare();
        synchronized (mReadyFence) {
            mHandler = new MessageHandler(this);
            mReady = true;
            mReadyFence.notify();
        }
        Looper.loop();

        Log.d(TAG, "Encoder thread exiting");
        synchronized (mReadyFence) {
            mReady = mRunning = false;
            mHandler = null;
        }
    }

    /**
     * Handles encoder state change requests.  The handler is created on the encoder thread.
     */
    private static class MessageHandler extends Handler {
        private WeakReference<VideoEncoder> mWeakEncoder;

        public MessageHandler(VideoEncoder encoder) {
            mWeakEncoder = new WeakReference<VideoEncoder>(encoder);
        }

        @Override  // runs on encoder thread
        public void handleMessage(Message inputMessage) {
            int what = inputMessage.what;
            Object obj = inputMessage.obj;

            VideoEncoder encoder = mWeakEncoder.get();
            if (encoder == null) {
                Log.w(TAG, "EncoderHandler.handleMessage: encoder is null");
                return;
            }

            switch (what) {
                case MSG_START_RECORDING:
                    Log.d(TAG, "*** MSG_START_RECORDING");
                    encoder.handleStartRecording(inputMessage.arg1);
                    break;
                case MSG_FRAME_AVAILABLE:
                    long timestamp = (((long) inputMessage.arg1) << 32) |
                            (((long) inputMessage.arg2) & 0xffffffffL);
                    encoder.handleFrameAvailable((float[]) obj, timestamp);
                    break;
                case MSG_SET_TEXTURE_ID:
                    encoder.handleSetTexture(inputMessage.arg1);
                    break;
                case MSG_UPDATE_SHARED_CONTEXT:
                    encoder.handleUpdateSharedContext((EGLContext) inputMessage.obj);
                    break;
                case MSG_STOP_RECORDING:
                    Log.d(TAG, "*** MSG_STOP_RECORDING");
                    encoder.handleStopRecording();
                    break;
                case MSG_QUIT:
                    Log.d(TAG, "*** MSG_QUIT");
                    Looper.myLooper().quit();
                    break;
                default:
                    throw new RuntimeException("Unhandled msg what=" + what);
            }
        }
    }

    private void handleSetTexture(int id) {
        //Log.d(TAG, "handleSetTexture " + id);
        mTextureId = id;
    }

    private void handleStartRecording(int textureId) {
        mTextureId = textureId;
        mBufferInfo = new MediaCodec.BufferInfo();
        MediaFormat format = MediaFormat.createVideoFormat(MIME_TYPE, mWidth, mHeight);
        format.setInteger(MediaFormat.KEY_COLOR_FORMAT,
                MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface);
        format.setInteger(MediaFormat.KEY_BIT_RATE, mBitRate);
        format.setInteger(MediaFormat.KEY_FRAME_RATE, FRAME_RATE);
        format.setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, IFRAME_INTERVAL);

        mEncoder = MediaCodec.createEncoderByType(MIME_TYPE);
        mEncoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);
        mInputSurface = mEncoder.createInputSurface();
        mEncoder.start();
    }

    private void handleFrameAvailable(float[] transform, long timestampNanos) {
        drainEncoder(false);
        mFullScreen.drawFrame(mTextureId, transform);
        mInputWindowSurface.setPresentationTime(timestampNanos);
        mInputWindowSurface.swapBuffers();
    }

    private void handleUpdateSharedContext(EGLContext newSharedContext) {
        Log.d(TAG, "handleUpdatedSharedContext " + newSharedContext);

        try {
            if (mInputWindowSurface == null) {
                mEglCore = new EglCore(newSharedContext, EglCore.FLAG_RECORDABLE);
                mInputWindowSurface = new WindowSurface(mEglCore, mInputSurface, true);
            } else {
                mInputWindowSurface.releaseEglSurface();
                mFullScreen.release(false);
                mEglCore.release();
                mEglCore = new EglCore(newSharedContext, EglCore.FLAG_RECORDABLE);
                mInputWindowSurface.recreate(mEglCore);
            }
            mInputWindowSurface.makeCurrent();

            mFullScreen = new FullFrameRect(
                    new Texture2dProgram(Texture2dProgram.ProgramType.TEXTURE_EXT));
        } catch (Exception e) {
            Log.e(TAG, "handleUpdatedSharedContext failed! " + e.getMessage());
        }
    }

    private void handleStopRecording() {
        drainEncoder(true);
        if (mEncoder != null) {
            mEncoder.stop();
            mEncoder.release();
            mEncoder = null;
        }
        if (mInputWindowSurface != null) {
            mInputWindowSurface.release();
            mInputWindowSurface = null;
        }
        if (mFullScreen != null) {
            mFullScreen.release(false);
            mFullScreen = null;
        }
        if (mEglCore != null) {
            mEglCore.release();
            mEglCore = null;
        }
    }

    public void drainEncoder(boolean endOfStream) {
        final int TIMEOUT_USEC = 10000;

        try {
            if (endOfStream) {
                mEncoder.signalEndOfInputStream();
            }

            ByteBuffer[] encoderOutputBuffers = mEncoder.getOutputBuffers();
            while (true) {
                int encoderStatus = mEncoder.dequeueOutputBuffer(mBufferInfo, TIMEOUT_USEC);
                if (encoderStatus == MediaCodec.INFO_TRY_AGAIN_LATER) {
                    // no output available yet
                    if (!endOfStream) {
                        break;      // out of while
                    }
                } else if (encoderStatus == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
                    // not expected for an encoder
                    encoderOutputBuffers = mEncoder.getOutputBuffers();
                } else if (encoderStatus == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    MediaFormat format = mEncoder.getOutputFormat();
                    mClipBufManager.setVideoFormat(format);
                    Log.w(TAG, "Video format set " + format.getString(MediaFormat.KEY_MIME));
                } else if (encoderStatus < 0) {
                    Log.w(TAG, "unexpected result from encoder.dequeueOutputBuffer: " +
                            encoderStatus);
                    // let's ignore it
                } else {
                    ByteBuffer encodedData = encoderOutputBuffers[encoderStatus];
                    if (encodedData == null) {
                        throw new RuntimeException("encoderOutputBuffer " + encoderStatus +
                                " was null");
                    }

                    if ((mBufferInfo.flags & MediaCodec.BUFFER_FLAG_CODEC_CONFIG) != 0) {
                        // The codec config data was pulled out and fed to the muxer when we got
                        // the INFO_OUTPUT_FORMAT_CHANGED status.  Ignore it.
                        mBufferInfo.size = 0;
                    }

                    if (mBufferInfo.size != 0) {
                        // adjust the ByteBuffer values to match BufferInfo (not needed?)
                        encodedData.position(mBufferInfo.offset);
                        encodedData.limit(mBufferInfo.offset + mBufferInfo.size);

                        mClipBufManager.appendVideoBuffer(encodedData, mBufferInfo);
                    }

                    mEncoder.releaseOutputBuffer(encoderStatus, false);

                    if ((mBufferInfo.flags & MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) {
                        if (!endOfStream) {
                            Log.w(TAG, "reached end of stream unexpectedly");
                        } else {
                            Log.d(TAG, "end of stream reached");
                        }
                        break;      // out of while
                    }
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Drain encoder exception " + e.getMessage());
            Log.e(TAG, e.getStackTrace().toString());
        }
    }
}

class AudioClipRecorder {
    private static final String TAG = "AudioClipRecorder";
    private MediaFormat mAudioFormat;
    private ClipBufferManager mClipBufMgr;
    private MediaCodec.BufferInfo mBufferInfo;
    private MediaCodec mAudioEncoder;
    private EncoderThread mEncoderThread;
    private AudioRecord mAudioRecord;
    private boolean isRunning;
    private int mBufSize;

    private static final String AUDIO_MIME_TYPE = "audio/mp4a-latm";

    public AudioClipRecorder(ClipBufferManager clipMgr) {
        mClipBufMgr = clipMgr;
        mBufferInfo = new MediaCodec.BufferInfo();
        mEncoderThread = new EncoderThread();
    }

    public void start() {
        MediaFormat configFormat = new MediaFormat();
        configFormat.setString(MediaFormat.KEY_MIME, AUDIO_MIME_TYPE);
        configFormat.setInteger(MediaFormat.KEY_AAC_PROFILE, MediaCodecInfo.CodecProfileLevel.AACObjectLC);
        configFormat.setInteger(MediaFormat.KEY_SAMPLE_RATE, 44100);
        configFormat.setInteger(MediaFormat.KEY_CHANNEL_COUNT, 1);
        configFormat.setInteger(MediaFormat.KEY_BIT_RATE, 128000);
        configFormat.setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16384);
        mAudioEncoder = MediaCodec.createEncoderByType(AUDIO_MIME_TYPE);
        mAudioEncoder.configure(configFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE);

        mAudioEncoder.start();
        int sampleRateInHz = 44100;
        int channelConfig = AudioFormat.CHANNEL_IN_MONO;
        int audioFormat = AudioFormat.ENCODING_PCM_16BIT;
        mBufSize = AudioRecord.getMinBufferSize(sampleRateInHz, channelConfig, audioFormat);
        mAudioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, sampleRateInHz, channelConfig, audioFormat, mBufSize *5);
        mAudioRecord.startRecording();

        mEncoderThread.start();
    }

    public void stop() {
        isRunning = false;
    }

    class EncoderThread {
        public void start() {
            (new Thread(new Runnable() {
                @Override
                public void run() {
                    Log.d(TAG, "ENCODER THREAD STARTED");
                    isRunning = true;
                    ByteBuffer buf = ByteBuffer.allocateDirect(mBufSize);
                    while (isRunning) {
                        buf.clear();
                        int length = mAudioRecord.read(buf, mBufSize);
                        encodeAudioFrame(buf, length);
                    }
                    Log.d(TAG, "Audio encoder exit");
                    mAudioEncoder.stop();
                    mAudioEncoder.release();
                    mAudioRecord.stop();
                    mAudioRecord.release();
                }
            })).start();
        }
    }

    public void encodeAudioFrame(ByteBuffer input, int length) {
        final int TIMEOUT_USEC = 10000;

        try {
            ByteBuffer[] inputBuffers = mAudioEncoder.getInputBuffers();
            ByteBuffer[] outputBuffers = mAudioEncoder.getOutputBuffers();
            int inputBufferIndex = mAudioEncoder.dequeueInputBuffer(-1);
            if (inputBufferIndex >= 0) {
                ByteBuffer inputBuffer = inputBuffers[inputBufferIndex];
                inputBuffer.clear();
                inputBuffer.put(input);
                mAudioEncoder.queueInputBuffer(inputBufferIndex, 0, length, System.nanoTime() / 1000, 0);
            }

            while (true) {
                int outputBufferIndex = mAudioEncoder.dequeueOutputBuffer(mBufferInfo,TIMEOUT_USEC);
                if (outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                    break;
                }
                else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED) {
                    outputBuffers = mAudioEncoder.getOutputBuffers();
                }
                else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    mClipBufMgr.setAudioFormat(mAudioFormat = mAudioEncoder.getOutputFormat());
                }
                else if (outputBufferIndex < 0) {
                    Log.e(TAG, "Unexpected status from dequeueOutputBuffer audio " + outputBufferIndex);
                } else {
                    ByteBuffer outputBuffer = outputBuffers[outputBufferIndex];
                    outputBuffer.position(mBufferInfo.offset);
                    outputBuffer.limit(mBufferInfo.offset + mBufferInfo.size);
                    mClipBufMgr.appendAudioBuffer(outputBuffer, mBufferInfo);
                    mAudioEncoder.releaseOutputBuffer(outputBufferIndex, false);
                }
            }
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }
}
class ClipBufferManager {
    private static String TAG = "ClipBufMgr";
    private int largeBufSize = 250000;
    private int mediumBufSize = 120000;
    private int smallBufSize = 60000;
    private int tinyBufSize = 1000; // for Audio
    private int largePoolMaxSize = largeBufSize * 5;
    private int mediumPoolMaxSize = mediumBufSize * 25;
    private int smallPoolMaxSize = smallBufSize * 500;
    private int tinyPoolMaxSize = tinyBufSize * 1000;
    private int largeAllocated = 0;
    private int mediumAllocated = 0;
    private int smallAllocated = 0;
    private int tinyAllocated = 0;
    private int totalBytesAllocated = 0;
    private int totalBytesBuffered = 0;

    private LinkedList largeBufList;
    private LinkedList mediumBufList;
    private LinkedList smallBufList;
    private LinkedList tinyBufList;
    private LinkedList videoList;
    private LinkedList videoHoldingList;
    private LinkedList audioList;
    private LinkedList audioHoldingList;
    private WriterThread mWriterThread;
    private WaitNotify mWaitNotify;
    private int maxSeconds;
    private AtomicInteger currentClipLength = new AtomicInteger();
    private MediaFormat mVideoFormat;
    private MediaFormat mAudioFormat;
    private boolean isBuffering;
    private GlobalEventsListener mListener;
    private long videoSyncFrameCount = 0;
    private AtomicLong clipEndTime;
    private AtomicBoolean isWritingClip;

    public ClipBufferManager(int maxSecondsToBuffer, GlobalEventsListener listener) {
        mListener = listener;
        maxSeconds = maxSecondsToBuffer;
        currentClipLength.set(0);

        largeBufList = new LinkedList();
        mediumBufList = new LinkedList();
        smallBufList = new LinkedList();
        tinyBufList = new LinkedList();

        videoList = new LinkedList();
        videoHoldingList = new LinkedList();
        audioList = new LinkedList();
        audioHoldingList = new LinkedList();

        mWriterThread = new WriterThread();
        mWaitNotify = new WaitNotify();
        clipEndTime = new AtomicLong();
        clipEndTime.set(Long.MAX_VALUE);
        isWritingClip = new AtomicBoolean();
        isWritingClip.set(false);
    }

    public void start() {
        Log.d(TAG, "ClipBufManager started **********************  Length " + videoList.size());
        isBuffering = true;
        cleanUpBuffers();
        mWriterThread.start();
        videoSyncFrameCount = 0;
    }

    public void stop() {
        Log.d(TAG, "ClipBufManager stopped **********************  Length " + videoList.size());
        isBuffering = false;
        cleanUpBuffers();
        mWaitNotify.doNotify();
    }

    public void cleanUpBuffers() {
        EncodedBuffer buf;
        if (isWritingClip.get()) {
            // can't touch the buffers if we're in the middle of writing clip
            return;
        }
        while (videoList.size() != 0) {
            buf = removeFirst(videoList);
            freeBuffer(buf);
        }
        while (videoHoldingList.size() != 0) {
            buf = removeFirst(videoHoldingList);
            freeBuffer(buf);
        }
        while (audioList.size() != 0) {
            buf = removeFirst(audioList);
            freeBuffer(buf);
        }
        while (audioHoldingList.size() != 0) {
            buf = removeFirst(audioHoldingList);
            freeBuffer(buf);
        }
    }

    public void setVideoFormat(MediaFormat format) {
        Log.d(TAG, "Video format changed: " + format);
        mVideoFormat = format;
    }

    public void setAudioFormat(MediaFormat format) {
        Log.d(TAG, "Audio format changed: " + format);
        mAudioFormat = format;
    }

    public void setClipLength(int seconds) {
        Log.d(TAG, "Clip length set to seconds: " + seconds);
        maxSeconds = seconds;
    }

    public int getClipLength() {
        return maxSeconds;
    }

    public int requestForNewClip() {
        if (!isBuffering) return GlobalEventsListener.CLIP_RECORDER_NOT_RECORDING;
        if (isWritingClip.get()) {
            Log.w(TAG, "Busy writing clip");
            return GlobalEventsListener.CLIP_RECORDER_BUSY_WRITING;
        }
        if (currentClipLength.get() < 2) return GlobalEventsListener.CLIP_RECORDER_BUSY_WRITING;
        long delayInNanoseconds = Settings.get().getDefaultPostTapDelayMs() * 1000000;
        long currentValue = clipEndTime.getAndSet((System.nanoTime() + delayInNanoseconds) / 1000); // in microseconds
        return currentValue == Long.MAX_VALUE ? GlobalEventsListener.CLIP_RECORDER_END_TIME_SET :
                GlobalEventsListener.CLIP_RECORDER_END_TIME_RESET;
    }

    public void appendVideoBuffer(ByteBuffer data, MediaCodec.BufferInfo bufferInfo) {
        boolean isSyncFrame = (bufferInfo.flags & MediaCodec.BUFFER_FLAG_SYNC_FRAME) != 0;
        if (isSyncFrame) {
            videoSyncFrameCount++;
            if (videoSyncFrameCount == 2) {
                mListener.onStartSaving();
            }
        }
        if (videoSyncFrameCount < 2) return;
        appendBuffer(videoList, videoHoldingList, data, bufferInfo);
    }

    public void appendAudioBuffer(ByteBuffer data, MediaCodec.BufferInfo bufferInfo) {
        appendBuffer(audioList, audioHoldingList, data, bufferInfo);
    }

    public void appendBuffer(LinkedList avList, LinkedList avHoldingList, ByteBuffer data, MediaCodec.BufferInfo bufferInfo) {
        if (!isBuffering) return;
        EncodedBuffer newBuf = getBuffer(data, bufferInfo);
        if (newBuf == null) {
            Log.e(TAG, "Encoded buffer was too large or allocation failed" + bufferInfo.size);
            return;
        }
        if (clipEndTime.get() <= bufferInfo.presentationTimeUs) {
            // Notify writer thread to write new clip
            clipEndTime.set(Long.MAX_VALUE);
            isWritingClip.set(true);
            mWaitNotify.doNotify();
        }
        if (isWritingClip.get()) {
            avHoldingList.addLast(newBuf);
        } else {
            while (avHoldingList.size() != 0) {
                EncodedBuffer buf = removeFirst(avHoldingList);
                totalBytesBuffered += buf.byteBuf.capacity();
                avList.addLast(buf);
            }

            avList.addLast(newBuf);
            totalBytesBuffered += newBuf.byteBuf.capacity();
            long currentLength = Long.MAX_VALUE;
            while (currentLength > maxSeconds) {
                EncodedBuffer oldBuf = (EncodedBuffer) avList.peekFirst();
                if (oldBuf == null) {
                    // should never happen
                    break;
                }
                currentLength = (newBuf.bufferInfo.presentationTimeUs -
                        oldBuf.bufferInfo.presentationTimeUs) / 1000000;

                if (currentLength > maxSeconds) {
                    removeFirst(avList);
                    totalBytesBuffered -= oldBuf.byteBuf.capacity();
                    freeBuffer(oldBuf);
                }
            }
            if (avList == videoList) {
                EncodedBuffer oldBuf = (EncodedBuffer) videoList.peekFirst();
                if (oldBuf != null) {
                    currentClipLength.set((int)((newBuf.bufferInfo.presentationTimeUs -
                                                oldBuf.bufferInfo.presentationTimeUs) / 1000000));
                }
            }
        }
    }

    class WriterThread {
        public void start() {
            (new Thread(new Runnable() {
                @Override
                public void run() {
                    while (isBuffering) {
                        mWaitNotify.doWait();
                        if (!isWritingClip.get() || !isBuffering) continue;
                        try {
                            if (mVideoFormat == null) {
                                Log.e(TAG, "Can't write clip, video format not set");
                            } else {
                                writeClip();
                            }
                        } catch (Exception e) {
                            Log.e(TAG, e.getMessage());
                        } finally {
                            isWritingClip.set(false);
                        }
                    }
                    Log.d(TAG,"Writer thread exiting");
                }
            })).start();
        }

        public void writeClip() {
            MediaMuxer mMuxer;
            int videoTrackIndex;
            int audioTrackIndex;
            String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());
            long firstSyncFrameTime = Long.MIN_VALUE;
            long lastVideoFrameTime = Long.MIN_VALUE;
            long startTime = System.nanoTime();
            long lastAudioFrameTime = Long.MIN_VALUE;
            String saveTimeStamp = null;
            MediaMetadataRetriever retriever = null;

            // Garbage collect here
            System.gc();

            String videoFile = FileManager.getVideoPath(timeStamp);

            try {
                mMuxer = new MediaMuxer(videoFile, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
            } catch (IOException ioe) {
                Log.e(TAG, ioe.getMessage());
                return;
            }
            videoTrackIndex = mMuxer.addTrack(mVideoFormat);
            audioTrackIndex = mMuxer.addTrack(mAudioFormat);
            mMuxer.start();
            Iterator it = videoList.iterator();
            while (it.hasNext()) {
                EncodedBuffer buf = (EncodedBuffer) it.next();
                if (firstSyncFrameTime == Long.MIN_VALUE) {
                    if ((buf.bufferInfo.flags & MediaCodec.BUFFER_FLAG_SYNC_FRAME) == 0) continue;
                    firstSyncFrameTime = buf.bufferInfo.presentationTimeUs;
                }
                lastVideoFrameTime = buf.bufferInfo.presentationTimeUs;
                mMuxer.writeSampleData(videoTrackIndex, buf.byteBuf, buf.bufferInfo);
            }
            it = audioList.iterator();
            while (it.hasNext()) {
                EncodedBuffer buf = (EncodedBuffer) it.next();
                if (buf.bufferInfo.presentationTimeUs > lastVideoFrameTime) break;
                if (buf.bufferInfo.presentationTimeUs < firstSyncFrameTime) {
                    continue;
                }
                if (buf.bufferInfo.presentationTimeUs < lastAudioFrameTime) {
                    continue;
                }
                lastAudioFrameTime = buf.bufferInfo.presentationTimeUs;
                mMuxer.writeSampleData(audioTrackIndex, buf.byteBuf, buf.bufferInfo);
            }
            long writingTime = System.nanoTime() - startTime;
            int duration = 0;

            try {
                mMuxer.stop();
                mMuxer.release();
                saveTimeStamp = timeStamp;
                retriever = new MediaMetadataRetriever();
                retriever.setDataSource(videoFile);
                String time = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION);
                duration = Integer.parseInt(time);
                FileOutputStream coverStream = new FileOutputStream(FileManager.getCoverPhotoPath(timeStamp));
                FileOutputStream thumbnailStream = new FileOutputStream(FileManager.getThumbPath(timeStamp));
                Bitmap cover = retriever.getFrameAtTime((maxSeconds - 3) * 1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC);
                cover.compress(Bitmap.CompressFormat.JPEG, 100, coverStream);
                Bitmap thumbnail = ThumbnailUtils.extractThumbnail(cover, 200, 112);
                thumbnail.compress(Bitmap.CompressFormat.JPEG, 100, thumbnailStream);
                try {
                    coverStream.close();
                    thumbnailStream.close();
                } catch (IOException e) {
                    Log.e(TAG, e.getMessage());
                }
            } catch (FileNotFoundException  fe) {
                Log.e(TAG, fe.getMessage());
            } finally {
                try {
                    if (retriever != null) retriever.release();
                    if (saveTimeStamp == null) {
                        Log.w(TAG, "Deleting clip because of some error. " + videoFile);
                        FileManager.deleteClip(new File(videoFile));
                    }
                    mListener.clipSaved(saveTimeStamp, duration);
                } catch (Exception e2) {
                    Log.e(TAG, e2.getMessage());
                }
            }
        }
    }

    private EncodedBuffer getBuffer(ByteBuffer data, MediaCodec.BufferInfo bufferInfo) {
        //          Log.d(TAG, "GET Buf " + bufferInfo.size);
        LinkedList bufList;
        int allocSize;
        int size = bufferInfo.size;
        if (size < tinyBufSize) {
            bufList = tinyBufList;
            allocSize = tinyBufSize;
        } else if (size < smallBufSize) {
            bufList = smallBufList;
            allocSize = smallBufSize;
        } else if (size < mediumBufSize) {
            bufList = mediumBufList;
            allocSize = mediumBufSize;
        } else if (size < largeBufSize) {
            bufList = largeBufList;
            allocSize = largeBufSize;
        } else {
            return null;
        }
        EncodedBuffer buf = removeFirst(bufList);
        if (buf == null) {
            buf = new EncodedBuffer(allocSize);
            if (buf == null || buf.byteBuf == null || buf.bufferInfo == null) return null;
            if (allocSize == tinyBufSize) tinyAllocated += allocSize;
            if (allocSize == smallBufSize) smallAllocated += allocSize;
            if (allocSize == mediumBufSize) mediumAllocated += allocSize;
            if (allocSize == largeBufSize) largeAllocated += allocSize;
        }
        buf.bufferInfo.set(bufferInfo.offset, bufferInfo.size, bufferInfo.presentationTimeUs, bufferInfo.flags);
        buf.byteBuf.clear();
        buf.byteBuf.put(data);
        return buf;
    }

    private void freeBuffer(EncodedBuffer buf) {
        if (buf.byteBuf.capacity() == tinyBufSize) {
            if (tinyAllocated < tinyPoolMaxSize) {
                tinyBufList.add(buf);
            } else {
                tinyAllocated -= tinyBufSize;
                totalBytesAllocated -= tinyBufSize;
            }
        }
        else if (buf.byteBuf.capacity() == smallBufSize) {
            if (smallAllocated < smallPoolMaxSize) {
                smallBufList.add(buf);
            } else {
                smallAllocated -= smallBufSize;
                totalBytesAllocated -= smallBufSize;
            }
        }
        else if (buf.byteBuf.capacity() == mediumBufSize) {
            if (mediumAllocated < mediumPoolMaxSize) {
                mediumBufList.add(buf);
            } else {
                mediumAllocated -= mediumBufSize;
                totalBytesAllocated -= mediumBufSize;
            }
        }
        else if (buf.byteBuf.capacity() == largeBufSize) {
            if (largeAllocated < largePoolMaxSize) {
                largeBufList.add(buf);
            } else {
                largeAllocated -= largeBufSize;
                totalBytesAllocated -= largeBufSize;
            }
        }
        else throw new RuntimeException("Incorrect buffer capacity " + buf.byteBuf.capacity());
    }

    private class EncodedBuffer {
        public MediaCodec.BufferInfo bufferInfo = null;
        public ByteBuffer byteBuf = null;

        public EncodedBuffer(int size) {
            //Log.d(TAG, "" + size + " t:" + tinyAllocated + " s:" + smallAllocated + " m:" + mediumAllocated + " l:" + largeAllocated + " =" + totalBytesAllocated + " >" + totalBytesBuffered);
            try {
                byteBuf = ByteBuffer.allocateDirect(size);
                bufferInfo = new MediaCodec.BufferInfo();
                totalBytesAllocated += size;
            } catch (Exception e) {
                Log.e(TAG, e.getMessage());
                System.gc();
            }
        }
    }

    private EncodedBuffer removeFirst(LinkedList l) {
        try {
            return (EncodedBuffer) l.removeFirst();
        } catch (NoSuchElementException e) {
            return null;
        }
    }

    private EncodedBuffer getFirst(LinkedList l) {
        try {
            return (EncodedBuffer) l.getFirst();
        } catch (NoSuchElementException e) {
            return null;
        }
    }

    private EncodedBuffer getLast(LinkedList l) {
        try {
            return (EncodedBuffer) l.getLast();
        } catch (NoSuchElementException e) {
            return null;
        }
    }

    private class MonitorObject {}
    private class WaitNotify{
        MonitorObject myMonitorObject = new MonitorObject();
        boolean wasSignalled = false;

        public void doWait(){
            synchronized(myMonitorObject){
                while(!wasSignalled){
                    try{
                        myMonitorObject.wait();
                    } catch(InterruptedException e)  {

                    }
                }
                //clear signal and continue running.
                wasSignalled = false;
            }
        }

        public void doNotify(){
            synchronized(myMonitorObject){
                wasSignalled = true;
                myMonitorObject.notify();
            }
        }
    }

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
            Log.d(TAG, "CREATE");
            if (! mediaStorageDir.mkdirs()) {
                Log.d("CameraSample", "failed to create directory");
                return null;
            }
        }
        return mediaStorageDir.getPath();
    }
}
