package com.requestlabs.traveller;

import android.app.Application;

import com.parse.Parse;
import com.parse.ParseAnalytics;
import com.parse.ParseObject;

/**
 * Created by gjones on 5/16/14.
 */
public class App extends Application {
    private static final String APPLICATION_ID_PLACEHOLDER = "parse-application-id";
    private static final String CLIENT_KEY_PLACEHOLDER = "parse-client-key";

    @Override
    public void onCreate()
    {
        super.onCreate();
        ParseObject.registerSubclass(Item.class);
        String applicationId = ParseConfiguration.configuredValue(
                Constants.api_key, APPLICATION_ID_PLACEHOLDER);
        String clientKey = ParseConfiguration.configuredValue(
                Constants.client_id, CLIENT_KEY_PLACEHOLDER);
        Parse.initialize(this, applicationId, clientKey);
    }
}
