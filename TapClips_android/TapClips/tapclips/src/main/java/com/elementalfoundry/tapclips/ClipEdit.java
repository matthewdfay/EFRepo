package com.elementalfoundry.tapclips;

import android.media.MediaCodec;
import android.media.MediaExtractor;
import android.media.MediaMuxer;
import android.media.MediaFormat;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.util.HashMap;

/**
 * Created by mark on 5/29/14.
 */
public class ClipEdit {
    private static String TAG = "ClipEdit";
    private int MAX_SAMPLE_SIZE = 512 * 1024;

    public boolean edit(String srcFile, String dstFile, int startTime, int endTime) throws IOException {

        System.gc();

        MediaExtractor extractor = new MediaExtractor();
        MediaMuxer muxer = new MediaMuxer(dstFile, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4);
        extractor.setDataSource(srcFile);
        int videoTrackIndex = -1;

        int trackCount = extractor.getTrackCount();

        Log.d(TAG, "trackCount:" + trackCount + " startTime:" + startTime + " endTime:" + endTime);

        // Set up the tracks.
        HashMap<Integer, Integer> indexMap = new HashMap<Integer, Integer>(trackCount);
        for (int i = 0; i < trackCount; i++) {
            extractor.selectTrack(i);
            MediaFormat format = extractor.getTrackFormat(i);
            if (format.getString(MediaFormat.KEY_MIME).equals("video/avc")) videoTrackIndex = i;
            int dstIndex = muxer.addTrack(format);
            indexMap.put(i, dstIndex);
        }

        boolean sawEOS = false;
        int bufferSize = MAX_SAMPLE_SIZE;
        int offset = 100;
        ByteBuffer dstBuf = ByteBuffer.allocate(bufferSize);
        MediaCodec.BufferInfo bufferInfo = new MediaCodec.BufferInfo();
        long presentationStartTime = Long.MIN_VALUE;
        long editStartTime = Long.MIN_VALUE;
        long editEndTime = Long.MAX_VALUE;
        boolean isWriting = false;
        long startSyncTime = Long.MIN_VALUE;
        boolean bufferData = false;
        int framesWritten = 0;

        muxer.start();
        while (!sawEOS) {
            bufferInfo.offset = offset;
            bufferInfo.size = extractor.readSampleData(dstBuf, offset);
            if (bufferInfo.size < 0) {
                sawEOS = true;
                bufferInfo.size = 0;
            } else {
                bufferInfo.presentationTimeUs = extractor.getSampleTime();
                bufferInfo.flags = extractor.getSampleFlags();
                int trackIndex = extractor.getSampleTrackIndex();
                boolean isSyncFrame = (bufferInfo.flags & MediaCodec.BUFFER_FLAG_SYNC_FRAME) != 0;
                boolean isVideoFrame = trackIndex == videoTrackIndex;

                if (presentationStartTime == Long.MIN_VALUE) {
                    presentationStartTime = bufferInfo.presentationTimeUs;
                    editStartTime = presentationStartTime + startTime * 1000;
                    editEndTime = presentationStartTime + endTime * 1000;
                    if (startTime < 500) isWriting = true;
                }
                if (!isWriting && isSyncFrame && isVideoFrame) {
                    if (startSyncTime != Long.MIN_VALUE) {
                        // Encountered another sync frame. Is our start time between them?
                        if (startSyncTime < editStartTime && editStartTime < bufferInfo.presentationTimeUs) {
                            // Seek to sync frame closest to our start time and begin writing
                            long startDiff = Math.abs(editStartTime - startSyncTime);
                            long endDiff = Math.abs(editStartTime - bufferInfo.presentationTimeUs);
                            long seekToTime = startSyncTime;
                            if (endDiff < startDiff) seekToTime = bufferInfo.presentationTimeUs;
                            isWriting = true;
                            extractor.seekTo(seekToTime, MediaExtractor.SEEK_TO_CLOSEST_SYNC);
                            continue;
                        } else {
                            startSyncTime = Long.MIN_VALUE;
                        }
                    }
                    if (startSyncTime == Long.MIN_VALUE) {
                        startSyncTime = bufferInfo.presentationTimeUs;
                    }
                }

                if (isWriting && bufferInfo.presentationTimeUs < editEndTime) {
                    muxer.writeSampleData(indexMap.get(trackIndex), dstBuf, bufferInfo);
                    framesWritten += 1;
                }
                extractor.advance();
            }
        }
        Log.d(TAG, "framesWritten:" + framesWritten);
        try {
            muxer.stop();
            muxer.release();
        } catch (IllegalStateException e) {
            Log.e(TAG, "Failed to stop muxer, framesWritten:" + framesWritten);
            Log.e(TAG, "Attempting to delete " + dstFile);
            try {
                File delFile = new File(dstFile);
                delFile.delete();
            } catch (Exception e2) {

            }
        }
        extractor.release();
        return true;
    }

