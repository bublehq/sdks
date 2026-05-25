/**
 * Official Java SDK for the Buble public API.
 */
module ai.buble.sdk {
    requires java.net.http;
    requires com.fasterxml.jackson.annotation;
    requires com.fasterxml.jackson.core;
    requires com.fasterxml.jackson.databind;

    exports ai.buble.sdk;
    exports ai.buble.sdk.apps;
    exports ai.buble.sdk.chat;
    exports ai.buble.sdk.files;
    exports ai.buble.sdk.generations;
    exports ai.buble.sdk.media;
    exports ai.buble.sdk.streaming;
}
