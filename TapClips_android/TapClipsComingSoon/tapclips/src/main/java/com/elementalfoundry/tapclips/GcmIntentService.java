package com.elementalfoundry.tapclips;

import android.app.IntentService;
import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

public class GcmIntentService extends IntentService {
    public static final int NOTIFICATION_ID = 0;
    private NotificationManager mNotificationManager;
    NotificationCompat.Builder builder;


    public GcmIntentService() {
        super("GcmIntentService");
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        Bundle extras = intent.getExtras();

        if (!extras.isEmpty()) {
            sendNotification(extras.getString("title"), extras.getString("message"));
        }
    }

    private void sendNotification(String title, String msg) {
        try {
            Context context = getApplicationContext();
            mNotificationManager = (NotificationManager)
                    context.getSystemService(Context.NOTIFICATION_SERVICE);

            Intent intent = new Intent(this, MainActivity.class);

            PendingIntent contentIntent = PendingIntent.getActivity(this, 0, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT);


            Bitmap bMap = BitmapFactory.decodeStream(context.getAssets().open("icon_120x120.png"));


            NotificationCompat.Builder mBuilder =
                    new NotificationCompat.Builder(this)
                            .setLargeIcon(bMap)
                            .setSmallIcon(R.drawable.ic_launcher)
                            .setContentTitle(title)
                            .setStyle(new NotificationCompat.BigTextStyle()
                                    .bigText(msg))
                            .setTicker(msg)
                            .setContentText(msg);
            mBuilder.setContentIntent(contentIntent);
            Notification notification = mBuilder.build();
            notification.flags |= Notification.FLAG_AUTO_CANCEL;
            notification.defaults |= Notification.DEFAULT_SOUND;
            notification.defaults |= Notification.DEFAULT_VIBRATE;
            mNotificationManager.notify(NOTIFICATION_ID, notification);
        }
        catch (Exception ex) {
            Log.d("SPRIO", ex.toString());
        }
    }
}