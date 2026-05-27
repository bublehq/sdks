defmodule Buble.MediaModels do
  @moduledoc """
  Media model discovery methods.

  Use model discovery as the source of truth for model keys, modes, required
  inputs, and public parameters. New Buble models can become available without
  an SDK release.
  """

  alias Buble.Client
  alias Buble.Error

  @spec list(Client.t(), keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Client{} = client, opts \\ []) do
    query = Buble.normalize_params(opts)
    Client.request(client, :get, "/api/v1/media_models", query: query)
  end

  @spec list!(Client.t(), keyword() | map()) :: map()
  def list!(%Client{} = client, opts \\ []) do
    Buble.unwrap!(list(client, opts))
  end
end
