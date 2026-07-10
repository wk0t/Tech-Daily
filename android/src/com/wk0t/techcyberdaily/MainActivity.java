package com.wk0t.techcyberdaily;

import android.app.Activity;
import android.app.AlarmManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.speech.tts.TextToSpeech;
import android.speech.tts.UtteranceProgressListener;
import android.util.Base64;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Calendar;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class MainActivity extends Activity {
    private WebView web;
    private final ExecutorService pool = Executors.newFixedThreadPool(6);
    private TextToSpeech tts;
    private boolean ttsReady = false;
    private String pendingSpeak = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        s.setLoadsImagesAutomatically(true);
        s.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
        web.setWebViewClient(new WebViewClient());
        web.setWebChromeClient(new WebChromeClient());
        web.addJavascriptInterface(new Bridge(), "AndroidBridge");
        setContentView(web);
        web.loadUrl("file:///android_asset/index.html");

        // Synthèse vocale (français)
        try {
            tts = new TextToSpeech(this, new TextToSpeech.OnInitListener() {
                @Override
                public void onInit(int status) {
                    if (status == TextToSpeech.SUCCESS) {
                        try { tts.setLanguage(Locale.FRENCH); } catch (Exception e) {}
                        try {
                            tts.setOnUtteranceProgressListener(new UtteranceProgressListener() {
                                @Override public void onStart(String id) {}
                                @Override public void onDone(String id) {
                                    runOnUiThread(new Runnable() {
                                        @Override public void run() {
                                            web.evaluateJavascript("window.onSpeakDone&&onSpeakDone()", null);
                                        }
                                    });
                                }
                                @Override public void onError(String id) {}
                            });
                        } catch (Exception e) {}
                        ttsReady = true;
                        if (pendingSpeak != null) { doSpeak(pendingSpeak); pendingSpeak = null; }
                    }
                }
            });
        } catch (Exception e) {}

        // Permission notifications (Android 13+) + programmation du rappel quotidien
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"}, 1);
            }
        } catch (Exception e) {}
        try { NotifReceiver.scheduleDaily(this); } catch (Exception e) {}
    }

    private void doSpeak(String text) {
        if (tts == null || text == null) return;
        try { tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, "tcd"); } catch (Exception e) {}
    }

    @Override
    protected void onDestroy() {
        try { if (tts != null) { tts.stop(); tts.shutdown(); } } catch (Exception e) {}
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        web.evaluateJavascript("window.appBack ? appBack() : 'exit'", new android.webkit.ValueCallback<String>() {
            @Override
            public void onReceiveValue(String value) {
                if (value == null || value.contains("exit")) {
                    finish();
                }
            }
        });
    }

    class Bridge {
        @JavascriptInterface
        public void fetchUrl(final String url, final int id) {
            pool.execute(new Runnable() {
                @Override
                public void run() {
                    String body = "";
                    try {
                        HttpURLConnection c = (HttpURLConnection) new URL(url).openConnection();
                        c.setConnectTimeout(12000);
                        c.setReadTimeout(12000);
                        c.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36");
                        c.setInstanceFollowRedirects(true);
                        InputStream in = c.getInputStream();
                        ByteArrayOutputStream bos = new ByteArrayOutputStream();
                        byte[] buf = new byte[8192];
                        int n;
                        while ((n = in.read(buf)) > 0) bos.write(buf, 0, n);
                        in.close();
                        byte[] bytes = bos.toByteArray();
                        String charset = null;
                        String ct = c.getContentType();
                        if (ct != null) {
                            Matcher m = Pattern.compile("(?i)charset=([\\w\\-]+)").matcher(ct);
                            if (m.find()) charset = m.group(1);
                        }
                        if (charset == null) {
                            String head = new String(bytes, 0, Math.min(bytes.length, 3000), "US-ASCII");
                            Matcher m = Pattern.compile("(?i)(?:encoding|charset)\\s*=\\s*[\"']?([\\w\\-]+)").matcher(head);
                            if (m.find()) charset = m.group(1);
                        }
                        if (charset == null) charset = "UTF-8";
                        body = new String(bytes, charset);
                    } catch (Exception e) {
                        body = "";
                    }
                    String b64;
                    try {
                        b64 = Base64.encodeToString(body.getBytes("UTF-8"), Base64.NO_WRAP);
                    } catch (Exception e) {
                        b64 = "";
                    }
                    final String payload = b64;
                    runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            web.evaluateJavascript("onFetchDone(" + id + ",'" + payload + "')", null);
                        }
                    });
                }
            });
        }

        @JavascriptInterface
        public void speak(final String text) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (ttsReady) doSpeak(text); else pendingSpeak = text;
                }
            });
        }

        @JavascriptInterface
        public void stopSpeak() {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try { if (tts != null) tts.stop(); } catch (Exception e) {}
                    pendingSpeak = null;
                }
            });
        }

        @JavascriptInterface
        public void share(final String text) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    try {
                        Intent i = new Intent(Intent.ACTION_SEND);
                        i.setType("text/plain");
                        i.putExtra(Intent.EXTRA_TEXT, text);
                        Intent chooser = Intent.createChooser(i, "Partager l'article");
                        chooser.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        startActivity(chooser);
                    } catch (Exception e) {}
                }
            });
        }

        @JavascriptInterface
        public void saveCache(String data) {
            try {
                FileOutputStream f = openFileOutput("cache.json", MODE_PRIVATE);
                f.write(data.getBytes("UTF-8"));
                f.close();
            } catch (Exception e) { }
        }

        @JavascriptInterface
        public String loadCache() {
            try {
                FileInputStream f = openFileInput("cache.json");
                ByteArrayOutputStream b = new ByteArrayOutputStream();
                byte[] buf = new byte[8192];
                int n;
                while ((n = f.read(buf)) > 0) b.write(buf, 0, n);
                f.close();
                return b.toString("UTF-8");
            } catch (Exception e) {
                return "";
            }
        }
    }
}
