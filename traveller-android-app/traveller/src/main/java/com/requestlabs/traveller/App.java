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
        requireParseConfiguration();
        Parse.initialize(this, Constants.api_key, Constants.client_id);
    }

    private static void requireParseConfiguration(){
        if(!isConfigured(Constants.api_key, APPLICATION_ID_PLACEHOLDER) ||
                !isConfigured(Constants.client_id, CLIENT_KEY_PLACEHOLDER)){
            throw new IllegalStateException(
                    "Traveller Parse configuration is missing; replace Constants.java placeholders locally.");
        }
    }

    private static boolean isConfigured(String value, String placeholder){
        return value != null &&
                value.trim().length() > 0 &&
                !placeholder.equals(value.trim());
    }
}
