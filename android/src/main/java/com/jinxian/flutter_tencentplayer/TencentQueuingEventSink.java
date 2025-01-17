package com.jinxian.flutter_tencentplayer;

import android.app.Activity;
import android.os.Handler;
import android.os.Message;

import androidx.annotation.NonNull;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.EventChannel;

/**
 * And implementation of {@link EventChannel.EventSink} which can wrap an underlying sink.
 *
 * <p>It delivers messages immediately when downstream is available, but it queues messages before
 * the delegate event sink is set with setDelegate.
 *
 * <p>This class is not thread-safe. All calls must be done on the same thread or synchronized
 * externally.
 */
final class TencentQueuingEventSink implements EventChannel.EventSink {
    private EventChannel.EventSink delegate;
    private ArrayList<Object> eventQueue = new ArrayList<>();
    private boolean done = false;
    private Handler mHandler;

    private Activity activity;

    public TencentQueuingEventSink(Activity activity) {
        this.activity = activity;

        mHandler = new UIHandler(this);
    }

    public void setDelegate(EventChannel.EventSink delegate) {
        this.delegate = delegate;
        maybeFlush();
    }

    @Override
    public void endOfStream() {
        enqueue(new EndOfStreamEvent());
        maybeFlush();
        done = true;
    }

    @Override
    public void error(String code, String message, Object details) {
        enqueue(new ErrorEvent(code, message, details));
        maybeFlush();
    }

    @Override
    public void success(Object event) {
        enqueue(event);
        maybeFlush();
    }

    private void enqueue(Object event) {
        if (done) {
            return;
        }
        eventQueue.add(event);
    }

    private void maybeFlush() {
        if (delegate == null) {
            return;
        }
        for (Object event : eventQueue) {
            if (event instanceof EndOfStreamEvent) {
                delegate.endOfStream();
            } else if (event instanceof ErrorEvent) {
                ErrorEvent errorEvent = (ErrorEvent) event;
                delegate.error(errorEvent.code, errorEvent.message, errorEvent.details);
            } else {
                mHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        if(delegate != null){
                            delegate.success(event);
                        }
                    }
                });
//                activity.runOnUiThread(new Runnable() {
//                    @Override
//                    public void run() {
//                        delegate.success(event);
//                    }
//                });
            }
        }
        eventQueue.clear();
    }

    static class UIHandler extends Handler {
        WeakReference<TencentQueuingEventSink> pluginReference;

        public UIHandler(TencentQueuingEventSink plugin) {
            pluginReference = new WeakReference<>(plugin);
        }

        @Override
        public void handleMessage(@NonNull Message msg) {
        }
    }

    private static class EndOfStreamEvent {
    }

    private static class ErrorEvent {
        String code;
        String message;
        Object details;

        ErrorEvent(String code, String message, Object details) {
            this.code = code;
            this.message = message;
            this.details = details;
        }
    }
}
