defmodule Buble.Client do
  @moduledoc """
  Client configuration for the Buble public API.

  `Buble.Client.new/1` reads `BUBLE_API_KEY` and optional `BUBLE_BASE_URL` from
  the environment when explicit options are omitted.
  """

  alias Buble.Error

  @default_base_url "https://buble.ai"
  @default_timeout 60_000

  @enforce_keys [:api_key, :base_url, :transport]
  defstruct api_key: nil,
            base_url: @default_base_url,
            timeout: @default_timeout,
            headers: [],
            transport: Buble.Transport.Req

  @type header :: {String.t(), String.t()}
  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          timeout: non_neg_integer(),
          headers: [header()],
          transport: module()
        }

  @doc """
  Creates a Buble client.

  Options:

    * `:api_key` - Buble API key. Defaults to `BUBLE_API_KEY`.
    * `:base_url` - API base URL. Defaults to `BUBLE_BASE_URL` or `https://buble.ai`.
    * `:timeout` - request timeout in milliseconds. Defaults to `60_000`.
    * `:headers` - additional headers for every request.
    * `:transport` - module implementing `Buble.Transport`.
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(opts \\ []) when is_list(opts) do
    api_key = first_present(Keyword.get(opts, :api_key), System.get_env("BUBLE_API_KEY"))

    base_url =
      first_present(
        Keyword.get(opts, :base_url),
        System.get_env("BUBLE_BASE_URL"),
        @default_base_url
      )

    if blank?(api_key) do
      {:error,
       Error.new(
         :missing_api_key,
         "Missing Buble API key. Pass :api_key or set BUBLE_API_KEY."
       )}
    else
      {:ok,
       %__MODULE__{
         api_key: api_key,
         base_url: trim_trailing_slashes(base_url),
         timeout: Keyword.get(opts, :timeout, @default_timeout),
         headers: normalize_headers(Keyword.get(opts, :headers, [])),
         transport: Keyword.get(opts, :transport, Buble.Transport.Req)
       }}
    end
  end

  @doc """
  Creates a client or raises `Buble.Error`.
  """
  @spec new!(keyword()) :: t()
  def new!(opts \\ []) do
    case new(opts) do
      {:ok, client} -> client
      {:error, error} -> raise error
    end
  end

  @doc false
  @spec request(t(), atom(), String.t(), keyword()) :: {:ok, term()} | {:error, Error.t()}
  def request(%__MODULE__{} = client, method, path, opts \\ []) do
    client.transport.request(client, method, path, opts)
  end

  @doc false
  @spec stream(t(), atom(), String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream(%__MODULE__{} = client, method, path, opts \\ []) do
    client.transport.stream(client, method, path, opts)
  end

  @doc false
  def normalize_headers(headers) when is_map(headers) do
    Enum.map(headers, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  def normalize_headers(headers) when is_list(headers) do
    Enum.map(headers, fn {key, value} -> {to_string(key), to_string(value)} end)
  end

  defp first_present(values), do: Enum.find(values, &(not blank?(&1)))
  defp first_present(a, b), do: first_present([a, b])
  defp first_present(a, b, c), do: first_present([a, b, c])

  defp blank?(value), do: is_nil(value) or String.trim(to_string(value)) == ""

  defp trim_trailing_slashes(value) do
    value
    |> to_string()
    |> String.trim()
    |> String.trim_trailing("/")
  end
end
