// MyApplication.java (create this file if it doesn't exist in your project)
package com.example.flusic;

import io.flutter.app.FlutterApplication;
import io.flutter.plugin.common.PluginRegistry;
import vn.hunghd.flutterdownloader.FlutterDownloaderPlugin;

public class MyApplication extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {
    @Override
    public void registerWith(PluginRegistry registry) {
        //
        // Integration note:
        //
        // In Flutter, in order to work in background isolate, plugins need to register
        // with
        // a special instance of `FlutterEngine` that serves for background execution
        // only.
        // Hence, all (and only) plugins that require background execution feature need
        // to
        // call `registerWith` in this method.
        //
        // The default `GeneratedPluginRegistrant` will call `registerWith` of all
        // plugins
        // integrated in your application. Hence, if you are using
        // `FlutterDownloaderPlugin`
        // along with other plugins that need UI manipulation, you should register
        // `FlutterDownloaderPlugin` and any 'background' plugins explicitly like this:
        //
        FlutterDownloaderPlugin
                .registerWith(registry.registrarFor("vn.hunghd.flutterdownloader.FlutterDownloaderPlugin"));

    }
}