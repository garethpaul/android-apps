package com.requestlabs.traveller;

import android.graphics.Paint;
import android.support.v7.app.ActionBarActivity;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.AdapterView;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import com.parse.FindCallback;
import com.parse.ParseAnalytics;
import com.parse.ParseException;
import com.parse.ParseObject;
import com.parse.ParseQuery;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends ActionBarActivity implements AdapterView.OnItemClickListener {

    private EditText mTaskInput;
    private ListView mListView;
    private ItemAdapter mAdapter;



    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        ParseObject.registerSubclass(Item.class);
        setContentView(R.layout.item_activity);
        ParseAnalytics.trackAppOpened(getIntent());

        mAdapter = new ItemAdapter(this, new ArrayList<Item>());

        mTaskInput = (EditText) findViewById(R.id.task_input);
        mListView = (ListView) findViewById(R.id.task_list);

        mListView.setAdapter(mAdapter);
        mListView.setOnItemClickListener(this);
        updateData();
    }




    //
    public void createTask(View v) {
        String description = normalizedTaskDescription();
        if (description.length() > 0){
            Item t = new Item();
            t.setDescription(description);
            t.setCompleted(false);
            t.saveEventually();
            mTaskInput.setText("");
            finish();
            startActivity(getIntent());
        }

    }

    //


    private String normalizedTaskDescription() {
        if(mTaskInput == null || mTaskInput.getText() == null){
            return "";
        }
        return mTaskInput.getText().toString().trim();
    }




    public void updateData(){
        ParseQuery<Item> query = ParseQuery.getQuery(Item.class);
        query.whereNotEqualTo("completed", true);

        query.setCachePolicy(ParseQuery.CachePolicy.CACHE_THEN_NETWORK);
        query.findInBackground(new FindCallback<Item>() {

            @Override
            public void done(List<Item> tasks, ParseException error) {
                if(error == null && tasks != null){
                    mAdapter.clear();
                    mAdapter.addAll(tasks);
                }else{
                    Toast.makeText(
                            MainActivity.this,
                            R.string.load_items_error,
                            Toast.LENGTH_SHORT).show();
                }
            }
        });
    }



    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();
        if (id == R.id.action_settings) {
            return true;
        }
        return super.onOptionsItemSelected(item);
    }

    @Override
    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
        if(mAdapter == null){
            return;
        }

        Item task = mAdapter.getItem(position);
        if(task == null){
            return;
        }

        if(view == null){
            return;
        }

        View taskDescriptionView = view.findViewById(R.id.task_description);
        TextView taskDescription = null;
        if(taskDescriptionView instanceof TextView){
            taskDescription = (TextView) taskDescriptionView;
        }
        if(taskDescription == null){
            return;
        }

        task.setCompleted(!task.isCompleted());

        if(task.isCompleted()){
            taskDescription.setPaintFlags(taskDescription.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
        }else{
            taskDescription.setPaintFlags(taskDescription.getPaintFlags() & (~Paint.STRIKE_THRU_TEXT_FLAG));
        }
        task.saveEventually();
        finish();
        startActivity(getIntent());
    }
}
