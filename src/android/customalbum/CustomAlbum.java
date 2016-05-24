package customalbum;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;

import android.util.Log;

public class CustomAlbum extends CordovaPlugin {


    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView)
    {
        super.initialize(cordova, webView);
    }

    private CallbackContext pluginResult = null;
    
    @Override
    public boolean execute(String action, JSONArray data, final CallbackContext callbackContext) throws JSONException
    {
        /*
        pluginResult = callbackContext;

        final Boolean withTorch = data.getBoolean(0);
        final Boolean withFocus = data.getBoolean(1);

        if (action.equals("doScan"))
        {
            cordova.setActivityResultCallback(this);

            cordova.getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {

                    Intent intent = new Intent(cordova.getActivity(), ScanActivity.class);
                           intent.addFlags(Intent.FLAG_ACTIVITY_NO_ANIMATION);
                           intent.putExtra(ScanActivity.WithTorch, withTorch);
                           intent.putExtra(ScanActivity.WithFocus, withFocus);

                    cordova.getActivity().startActivityForResult(intent, GET_BARCODE);
                }

            });

            return true;
        }
        else
        {
            return false;
        }
        */
    }
}