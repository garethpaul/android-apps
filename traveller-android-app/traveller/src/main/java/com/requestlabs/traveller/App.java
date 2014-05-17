package com.requestlabs.traveller;

import android.app.Application;

import com.parse.Parse;
import com.parse.ParseAnalytics;

/**
 * Created by gjones on 5/16/14.
 */
public class App extends Application {
    @Override
    public void onCreate()
    {
        Parse.initialize(this, Constants.api_key, Constants.client_id);


    }
}
