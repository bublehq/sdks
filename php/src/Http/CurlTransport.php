<?php

declare(strict_types=1);

namespace Buble\Http;

use Buble\Exception\ApiException;
use Buble\Exception\BubleException;
use Buble\Exception\TimeoutException;
use Buble\RequestOptions;
use Buble\Streaming\SseEvent;
use Buble\Streaming\SseParser;

final class CurlTransport implements TransportInterface
{
    /**
     * @param array<string, string> $headers
     */
    public function __construct(
        private readonly string $apiKey,
        private readonly string $baseUrl,
        private readonly float $timeout,
        private readonly array $headers = [],
    ) {
    }

    /**
     * @param array<string, mixed>|null $body
     * @return array<string, mixed>
     */
    public function request(string $method, string $path, ?array $body = null, ?RequestOptions $options = null): array
    {
        $headers = ['Accept' => 'application/json'];
        $payload = null;
        if ($body !== null) {
            $payload = $this->encodeJson($body);
            $headers['Content-Type'] = 'application/json';
        }

        [$status, $responseBody] = $this->send(
            $method,
            $this->resolve($path, $this->queryFromOptions($options)),
            $headers,
            $payload,
            $options,
        );

        return $this->decodeResponse($status, $responseBody);
    }

    /**
     * @param array<string, mixed> $fields
     * @return array<string, mixed>
     */
    public function multipart(string $path, array $fields, FilePart $file, ?RequestOptions $options = null): array
    {
        $body = [];
        foreach ($fields as $key => $value) {
            if ($value !== null && $value !== '' && is_scalar($value)) {
                $body[$key] = (string) $value;
            }
        }
        $body['file'] = $file->toCurlFile();

        try {
            [$status, $responseBody] = $this->send(
                'POST',
                $this->resolve($path, $this->queryFromOptions($options)),
                ['Accept' => 'application/json'],
                $body,
                $options,
            );
        } finally {
            $file->cleanup();
        }

        return $this->decodeResponse($status, $responseBody);
    }

    /**
     * @param array<string, mixed> $body
     * @return \Generator<int, SseEvent>
     */
    public function stream(string $path, array $body, ?RequestOptions $options = null): \Generator
    {
        $parser = new SseParser();

        $headers = $this->formatHeaders(array_merge(
            [
                'Authorization' => 'Bearer ' . $this->apiKey,
                'Accept' => 'text/event-stream',
                'Content-Type' => 'application/json',
            ],
            $this->headers,
            $this->headersFromOptions($options),
        ));

        $context = stream_context_create([
            'http' => [
                'method' => 'POST',
                'header' => implode("\r\n", $headers),
                'content' => $this->encodeJson($body),
                'timeout' => $this->timeout,
                'ignore_errors' => true,
            ],
        ]);

        $stream = @fopen($this->resolve($path, $this->queryFromOptions($options)), 'rb', false, $context);
        if ($stream === false) {
            throw new BubleException('Failed to open Buble API stream.');
        }

        try {
            $responseHeaders = $this->lastResponseHeaders();
            if ($responseHeaders === [] && PHP_VERSION_ID < 80500) {
                $responseHeaders = $this->responseHeadersFromScope(compact('http_response_header'));
            }

            $status = $this->statusFromResponseHeaders($responseHeaders);
            if ($status < 200 || $status >= 300) {
                $bodyText = stream_get_contents($stream);
                throw $this->apiException($status, $bodyText === false ? '' : $bodyText);
            }

            while (($line = fgets($stream)) !== false) {
                $event = $parser->pushLine(rtrim($line, "\r\n"));
                if ($event !== null) {
                    yield $event;
                }
            }
            $finalEvent = $parser->finish();
            if ($finalEvent !== null) {
                yield $finalEvent;
            }
        } finally {
            fclose($stream);
        }
    }

    /**
     * @param array<string, string> $headers
     * @param string|array<string, mixed>|null $body
     * @return array{0:int, 1:string}
     */
    private function send(
        string $method,
        string $url,
        array $headers,
        string|array|null $body,
        ?RequestOptions $options,
    ): array {
        $ch = $this->createCurl($method, $url, $headers, $body, $options);
        $response = curl_exec($ch);
        if ($response === false) {
            $this->throwCurlError($ch);
        }
        $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);

