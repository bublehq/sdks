defmodule Buble.Files do
  @moduledoc """
  Source media upload methods.

  Upload a file, then pass the returned URL into generation requests as
  `image_urls`, `video_urls`, `audio_urls`, `start_frame`, or `end_frame`.
  """

  alias Buble.Client
  alias Buble.Error
  alias Buble.Multipart

  @type file_source ::
          String.t()
          | {:path, String.t()}
          | {:binary, binary(), keyword()}
          | %{
              required(:content) => binary(),
              optional(:filename) => String.t(),
              optional(:content_type) => String.t()
            }

  @spec upload(Client.t(), file_source(), keyword() | map()) ::
          {:ok, map()} | {:error, Error.t()}
  def upload(%Client{} = client, file, opts \\ []) do
    fields =
      opts
      |> Buble.normalize_params()
      |> Buble.compact_params()

    with {:ok, body, content_type} <- Multipart.build(fields, file) do
      Client.request(
        client,
        :post,
        "/api/v1/files",
        body: body,
        headers: [{"content-type", content_type}]
      )
    end
  end

  @spec upload!(Client.t(), file_source(), keyword() | map()) :: map()
  def upload!(%Client{} = client, file, opts \\ []), do: Buble.unwrap!(upload(client, file, opts))
end
