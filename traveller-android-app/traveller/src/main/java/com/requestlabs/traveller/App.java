package com.requestlabs.traveller;

import android.app.Application;

import com.parse.Parse;
import com.parse.ParseAnalytics;

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
        String applicationId = configuredValue(Constants.api_key, APPLICATION_ID_PLACEHOLDER);
        String clientKey = configuredValue(Constants.client_id, CLIENT_KEY_PLACEHOLDER);
        Parse.initialize(this, applicationId, clientKey);
    }

    private static String configuredValue(String value, String placeholder){
        if(value == null){
            throw new IllegalStateException(
                    "Traveller Parse configuration is missing; replace Constants.java placeholders locally.");
        }

        String configuredValue = value.trim();
        if(configuredValue.length() == 0 || placeholder.equals(configuredValue)){
            throw new IllegalStateException(
                    "Traveller Parse configuration is missing; replace Constants.java placeholders locally.");
        }
        return configuredValue;
    }
}
