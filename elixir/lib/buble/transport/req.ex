defmodule Buble.Transport.Req do
  @moduledoc """
  Default Req-based HTTP transport.
  """

  @behaviour Buble.Transport

  alias Buble.Client
  alias Buble.Error
  alias Buble.SSE

  @impl true
  def request(%Client{} = client, method, path, opts) do
    request_opts = build_request_opts(client, method, path, opts)

    case Req.request(request_opts) do
      {:ok, %Req.Response{status: status, body: body}} when status >= 200 and status < 300 ->
        {:ok, body || %{}}

      {:ok, %Req.Response{} = response} ->
        {:error, api_error(response)}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, Error.new(:timeout, "Buble API request timed out.", raw: :timeout)}

      {:error, error} ->
        {:error, Error.new(:api, Exception.message(error), raw: error)}
    end
  end

  @impl true
  def stream(%Client{} = client, method, path, opts) do
    opts =
      Keyword.update(opts, :headers, [{"accept", "text/event-stream"}], fn headers ->
        [{"accept", "text/event-stream"} | Client.normalize_headers(headers)]
      end)

    request_opts =
      client
      |> build_request_opts(method, path, opts)
      |> Keyword.put(:into, :self)
      |> Keyword.put(:decode_body, false)

    case Req.request(request_opts) do
      {:ok, %Req.Response{status: status, body: body}} when status >= 200 and status < 300 ->
        {:ok, SSE.events_from_chunks(body)}

      {:ok, %Req.Response{} = response} ->
        {:error, api_error(response)}

      {:error, %Req.TransportError{reason: :timeout}} ->
        {:error, Error.new(:timeout, "Buble API request timed out.", raw: :timeout)}

      {:error, error} ->
        {:error, Error.new(:api, Exception.message(error), raw: error)}
    end
  end

  defp build_request_opts(%Client{} = client, method, path, opts) do
    headers =
      [
        {"authorization", "Bearer #{client.api_key}"},
        {"accept", "application/json"}
      ] ++ client.headers ++ Client.normalize_headers(Keyword.get(opts, :headers, []))

    [
      method: method,
      url: resolve_url(client.base_url, path),
      headers: headers,
      params: Keyword.get(opts, :query, []),
      receive_timeout: Keyword.get(opts, :timeout, client.timeout)
    ]
    |> put_body(opts)
  end

  defp put_body(request_opts, opts) do
    cond do
      Keyword.has_key?(opts, :json) ->
        request_opts
        |> Keyword.put(:json, Keyword.fetch!(opts, :json))
        |> Keyword.update(:headers, [{"content-type", "application/json"}], fn headers ->
          [{"content-type", "application/json"} | headers]
        end)

      Keyword.has_key?(opts, :body) ->
        Keyword.put(request_opts, :body, Keyword.fetch!(opts, :body))

      true ->
        request_opts
    end
  end

  defp resolve_url(base_url, path) do
    normalized_path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"
    base_url <> normalized_path
  end

  defp api_error(%Req.Response{status: status, body: body}) do
    {message, code, details} = parse_error_body(body, status)

    Error.new(
      :api,
      message,
      status: status,
      code: code,
      details: details,
      raw: body
    )
  end

  defp parse_error_body(%{"error" => %{} = error}, status) do
    {
      Map.get(error, "message", "Buble API request failed with status #{status}."),
      Map.get(error, "code"),
      Map.get(error, "details")
    }
  end

  defp parse_error_body(%{error: %{} = error}, status) do
    {
      Map.get(error, :message, "Buble API request failed with status #{status}."),
      Map.get(error, :code),
      Map.get(error, :details)
    }
  end

  defp parse_error_body(body, status) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> parse_error_body(decoded, status)
      {:error, _error} -> {body, nil, nil}
    end
  end

  defp parse_error_body(_body, status) do
    {"Buble API request failed with status #{status}.", nil, nil}
  end
end
