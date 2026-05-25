package ai.buble.sdk;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;

final class TestHttpServer implements AutoCloseable {
    private final ServerSocket server;
    private final Thread thread;
    private final Function<CapturedRequest, Response> handler;
    private final List<CapturedRequest> requests = new ArrayList<CapturedRequest>();
    private volatile boolean closed;

    TestHttpServer(Function<CapturedRequest, Response> handler) throws IOException {
        this.handler = handler;
        this.server = new ServerSocket(0);
        this.thread = new Thread(this::serve, "buble-sdk-test-http");
        this.thread.setDaemon(true);
        this.thread.start();
    }

    String url() {
        return "http://127.0.0.1:" + server.getLocalPort();
    }

    List<CapturedRequest> requests() {
        return requests;
    }

    @Override
    public void close() throws IOException {
        closed = true;
        server.close();
    }

    private void serve() {
        while (!closed) {
            try (Socket socket = server.accept()) {
                CapturedRequest request = capture(socket.getInputStream());
                synchronized (requests) {
                    requests.add(request);
                }
                Response response = handler.apply(request);
                write(socket.getOutputStream(), response);
            } catch (IOException ignored) {
                if (!closed) {
                    throw new RuntimeException(ignored);
                }
            }
        }
    }

    private static CapturedRequest capture(InputStream input) throws IOException {
        String requestLine = readLine(input);
        String[] parts = requestLine.split(" ", 3);
        Map<String, String> headers = new LinkedHashMap<String, String>();
        String line;
        while ((line = readLine(input)) != null && !line.isEmpty()) {
            int colon = line.indexOf(':');
            if (colon > 0) {
                headers.put(line.substring(0, colon).toLowerCase(Locale.ROOT), line.substring(colon + 1).trim());
            }
        }
        byte[] body = readBody(input, headers);
        return new CapturedRequest(
                parts[0],
                parts[1],
                headers.get("authorization"),
                headers.get("accept"),
                headers.get("content-type"),
                new String(body, StandardCharsets.UTF_8)
        );
    }

    private static byte[] readBody(InputStream input, Map<String, String> headers) throws IOException {
        if ("chunked".equalsIgnoreCase(headers.get("transfer-encoding"))) {
            ByteArrayOutputStream body = new ByteArrayOutputStream();
            while (true) {
                String sizeLine = readLine(input);
                int semicolon = sizeLine.indexOf(';');
                String sizeText = semicolon >= 0 ? sizeLine.substring(0, semicolon) : sizeLine;
                int size = Integer.parseInt(sizeText.trim(), 16);
                if (size == 0) {
                    readLine(input);
                    return body.toByteArray();
                }
                body.write(readBytes(input, size));
                readLine(input);
            }
        }
        int length = 0;
        if (headers.containsKey("content-length")) {
            length = Integer.parseInt(headers.get("content-length"));
        }
        return readBytes(input, length);
    }

    private static byte[] readBytes(InputStream input, int length) throws IOException {
        byte[] bytes = new byte[length];
        int offset = 0;
        while (offset < length) {
            int count = input.read(bytes, offset, length - offset);
            if (count < 0) {
                break;
            }
            offset += count;
        }
        if (offset == length) {
            return bytes;
        }
        byte[] truncated = new byte[offset];
        System.arraycopy(bytes, 0, truncated, 0, offset);
        return truncated;
    }

    private static String readLine(InputStream input) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        int previous = -1;
        int current;
        while ((current = input.read()) != -1) {
            if (previous == '\r' && current == '\n') {
                byte[] bytes = out.toByteArray();
                return new String(bytes, 0, bytes.length - 1, StandardCharsets.UTF_8);
            }
            out.write(current);
            previous = current;
        }
        if (out.size() == 0) {
            return null;
        }
        return out.toString(StandardCharsets.UTF_8);
    }

    private static void write(OutputStream output, Response response) throws IOException {
        byte[] body = response.body.getBytes(StandardCharsets.UTF_8);
        ByteArrayOutputStream head = new ByteArrayOutputStream();
        head.write(("HTTP/1.1 " + response.status + " OK\r\n").getBytes(StandardCharsets.UTF_8));
        head.write(("Content-Length: " + body.length + "\r\n").getBytes(StandardCharsets.UTF_8));
        for (String[] header : response.headers) {
            head.write((header[0] + ": " + header[1] + "\r\n").getBytes(StandardCharsets.UTF_8));
        }
        head.write("Connection: close\r\n\r\n".getBytes(StandardCharsets.UTF_8));
        output.write(head.toByteArray());
        output.write(body);
        output.flush();
    }

    static final class CapturedRequest {
        final String method;
        final String path;
        final String authorization;
        final String accept;
        final String contentType;
        final String body;

        CapturedRequest(String method, String path, String authorization, String accept, String contentType, String body) {
            this.method = method;
            this.path = path;
            this.authorization = authorization;
            this.accept = accept;
            this.contentType = contentType;
            this.body = body;
        }
    }

    static final class Response {
        final int status;
        final String body;
        final List<String[]> headers = new ArrayList<String[]>();

        Response(int status, String body) {
            this.status = status;
            this.body = body;
            this.headers.add(new String[] {"Content-Type", "application/json"});
        }

        Response header(String name, String value) {
            this.headers.add(new String[] {name, value});
            return this;
        }
    }
}
