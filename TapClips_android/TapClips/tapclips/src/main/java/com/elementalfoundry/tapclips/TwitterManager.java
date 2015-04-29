package com.elementalfoundry.tapclips;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.util.Log;
import android.provider.Browser;

import twitter4j.Twitter;
import twitter4j.TwitterException;
import twitter4j.TwitterFactory;
import twitter4j.auth.AccessToken;
import twitter4j.auth.RequestToken;
import twitter4j.conf.ConfigurationBuilder;

/**
 * Created by mdbranth on 6/16/14.
 */
public class TwitterManager {
    private static String TWITTER_CONSUMER_KEY = "CEJJ5eTzm5dnDblxyH08Q";
    private static String TWITTER_CONSUMER_SECRET = "T7CRXitC7By1CGyAfIHUrkvEiGCCdgPTu50PMRs";
    private static final String URL_TWITTER_OAUTH_VERIFIER = "oauth_verifier";
    private static final String TWITTER_CALLBACK_URL = "tapclips://action.launch/twitterAuth";

    private static TwitterManager sManager;

    public static TwitterManager get() {
        if (sManager == null) {
            sManager = new TwitterManager();
        }

        return sManager;
    }

    private Twitter mTwitter = null;
    private RequestToken mRequestToken = null;
    private String mOauthToken = "";
    private String mOauthSecret = "";

    private TwitterManager() {

    }

    public boolean isAuthorized() {
        return !mOauthToken.equals("") &&
                !mOauthToken.equals("");
    }

    public void deAuthorize() {
        mOauthToken = "";
        mOauthSecret = "";
    }

    public String getOauthToken() {
        return mOauthToken;
    }

    public String getOauthSecret() {
        return mOauthSecret;
    }

    public void requestAuthorization(final Activity activity) {
        ConfigurationBuilder builder = new ConfigurationBuilder();
        builder.setOAuthConsumerKey(TWITTER_CONSUMER_KEY);
        builder.setOAuthConsumerSecret(TWITTER_CONSUMER_SECRET);
        twitter4j.conf.Configuration configuration = builder.build();

        TwitterFactory factory = new TwitterFactory(configuration);
        mTwitter = factory.getInstance();

        Thread thread = new Thread(new Runnable(){
            @Override
            public void run() {
                try {
                    mRequestToken = mTwitter.getOAuthRequestToken(TWITTER_CALLBACK_URL);
                    Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(mRequestToken.getAuthenticationURL()));
                    browserIntent.putExtra(Browser.EXTRA_APPLICATION_ID, "com.elementalfoundry.tapclips");
                    activity.startActivity(browserIntent);
                } catch (Exception ex) {
                    Log.e(Settings.TAG, "Exception starting brower to log into twitter: ", ex);
                }
            }
        });
        thread.start();
    }

    public void completeAuthorization(EFUri efuri) throws TwitterException {
            final String verifier = efuri.getParam(URL_TWITTER_OAUTH_VERIFIER);
            AccessToken accessToken = mTwitter.getOAuthAccessToken(mRequestToken, verifier);
            mOauthToken = accessToken.getToken();
            mOauthSecret = accessToken.getTokenSecret();
            Log.d(Settings.TAG, "***** Twitter access granted");
    }
}