        return [$status, (string) $response];
    }

    /**
     * @param array<string, string> $headers
     * @param string|array<string, mixed>|null $body
     */
    private function createCurl(
        string $method,
        string $url,
        array $headers,
        string|array|null $body,
        ?RequestOptions $options,
    ): \CurlHandle {
        $ch = curl_init($url);
        if ($ch === false) {
            throw new BubleException('Failed to initialize cURL.');
        }

        $mergedHeaders = array_merge(
            ['Authorization' => 'Bearer ' . $this->apiKey],
            $this->headers,
            $headers,
            $this->headersFromOptions($options),
        );

        $customMethod = strtoupper($method);
        if ($customMethod === '') {
            throw new BubleException('HTTP method is required.');
        }

        curl_setopt_array($ch, [
            CURLOPT_CUSTOMREQUEST => $customMethod,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT_MS => max(1, (int) round($this->timeout * 1000)),
            CURLOPT_HTTPHEADER => $this->formatHeaders($mergedHeaders),
        ]);

        if ($body !== null) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        }

        return $ch;
    }

    /**
     * @param array<string, mixed> $query
     */
    private function resolve(string $path, array $query): string
    {
        $normalizedPath = str_starts_with($path, '/') ? $path : '/' . $path;
        $url = rtrim($this->baseUrl, '/') . $normalizedPath;
        if ($query !== []) {
            $separator = str_contains($url, '?') ? '&' : '?';
            $url .= $separator . http_build_query($query, '', '&', PHP_QUERY_RFC3986);
        }

        return $url;
    }

    /**
     * @param array<string, string> $headers
     * @return list<string>
     */
    private function formatHeaders(array $headers): array
    {
        $out = [];
        foreach ($headers as $name => $value) {
            $out[] = $name . ': ' . $value;
        }

        return $out;
    }

    /**
     * @param array<string, mixed> $body
     */
    private function encodeJson(array $body): string
    {
        try {
            return json_encode($body, JSON_THROW_ON_ERROR);
        } catch (\JsonException $exception) {
            throw new BubleException('Failed to encode Buble API request body.', 0, $exception);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function decodeResponse(int $status, string $responseBody): array
    {
        if ($status < 200 || $status >= 300) {
            throw $this->apiException($status, $responseBody);
        }
        if ($responseBody === '') {
            return [];
        }

        try {
            $decoded = json_decode($responseBody, true, flags: JSON_THROW_ON_ERROR);
        } catch (\JsonException $exception) {
            throw new BubleException('Failed to parse Buble API response.', 0, $exception);
        }

        if (!is_array($decoded)) {
            throw new BubleException('Buble API returned a non-object JSON response.');
        }

        return $this->stringKeyArray($decoded);
    }

    private function apiException(int $status, string $responseBody): ApiException
    {
        $message = $responseBody !== '' ? $responseBody : 'Buble API request failed with status ' . $status . '.';
        $code = null;
        $details = null;

        try {
            $decoded = json_decode($responseBody, true, flags: JSON_THROW_ON_ERROR);
            if (is_array($decoded) && isset($decoded['error']) && is_array($decoded['error'])) {
                $error = $decoded['error'];
                $message = isset($error['message']) && is_string($error['message']) ? $error['message'] : $message;
                $code = isset($error['code']) && is_string($error['code']) ? $error['code'] : null;
                $details = isset($error['details']) && is_array($error['details'])
                    ? $this->stringKeyArray($error['details'])
                    : null;
            }
        } catch (\JsonException) {
            // Use the raw response body when the server did not return JSON.
        }

        return new ApiException($status, $code, $message, $details, $responseBody);
    }

    private function throwCurlError(\CurlHandle $ch): never
    {
        $errno = curl_errno($ch);
        $message = curl_error($ch);

        if ($errno === CURLE_OPERATION_TIMEDOUT) {
            throw new TimeoutException(
                'Buble API request timed out after ' . $this->timeout . ' seconds.',
                $this->timeout,
            );
        }

        throw new BubleException('Buble API request failed: ' . $message);
    }

    /**
     * @return array<string, string>
     */
    private function queryFromOptions(?RequestOptions $options): array
    {
        return $options === null ? [] : $options->query;
    }

    /**
     * @return array<string, string>
     */
    private function headersFromOptions(?RequestOptions $options): array
    {
        return $options === null ? [] : $options->headers;
    }

    /**
     * @param array<mixed> $value
     * @return array<string, mixed>
     */
    private function stringKeyArray(array $value): array
    {
        $out = [];
        foreach ($value as $key => $item) {
            if (is_string($key)) {
                $out[$key] = $item;
            }
        }

        return $out;
    }

    /**
     * @param list<string> $headers
     */
    private function statusFromResponseHeaders(array $headers): int
    {
        foreach ($headers as $header) {
            if (preg_match('/^HTTP\/\S+\s+(\d{3})/', $header, $matches) === 1) {
                return (int) $matches[1];
            }
        }

        return 0;
    }

    /**
     * @return list<string>
     */
    private function lastResponseHeaders(): array
    {
        if (function_exists('http_get_last_response_headers')) {
            $headers = http_get_last_response_headers();

            return is_array($headers) ? $this->stringList($headers) : [];
        }

        return [];
    }

    /**
     * @param array<string, mixed> $scope
     * @return list<string>
     */
    private function responseHeadersFromScope(array $scope): array
    {
        $headers = $scope['http_response_header'] ?? [];

        return is_array($headers) ? $this->stringList($headers) : [];
    }

    /**
     * @param array<mixed> $headers
     * @return list<string>
     */
    private function stringList(array $headers): array
    {
        $out = [];
        foreach ($headers as $header) {
            if (is_string($header)) {
                $out[] = $header;
            }
        }

        return $out;
    }
}
