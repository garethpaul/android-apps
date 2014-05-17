package com.requestlabs.traveller;

import com.parse.ParseClassName;
import com.parse.ParseObject;


@ParseClassName("Item")
public class Item extends ParseObject {
    public Item(){

    }

    public boolean isCompleted(){
        return getBoolean("completed");
    }

    public void setCompleted(boolean complete){
        put("completed", complete);
    }

    public String getDescription(){
        return getString("description");
    }

    public void setDescription(String description){
        put("description", description);
    }
}

