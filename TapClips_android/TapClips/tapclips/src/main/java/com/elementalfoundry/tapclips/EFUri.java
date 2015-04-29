package com.elementalfoundry.tapclips;

import java.net.URLDecoder;
import java.util.Hashtable;

public class EFUri {
    private String mProtocol;
    private String mHost;
    private String mQuery;
    private String mAction;
    private Hashtable<String, String> mParams;

    public EFUri(String uri) {
        mProtocol = "";
        mHost = "";
        mQuery = "";
        mAction = "";
        mParams = new Hashtable<String, String>();

        int index = uri.indexOf("://");
        if (index != -1) {
            mProtocol = uri.substring(0, index);
            uri = uri.substring(index + 3);
        }

        index = uri.indexOf("?");
        if (index == -1) {
            mHost = uri;
        }
        else {
            mHost = uri.substring(0, index);
            uri = uri.substring(index + 1);
            mQuery = uri;

            String[] params = uri.split("&");
            for(int i = 0; i < params.length; i++) {
                String[] parts = params[i].split("=");
                if (parts.length == 2) {
                    try {
                        mParams.put(parts[0], URLDecoder.decode(parts[1], "UTF-8"));
                    } catch (Exception ex) {
                    }
                }
            }
        }

        index = mHost.indexOf("/");
        if (index != -1) {
            String[] parts = mHost.split("/");
            mHost = parts[0];
            mAction = parts[1];
        }
    }

    public String getProtocol() {
        return mProtocol;
    }

    public String getHost() {
        return mHost;
    }

    public String getQuery() {
        return mQuery;
    }

    public String getAction() { return mAction; }

    public String getParam(String name) {
        String result = "";
        if (mParams.containsKey(name)) {
            result = mParams.get(name);
        }
        return result;
    }
}
