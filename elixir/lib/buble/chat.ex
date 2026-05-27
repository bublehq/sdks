defmodule Buble.Chat do
  @moduledoc """
  Chat model methods for OpenAI, Anthropic Messages, and Gemini-compatible APIs.
  """
end

defmodule Buble.Chat.Models do
  @moduledoc """
  Chat model discovery methods.
  """

  alias Buble.Client
  alias Buble.Error

  @spec list(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Client{} = client), do: Client.request(client, :get, "/api/v1/models")

  @spec list!(Client.t()) :: map()
  def list!(%Client{} = client), do: Buble.unwrap!(list(client))
end

defmodule Buble.Chat.Completions do
  @moduledoc """
  OpenAI-compatible chat completions methods.
  """

  alias Buble.Client
  alias Buble.Error
  alias Buble.SSE

  @spec create(Client.t(), keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def create(%Client{} = client, body) do
    Client.request(client, :post, "/api/v1/chat/completions", json: stream_body(body, false))
  end

  @spec create!(Client.t(), keyword() | map()) :: map()
  def create!(%Client{} = client, body), do: Buble.unwrap!(create(client, body))

  @spec stream(Client.t(), keyword() | map()) :: {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream(%Client{} = client, body) do
    Client.stream(client, :post, "/api/v1/chat/completions", json: stream_body(body, true))
  end

  @spec stream_text(Client.t(), keyword() | map()) :: {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream_text(%Client{} = client, body) do
    with {:ok, events} <- stream(client, body) do
      {:ok, SSE.text_stream(events, :openai)}
    end
  end

  defp stream_body(body, value), do: Map.put(Buble.normalize_params(body), "stream", value)
end

defmodule Buble.Chat.Messages do
  @moduledoc """
  Anthropic Messages-compatible methods.
  """

  alias Buble.Client
  alias Buble.Error
  alias Buble.SSE

  @spec create(Client.t(), keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def create(%Client{} = client, body) do
    Client.request(client, :post, "/api/v1/messages", json: stream_body(body, false))
  end

  @spec create!(Client.t(), keyword() | map()) :: map()
  def create!(%Client{} = client, body), do: Buble.unwrap!(create(client, body))

  @spec stream(Client.t(), keyword() | map()) :: {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream(%Client{} = client, body) do
    Client.stream(client, :post, "/api/v1/messages", json: stream_body(body, true))
  end

  @spec stream_text(Client.t(), keyword() | map()) :: {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream_text(%Client{} = client, body) do
    with {:ok, events} <- stream(client, body) do
      {:ok, SSE.text_stream(events, :anthropic)}
    end
  end

  defp stream_body(body, value), do: Map.put(Buble.normalize_params(body), "stream", value)
end

defmodule Buble.Chat.Gemini do
  @moduledoc """
  Gemini-compatible content generation methods.
  """

  alias Buble.Client
  alias Buble.Error
  alias Buble.SSE

  @spec generate_content(Client.t(), String.t(), keyword() | map()) ::
          {:ok, map()} | {:error, Error.t()}
  def generate_content(%Client{} = client, model, body) do
    Client.request(
      client,
      :post,
      "/api/v1beta/models/#{Buble.HTTP.encode_model_path(model)}:generateContent",
      json: Buble.normalize_params(body)
    )
  end

  @spec generate_content!(Client.t(), String.t(), keyword() | map()) :: map()
  def generate_content!(%Client{} = client, model, body),
    do: Buble.unwrap!(generate_content(client, model, body))

  @spec stream_generate_content(Client.t(), String.t(), keyword() | map()) ::
          {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream_generate_content(%Client{} = client, model, body) do
    Client.stream(
      client,
      :post,
      "/api/v1beta/models/#{Buble.HTTP.encode_model_path(model)}:streamGenerateContent",
      json: Buble.normalize_params(body)
    )
  end

  @spec stream_text(Client.t(), String.t(), keyword() | map()) ::
          {:ok, Enumerable.t()} | {:error, Error.t()}
  def stream_text(%Client{} = client, model, body) do
    with {:ok, events} <- stream_generate_content(client, model, body) do
      {:ok, SSE.text_stream(events, :gemini)}
    end
  end
end
