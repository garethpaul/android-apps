package com.requestlabs.traveller;

import java.util.List;

import android.content.Context;
import android.graphics.Paint;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.TextView;

public class ItemAdapter extends ArrayAdapter<Item> {
    private Context mContext;

    public ItemAdapter(Context context, List<Item> objects) {
        super(context, R.layout.item_row_item, objects);
        this.mContext = context;
    }

    public View getView(int position, View convertView, ViewGroup parent){
        if(convertView == null){
            LayoutInflater mLayoutInflater = LayoutInflater.from(mContext);
            convertView = mLayoutInflater.inflate(R.layout.item_row_item, parent, false);
        }

        View descriptionViewCandidate = convertView.findViewById(R.id.task_description);
        if(!(descriptionViewCandidate instanceof TextView)){
            return convertView;
        }

        TextView descriptionView = (TextView) descriptionViewCandidate;
        Item task = getItem(position);
        if(task == null){
            descriptionView.setText("");
            descriptionView.setPaintFlags(descriptionView.getPaintFlags() & (~Paint.STRIKE_THRU_TEXT_FLAG));
            return convertView;
        }

        String description = task.getDescription();
        if(description == null){
            description = "";
        }
        descriptionView.setText(description);

        if(task.isCompleted()){
            descriptionView.setPaintFlags(descriptionView.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
        }else{
            descriptionView.setPaintFlags(descriptionView.getPaintFlags() & (~Paint.STRIKE_THRU_TEXT_FLAG));
        }

        return convertView;
    }

}
