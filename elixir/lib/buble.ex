defmodule Buble do
  @moduledoc """
  Server-side Elixir SDK for the Buble public API.

  [Buble](https://buble.ai/) provides AI chat, image generation, video
  generation, file uploads, and preconfigured AI app workflows. The
  [Buble API documentation](https://buble.ai/docs) describes authentication,
  model discovery, file uploads, asynchronous generation tasks, app workflows,
  polling, and chat model endpoints.

  ## Quick start

      client = Buble.Client.new!(api_key: "sk_...")

      {:ok, task} =
        Buble.Generations.create(client, %{
          model: "nano-banana",
          prompt: "A cinematic studio product photo"
        })

      {:ok, result} = Buble.Generations.wait(client, task["data"]["id"])

  The SDK also reads `BUBLE_API_KEY` and `BUBLE_BASE_URL` from the environment
  when omitted.
  """

  alias Buble.Error

  @doc """
  Creates a `Buble.Client`.
  """
  @spec client(keyword()) :: {:ok, Buble.Client.t()} | {:error, Error.t()}
  def client(opts \\ []), do: Buble.Client.new(opts)

  @doc """
  Creates a `Buble.Client` or raises `Buble.Error`.
  """
  @spec client!(keyword()) :: Buble.Client.t()
  def client!(opts \\ []), do: Buble.Client.new!(opts)

  @doc false
  def unwrap!({:ok, value}), do: value
  def unwrap!({:error, %Error{} = error}), do: raise(error)

  @doc false
  def normalize_params(params) when is_map(params) do
    Map.new(params, fn {key, value} -> {to_string(key), value} end)
  end

  def normalize_params(params) when is_list(params) do
    params
    |> Enum.into(%{})
    |> normalize_params()
  end

  @doc false
  def compact_params(params) do
    params
    |> normalize_params()
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" or value == [] end)
    |> Map.new()
  end
end
