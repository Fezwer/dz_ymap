package com.example.dz_ymap;

import android.app.Application;

import com.yandex.mapkit.MapKitFactory;

public class MainApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        MapKitFactory.setLocale("YOUR_LOCALE");
        MapKitFactory.setApiKey("12da07f7-70bf-487d-910b-ddaa69099625");
    }
}