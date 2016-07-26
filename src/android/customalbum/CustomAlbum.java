package customalbum;

import org.apache.cordova.*;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Paint;
import android.graphics.Point;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Display;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.Date;


public class CustomAlbum extends CordovaPlugin {


    private static final String TAG = "CustomAlbum";


    private CallbackContext pluginResult = null;
    private String albumName = null;


    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView)
    {
        super.initialize(cordova, webView);
    }



    @Override
    public boolean execute(String action, final JSONArray data, final CallbackContext callbackContext) throws JSONException
    {
        pluginResult = callbackContext;

        // request authorization
        if(action.equals("requestAuthorization"))
        {
            requestAuthorization();
        }

        // create a album
        else if(action.equals("createAlbum"))
        {
            createAlbum(data.getString(0));
        }

        // get the local photos
        else if(action.equals("getPhotos"))
        {
            this.cordova.getThreadPool().execute(new Runnable()
            {
                @Override
                public void run()
                {
                    try
                    {
                        getPhotos();
                    }
                    catch (Exception e)
                    {
                        pluginResult.error(e.getLocalizedMessage());
                    }
                }
            });
        }

        // store the image
        else if(action.equals("storeImage"))
        {
            this.cordova.getThreadPool().execute(new Runnable()
            {
                @Override
                public void run()
                {
                    try
                    {
                        storeImage(data.getString(0), data.getString(1));
                    }
                    catch (JSONException e)
                    {
                        pluginResult.error(e.getLocalizedMessage());
                    }
                }
            });
        }

        // remove a image
        else if(action.equals("removeImage"))
        {
            //Log.d(TAG, "before remove img"+data.get(0).toString()+"");
            this.cordova.getThreadPool().execute(new Runnable()
            {
                @Override
                public void run()
                {
                    try
                    {
                        removeImage(data);
                    }
                    catch (Exception e)
                    {
                        pluginResult.error(e.getLocalizedMessage());
                    }
                }
            });
        }

        // load a single image
        else if(action.equals("loadImage"))
        {
            this.cordova.getThreadPool().execute(new Runnable()
            {
                @Override
                public void run()
                {
                    try
                    {
                        loadImage(data.getString(0));
                    }
                    catch (JSONException e)
                    {
                        pluginResult.error(e.getLocalizedMessage());
                    }
                }
            });
        }

        return true;
    }




    private void requestAuthorization()
    {
        //Log.d(TAG, "requestAuthorization");
        //first check permissions
        boolean hasPermission = cordova.hasPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE);

        if (!hasPermission)
        {
            cordova.requestPermissions(this, REQUEST_WRITE_STORAGE, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE});
        }
        else
        {
            pluginResult.success("requestAuthorization");
        }
    }



    private static final int REQUEST_WRITE_STORAGE = 112;

    private void createAlbum(String album)
    {
        Log.d(TAG, "createAlbum");

        // set the album name
        albumName = album;

        // get the path
        String path    = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES) + File.separator + albumName;
        String pathTmp = Environment.getExternalStorageDirectory() + File.separator + "." + albumName;
        File dir       = new File(path);
        File dirTmp    = new File(pathTmp);

        if (!dir.isDirectory() || !dirTmp.isDirectory())
        {
            // make the dir
            dir.mkdirs();
            dirTmp.mkdirs();
            if (!dir.isDirectory() || !dirTmp.isDirectory())
            {
                pluginResult.error("createAlbum");
            }
        }
        else
        {
            pluginResult.success("createAlbum");
        }

        Log.d(TAG, path);
    }




    @Override
    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException
    {
        switch (requestCode) {
            case REQUEST_WRITE_STORAGE: {

                if (grantResults.length == 0 || grantResults[0] != PackageManager.PERMISSION_GRANTED)
                {
                    pluginResult.error("requestAuthorization");
                }
                else
                {
                    pluginResult.success("requestAuthorization");
                }
                return;
            }
        }
    }







    private void getPhotos()
    {
        Log.d(TAG, "getPhotos");

        String path = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES) + File.separator + albumName;
        File dir    = new File(path);
        File file[] = dir.listFiles();

        JSONArray result = new JSONArray();

        // check if we have images
        if(file.length > 0)
        {
            for (int i = 0; i < file.length; i++)
            {
                File currFile = file[i];

                try {

                    JSONObject item = new JSONObject();

                    String date     = new SimpleDateFormat("dd-MM-yyyy H:mm:ss").format(new Date(currFile.lastModified()));
                    String fileName = currFile.getName();
                    String fileType = fileName.substring(fileName.lastIndexOf('.')+1, fileName.length()).toLowerCase();
                    String id       = fileName.replace("."+fileType+"", "");

                    item.put("width", 0);//out.getWidth());
                    item.put("height", 0);//out.getHeight());
                    item.put("created_at", date);
                    item.put("modified_at", date);
                    item.put("id", id);
                    item.put("filename", fileName);

                    result.put(result.length(), item);
                }
                catch (Exception e)
                {
                    Log.d(TAG, e.getLocalizedMessage());
                }

            }

            // check if we have a result
            if(result.length() > 0)
            {
                Log.d(TAG, "Photos fetched:"+result.toString());
                pluginResult.success(result.toString());
            }
            else
            {
                pluginResult.error("no assets found");
            }
        }
        else
        {
            pluginResult.error("no assets found");
        }
    }




    private void storeImage(String src, String reference)
    {
        String path     = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES) + File.separator + albumName;
        String fileType = src.substring(src.lastIndexOf('.')+1, src.length()).toLowerCase();
        String fileName = reference + "." + fileType;//src.substring(src.lastIndexOf('/')+1, src.length());

        Log.d("STORE", path);

        DisplayMetrics dm = new DisplayMetrics();
        this.cordova.getActivity().getWindowManager().getDefaultDisplay().getMetrics(dm);

        try
        {
            URL url = new URL(src);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                              connection.setDoInput(true);
                              connection.connect();

            InputStream input          = connection.getInputStream();
            ByteArrayOutputStream baos = new ByteArrayOutputStream();

            byte[] buffer = new byte[1024];
            int len;
            while ((len = input.read(buffer)) > -1 )
            {
                baos.write(buffer, 0, len);
            }
            baos.flush();
            input.close();

            InputStream is1 = new ByteArrayInputStream(baos.toByteArray());
            InputStream is2 = new ByteArrayInputStream(baos.toByteArray());

            final BitmapFactory.Options options = new BitmapFactory.Options();
                                  options.inJustDecodeBounds = true;

            BitmapFactory.decodeStream(is1, null, options);

            int imageWidth = options.outWidth;
            int imageHeight = options.outHeight;

            int inSampleSize = 1;

            if (imageHeight > dm.heightPixels || imageWidth > dm.widthPixels) {

                final int halfHeight = imageHeight / 2;
                final int halfWidth  = imageWidth / 2;

                while ((halfHeight / inSampleSize) > dm.heightPixels && (halfWidth / inSampleSize) > dm.widthPixels)
                {
                    inSampleSize *= 2;
                }
            }

            // reset the settings
            options.inJustDecodeBounds = false;
            options.inSampleSize = inSampleSize;

            Bitmap bmp = BitmapFactory.decodeStream(is2, null, options);

            Log.d(TAG, "Sample size:"+inSampleSize);

            FileOutputStream out = null;
            File imageFileName   = new File(path, fileName);
            try
            {
                out = new FileOutputStream(imageFileName);

                Bitmap.CompressFormat format = (fileType.equals("jpeg") || fileType.equals("jpg")) ? Bitmap.CompressFormat.JPEG : Bitmap.CompressFormat.PNG;

                // check the filetype
                bmp.compress(format, 100, out);

                bmp.recycle();
                bmp = null;

                out.flush();
                out.close();

                // save to photo for other apps
                refreshGallery(imageFileName);

                // send the result
                JSONArray result = new JSONArray();
                          result.put(reference);
                          result.put(reference);

                pluginResult.success(result);
            }
            catch (Exception e)
            {
                Log.d(TAG, "error:"+e.getCause()+"");
                pluginResult.error(e.getLocalizedMessage());
            }
        }
        catch (Exception e)
        {
            Log.d(TAG, "error:"+e.getCause());
            Log.d(TAG, "no file:"+src+"");
            pluginResult.error(e.getLocalizedMessage());
        }
    }




    private boolean resizeBitmap(File file, File newFile, int maxWidth, int maxHeight)
    {
        if(!file.exists())
            return false;

        if(newFile.exists())
            return true;

        // get the image size
        BitmapFactory.Options options = new BitmapFactory.Options();
                              options.inJustDecodeBounds = true;

        BitmapFactory.decodeFile(file.getAbsolutePath(), options);

        String type = options.outMimeType;

        int width   = options.outWidth;
        int height  = options.outHeight;

        int inSampleSize = 1;

        if (height > maxHeight || width > maxWidth) {

            final int halfHeight = height / 2;
            final int halfWidth  = width / 2;

            while ((halfHeight / inSampleSize) > maxHeight && (halfWidth / inSampleSize) > maxWidth)
            {
                inSampleSize *= 2;
            }
        }

        // load the bitmap
        options              = new BitmapFactory.Options();
        options.inSampleSize = inSampleSize;

        Bitmap b                     = BitmapFactory.decodeFile(file.getAbsolutePath(), options);
        Bitmap.CompressFormat format = (type.equals("image/jpeg")) ? Bitmap.CompressFormat.JPEG : Bitmap.CompressFormat.PNG;

        float wRatio = 1;
        float hRatio = 1;

        float shortSide = Math.min(maxWidth, maxHeight);
        float longSide  = Math.max(maxWidth, maxHeight);

        if (width >= height)
        {
            if (width > longSide || height > shortSide)
            {
                wRatio = (longSide/(float)width);
                hRatio = (shortSide/(float)height);
            }
        }
        else
        {
            if (height > shortSide || width > longSide)
            {
                wRatio = (shortSide/(float)width);
                hRatio = (longSide/(float)height);
            }
        }

        float ratio = Math.min(wRatio, hRatio);

        // create the bitmap
        try
        {
            int newWidth  = Math.round(width*ratio);
            int newHeight = Math.round(height*ratio);

            FileOutputStream out  = new FileOutputStream(newFile);
            Bitmap bmp            = Bitmap.createScaledBitmap(b, newWidth, newHeight, true);

            bmp.compress(format, 100, out);

            out.flush();
            out.close();
        }
        catch(IOException e)
        {
            Log.d(TAG, e.getLocalizedMessage());
            return false;
        }

        return true;
    }





    /*
    private void scanPhoto(String imageFileName)
    {
        Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
        File f = new File(imageFileName);
        Uri contentUri = Uri.fromFile(f);
        mediaScanIntent.setData(contentUri);

        this.cordova.getActivity().sendBroadcast(mediaScanIntent);
    }
    */


    private void refreshGallery(File file)
    {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT)
        {
            if (file.exists())
            {
                Intent mediaScanIntent = new Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE);
                Uri contentUri = Uri.fromFile(file);
                mediaScanIntent.setData(contentUri);
                this.cordova.getActivity().sendBroadcast(mediaScanIntent);
            }
            else
            {
                // Delete File
                try
                {
                    this.cordova.getActivity().getContentResolver().delete(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, MediaStore.Images.Media.DATA + "='" + file.getPath() + "'", null);
                } catch (Exception e)
                {
                    Log.d(TAG, e.getLocalizedMessage());
                }
            }
        } else {
            this.cordova.getActivity().sendBroadcast(new Intent(Intent.ACTION_MEDIA_MOUNTED, Uri.parse("file://"+file.getAbsolutePath())));
        }
    }



    private void removeImage(JSONArray localIdentifiers)
    {
        String path     = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES) + File.separator + albumName;
        String pathTmp  = Environment.getExternalStorageDirectory() + File.separator + "." + albumName;
        String error    = "";

        int deleted = 0;

        int total = localIdentifiers.length();
        for(int i = 0; i < total; i++)
        {
            try
            {
                String id       = localIdentifiers.getString(i);

                File original = new File(path, getFilenameById(path, id));
                File scaled   = new File(pathTmp, getFilenameById(pathTmp, "scaled_"+id));
                File thumb    = new File(pathTmp, getFilenameById(pathTmp, "thumb_"+id));

                Log.d(TAG, "try to remove:"+original.toString()+"");

                if(original.exists())
                {
                    original.delete();
                    refreshGallery(original);
                }

                if(scaled.exists())
                {
                    scaled.delete();
                }

                if(thumb.exists())
                {
                    thumb.delete();
                }

                Log.d(TAG, "removed:"+original.toString()+"");

                deleted++;
            }
            catch(Exception e)
            {
                error += e.getLocalizedMessage()+"|";
                return;
            }
        }

        // send the error
        if(error != "")
        {
            pluginResult.error(error);
        }
        else
        {
            pluginResult.success("" + deleted + " elements deleted");
        }

    }



    private JSONArray imageQueue    = new JSONArray();
    private Boolean isQueueRunning  = false;



    private String getFilenameById(String path, final String id)
    {
        File dir        = new File(path);
        String files[]  = dir.list(new FilenameFilter()
        {
            public boolean accept(File dir, String filename)
            {
                return filename.startsWith(id);
            }
        });

        String filename = files[0];

        return filename;
    }


    private void handleItemFromQueue(int index)
    {
        PluginResult result = null;

        DisplayMetrics dm = new DisplayMetrics();
        this.cordova.getActivity().getWindowManager().getDefaultDisplay().getMetrics(dm);

        try
        {

            String path     = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES) + File.separator + albumName;
            String pathTmp  = Environment.getExternalStorageDirectory() + File.separator + "." + albumName;
            JSONObject item = imageQueue.getJSONObject(index);

            final String id = item.get("id").toString();

            String filename = getFilenameById(path, id);
            File file       = new File(path, filename);
            File scaledFile = new File(pathTmp, "scaled_"+filename);

            boolean fileSuccess = resizeBitmap(file, scaledFile, dm.widthPixels, dm.heightPixels);

            if(fileSuccess)
            {
                File thumbnail = new File(pathTmp, "thumb_"+filename);

                boolean thumbSuccess = resizeBitmap(file, thumbnail, 400, 280);
                if(thumbSuccess)
                {
                    JSONObject newItem = new JSONObject();
                    newItem.put("img_path", scaledFile.getAbsolutePath());
                    newItem.put("thumb_path", thumbnail.getAbsolutePath());
                    newItem.put("filename", filename);
                    newItem.put("id", id);

                    result = new PluginResult(PluginResult.Status.OK, newItem.toString());
                }
                else
                {
                    result = new PluginResult(PluginResult.Status.ERROR, id);
                }
                //pluginResult.sendPluginResult(new PluginResult(PluginResult.Status.OK, newItem.toString()), callback);
            }
            else
            {
                result = new PluginResult(PluginResult.Status.ERROR, id);
            }

            // go next or stop
            imageQueue = RemoveJSONArray(imageQueue, index);
            if (imageQueue.length() >= 1)
            {
                handleItemFromQueue(0);
            } else
            {
                // end the queue
                isQueueRunning = false;
            }
        }
        catch(JSONException e)
        {
            result = new PluginResult(PluginResult.Status.ERROR, "no asset found");
        }

        result.setKeepCallback(true);
        pluginResult.sendPluginResult(result);
    }


    private void runQueue()
    {
        if(!isQueueRunning)
        {
            isQueueRunning = true;

            // start the queue
            handleItemFromQueue(0);
        }
    }


    private void loadImage(String localIdentifier)
    {
        try
        {
            JSONObject img = new JSONObject();
                       img.put("id", localIdentifier);

            // add to the queue
            imageQueue.put(imageQueue.length(), img);
            runQueue();
        }
        catch(JSONException e)
        {
            Log.d(TAG, e.getLocalizedMessage());
        }
    }




    public static JSONArray RemoveJSONArray(JSONArray arr, int pos) {

        JSONArray newArr = new JSONArray();
        try
        {
            int l = arr.length();
            for (int i = 0; i < l; i++)
            {
                if (i != pos)
                    newArr.put(arr.get(i));
            }
        } catch (Exception e)
        {
            e.printStackTrace();
        }
        return newArr;
    }
}



