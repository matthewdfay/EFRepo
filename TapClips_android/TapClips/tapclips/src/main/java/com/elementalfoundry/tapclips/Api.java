package com.elementalfoundry.tapclips;

import android.util.Log;

import com.google.gson.Gson;
import com.google.gson.annotations.SerializedName;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.conn.ssl.X509HostnameVerifier;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.SingleClientConnManager;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.apache.http.protocol.BasicHttpContext;
import org.apache.http.protocol.HttpContext;
import org.apache.http.util.EntityUtils;

import java.security.cert.X509Certificate;
import java.util.Arrays;

import javax.net.ssl.HostnameVerifier;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class Api {

    private String mBaseUrl;
    private boolean mUnsafeMode;

    public Api() {
        mBaseUrl = Settings.BASE_URL;
        mUnsafeMode = Arrays.asList(Settings.INSECURE_URLS).contains(Settings.BASE_URL);
    }

    public Object MakeApiCall(String url, Object data, Class type) {
        return makeApiCallInternal(url, data, type, true);
    }

    private Object makeApiCallInternal(String url, Object data, Class type, boolean retry) {
        Object result = null;
        try {

            Gson gson = new Gson();
            String json = "{}";
            if (null != data) {
                json = gson.toJson(data);
            }

            HttpClient httpClient;
            if (mUnsafeMode) {
                SSLContext ctx = SSLContext.getInstance("TLS");
                ctx.init(null, new TrustManager[] {
                        new X509TrustManager() {
                            public void checkClientTrusted(X509Certificate[] chain, String authType) {}
                            public void checkServerTrusted(X509Certificate[] chain, String authType) {}
                            public X509Certificate[] getAcceptedIssuers() { return new X509Certificate[]{}; }
                        }
                }, null);
                HttpsURLConnection.setDefaultSSLSocketFactory(ctx.getSocketFactory());

                HostnameVerifier hostnameVerifier = org.apache.http.conn.ssl.SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER;

                DefaultHttpClient client = new DefaultHttpClient();

                SchemeRegistry registry = new SchemeRegistry();
                SSLSocketFactory socketFactory = SSLSocketFactory.getSocketFactory();
                socketFactory.setHostnameVerifier((X509HostnameVerifier) hostnameVerifier);
                registry.register(new Scheme("https", socketFactory, 443));
                SingleClientConnManager mgr = new SingleClientConnManager(client.getParams(), registry);
                httpClient = new DefaultHttpClient(mgr, client.getParams());

                // Set verifier
                HttpsURLConnection.setDefaultHostnameVerifier(hostnameVerifier);
            } else {
                HttpParams myParams = new BasicHttpParams();
                HttpConnectionParams.setConnectionTimeout(myParams, 10000);
                HttpConnectionParams.setSoTimeout(myParams, 10000);
                httpClient = new DefaultHttpClient(myParams);
            }

            HttpContext localContext = new BasicHttpContext();
            HttpPost httpPost = new HttpPost(mBaseUrl + url);
            httpPost.setHeader("Content-Type", "application/json");
            String sessionToken = Settings.get().getSessionToken();
            if (sessionToken != "") {
                httpPost.setHeader("session-token", sessionToken);
            }

            httpPost.setEntity(new StringEntity(json, "UTF-8"));

            HttpResponse response = httpClient.execute(httpPost, localContext);
            if (response != null) {
                org.apache.http.Header[] h = response.getHeaders("Session-Token");
                if (h != null && h.length == 1) {
                    Settings.get().setSessionToken(h[0].getValue());
                }

                String responseJson = EntityUtils.toString(response.getEntity());
                result = gson.fromJson(responseJson, type);

                // todo: should return an error if one occurs and is returned in ApiResponse
                if (retry && result instanceof ApiResponse) {
                    ApiResponse apiResponse = (ApiResponse)result;
                    if(!apiResponse.success && apiResponse.error != null && isAuthFailure(apiResponse)) {
                        Settings.get().loginUser("");
                        makeApiCallInternal(url, data, type, false);
                    }
                }
            }
        } catch (Exception ex) {
            Log.d("SPRIO", ex.toString());
        }

        return result;
    }

    private boolean isAuthFailure(ApiResponse apiResponse) {
        if(apiResponse.error.name.equals("loginFailed") ||
                apiResponse.error.name.equals("invalidSessionToken")) {
            return true;
        }

        return false;
    }

    public static class ApiResponse {
        public boolean success;
        public Error error;

        public static class Error {
            public String name;
            public String message;
        }
    }

    public static class GetUserPreferencesResponse extends ApiResponse {
        public InternalResponse response;

        public class InternalResponse {
            public All all;
        }

        public class All {
            @SerializedName("linkedservice:sprio")
            public LinkedServiceSprio linkedServiceSprio;
        }

        public class LinkedServiceSprio {
            public String userId;
        }
    }

    public static class GetSettingsResponse extends ApiResponse {
        public InternalResponse response;

        public class InternalResponse {
            public Settings settings;
        }

        public class Settings {
            public Object tapClipsTypeaheads;

            public NameValue[] tapClips;

            public class NameValue {
                public String id;
                public String value;
            }
        }
    }

    public static class GetTeamsResponse extends ApiResponse {
        public Team[] response;

        public class Team {
            public Properties properties;
        }

        public class Properties {
            public String _id;
            public String moniker;
            public String icon;
            public String title;
        }
    }

    public static class SettingsResponse extends ApiResponse {
        public InternalResponse response;

        public class InternalResponse {
            public NameValue[] tapClips;

            public class NameValue {
                public String id;
                public String value;
            }
        }
    }

    public static class LoginResponse extends ApiResponse {
        public InternalResponse response;

        public class InternalResponse {
            public String userId;
            public String sessionToken;
        }
    }

    public static class LoginParams {
        public String appId = Settings.APP_ID;
        public String userIdType = "tc";
        public String requestSignature = Settings.REQUEST_SIGNATURE;
        public String token;
        public String serviceType = "android";
        public String userId;
        public String timeZone;

        public LoginParams(String userId, String timeZone) {
            this.userId = userId;
            this.timeZone = timeZone;
        }
    }

    public static class GetTapClipsUrlResponse extends ApiResponse {
        public InternalResponse response;

        public class InternalResponse {
            public String url;
            public String date;
            public String signature;
        }
    }

    public static class PostParamsWithShortUrl {
        public String appId = Settings.APP_ID;
        public String requestSignature = Settings.REQUEST_SIGNATURE;
        public String privacy = "public";
        public String teamId = Settings.get().getTeamId();
        public Attachment[] attachments;
        public ShortUrlInfo shortUrlInfo;

        public static class Attachment {
            public String type = "video";
            public String videoType = "video/mp4";
            public String url;
            public String imgUrl;
            public int[] size;
            public Float duration;
        }

        public static class ShortUrlInfo {
            public String url;
            public String date;
            public String signature;
        }
    }

    public static class PostParamsWithShareInfo {
        public String appId = Settings.APP_ID;
        public String requestSignature = Settings.REQUEST_SIGNATURE;
        public String privacy = "public";
        public String teamId = Settings.get().getTeamId();
        public Attachment[] attachments;
        public ShareDict share;
        public String description;

        public static class Attachment {
            public String type = "video";
            public String videoType = "video/mp4";
            public String url;
            public String imgUrl;
            public int[] size;
            public Float duration;
        }

        public static class ShareDict {
            public FacebookInfo fb;
            public TwitterInfo twitter;
            public SprioInfo sprio;
        }

        public static class FacebookInfo {
            public String token;
        }

        public static class TwitterInfo {
            public String oauth_token;
            public String oauth_token_secret;
        }

        public static class SprioInfo {
            public String teamId;
        }
    }

    public static class LinkServiceParams {
        public Object value;
        public String type;

        public static class SprioServiceInfo {
            public String token;
        }
    }

    public static class GetSettingsParams {
        public String[] include = {"settings"};
    }
}
