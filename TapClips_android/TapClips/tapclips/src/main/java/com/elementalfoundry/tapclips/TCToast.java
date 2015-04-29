package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;

/**
 * Created by mdbranth on 6/4/14.
 */
public class TCToast {
    public static void showToast(String text, Activity activity) {
        LayoutInflater inflater = activity.getLayoutInflater();
        View layout = inflater.inflate(R.layout.custom_toast,
                (ViewGroup) activity.findViewById(R.id.toast_layout_root));

        TextView textView = (TextView) layout.findViewById(R.id.text);
        textView.setText(text);

        Toast toast = new Toast(activity.getApplicationContext());
        toast.setGravity(Gravity.CENTER_VERTICAL, 0, 0);
        toast.setDuration(Toast.LENGTH_LONG);
        toast.setView(layout);
        toast.show();
    }

    public static void showErrorToast(String text, Activity activity) {
        LayoutInflater inflater = activity.getLayoutInflater();
        View layout = inflater.inflate(R.layout.custom_toast_error,
                (ViewGroup) activity.findViewById(R.id.toast_layout_root));

        TextView textView = (TextView) layout.findViewById(R.id.text);
        textView.setText(text);

        Toast toast = new Toast(activity.getApplicationContext());
        toast.setGravity(Gravity.CENTER_VERTICAL, 0, 0);
        toast.setDuration(Toast.LENGTH_LONG);
        toast.setView(layout);
        toast.show();
    }
}