    public void fastPlay(String srcFile, String dstFile)  {
        // Work around MediaMuxer bug where it writes moov box at end of file.
        RandomAccessFile inFile = null;
        FileOutputStream outFile = null;
        try {
            inFile = new RandomAccessFile(new File(srcFile), "r");
            outFile = new FileOutputStream(new File(dstFile));
            int moovPos = 0;
            int mdatPos = 0;
            int moovSize = 0;
            int mdatSize = 0;
            byte[] pathBuf = new byte[4];
            int boxSize;
            int dataSize;
            int bytesRead;
            int totalBytesRead = 0;
            int bytesWritten = 0;

            // First find the location and size of the moov and mdat boxes
            while (true) {
                try {
                    boxSize = inFile.readInt();
                    bytesRead = inFile.read(pathBuf);
                    if (bytesRead != 4) {
                        Log.e(TAG, "Unexpected bytes read (path) " + bytesRead);
                        break;
                    }
                    String pathRead = new String(pathBuf, "UTF-8");
                    dataSize = boxSize - 8;
                    totalBytesRead += 8;
                    if (pathRead.equals("moov")) {
                        moovPos = totalBytesRead - 8;
                        moovSize = boxSize;
                    } else if (pathRead.equals("mdat")) {
                        mdatPos = totalBytesRead - 8;
                        mdatSize = boxSize;
                    }
                    totalBytesRead += inFile.skipBytes(dataSize);
                } catch (IOException e) {
                    break;
                }
            }

            // Read the moov box into a buffer, This has to be patched up. Ug.
            inFile.seek(moovPos);
            byte[] moovBoxBuf = new byte[moovSize]; // This shouldn't be too big.
            bytesRead = inFile.read(moovBoxBuf);
            if (bytesRead != moovSize) {
                Log.e(TAG, "Couldn't read full moov box");
            }

            // Now locate the stco boxes (chunk offset box) inside the moov box and patch
            // them up. This ain't purdy.
            int pos = 0;
            while (pos < moovBoxBuf.length - 4) {
                if (moovBoxBuf[pos] == 0x73 && moovBoxBuf[pos + 1] == 0x74 &&
                        moovBoxBuf[pos + 2] == 0x63 && moovBoxBuf[pos + 3] == 0x6f) {
                    int stcoPos = pos - 4;
                    int stcoSize = byteArrayToInt(moovBoxBuf, stcoPos);
                    patchStco(moovBoxBuf, stcoSize, stcoPos, moovSize);
                }
                pos++;
            }

            inFile.seek(0);
            byte[] buf = new byte[(int) mdatPos];
            // Write out everything before mdat
            inFile.read(buf);
            outFile.write(buf);

            // Write moov
            outFile.write(moovBoxBuf, 0, moovSize);

            // Write out mdat
            inFile.seek(mdatPos);
            bytesWritten = 0;
            while (bytesWritten < mdatSize) {
                int bytesRemaining = (int) mdatSize - bytesWritten;
                int bytesToRead = buf.length;
                if (bytesRemaining < bytesToRead) bytesToRead = bytesRemaining;
                bytesRead = inFile.read(buf, 0, bytesToRead);
                if (bytesRead > 0) {
                    outFile.write(buf, 0, bytesRead);
                    bytesWritten += bytesRead;
                } else {
                    break;
                }
            }
        } catch (IOException e) {
            Log.e(TAG, e.getMessage());
        } finally {
            try {
                if (outFile != null) outFile.close();
                if (inFile != null) inFile.close();
            } catch (IOException e) {}
        }
    }

    private void patchStco(byte[] buf, int size, int pos, int moovSize) {
        // We are inserting the moov box before the mdat box so all of
        // offsets in the stco box need to be increased by the size of the moov box. The stco
        // box is variable in length. 4 byte size, 4 byte path, 4 byte version, 4 byte flags
        // followed by a variable number of chunk offsets. So subtract off 16 from size then
        // divide result by 4 to get the number of chunk offsets to patch up.
        int chunkOffsetCount = (size - 16) / 4;
        int chunkPos = pos + 16;
        for (int i = 0; i < chunkOffsetCount; i++) {
            int chunkOffset = byteArrayToInt(buf, chunkPos);
            int newChunkOffset = chunkOffset + moovSize;
            intToByteArray(newChunkOffset, buf, chunkPos);
            chunkPos += 4;
        }
    }

    public static int byteArrayToInt(byte[] b, int offset)
    {
        return   b[offset + 3] & 0xFF |
                (b[offset + 2] & 0xFF) << 8 |
                (b[offset + 1] & 0xFF) << 16 |
                (b[offset] & 0xFF) << 24;
    }

    public void intToByteArray(int a, byte[] buf, int offset)
    {
        buf[offset] = (byte) ((a >> 24) & 0xFF);
        buf[offset + 1] = (byte) ((a >> 16) & 0xFF);
        buf[offset + 2] = (byte) ((a >> 8) & 0xFF);
        buf[offset + 3] = (byte) (a  & 0xFF);
    }
}
