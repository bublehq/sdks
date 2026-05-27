defmodule Buble.Multipart do
  @moduledoc false

  alias Buble.Error

  @type file_source ::
          String.t()
          | {:path, String.t()}
          | {:binary, binary(), keyword()}
          | %{
              required(:content) => binary(),
              optional(:filename) => String.t(),
              optional(:content_type) => String.t()
            }

  @spec build(map(), file_source()) :: {:ok, binary(), String.t()} | {:error, Error.t()}
  def build(fields, file) when is_map(fields) do
    with {:ok, upload} <- read_file(file) do
      boundary = "buble-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)

      body =
        [
          field_parts(boundary, fields),
          file_part(boundary, upload),
          "--",
          boundary,
          "--\r\n"
        ]
        |> IO.iodata_to_binary()

      {:ok, body, "multipart/form-data; boundary=#{boundary}"}
    end
  end

  defp read_file({:path, path}), do: read_file(path)

  defp read_file(path) when is_binary(path) do
    case File.read(path) do
      {:ok, content} ->
        {:ok,
         %{
           content: content,
           filename: Path.basename(path),
           content_type: "application/octet-stream"
         }}

      {:error, reason} ->
        {:error,
         Error.new(
           :api,
           "Failed to read upload file #{inspect(path)}: #{:file.format_error(reason)}"
         )}
    end
  end

  defp read_file({:binary, content, opts}) when is_binary(content) and is_list(opts) do
    {:ok,
     %{
       content: content,
       filename: Keyword.get(opts, :filename, "upload"),
       content_type: Keyword.get(opts, :content_type, "application/octet-stream")
     }}
  end

  defp read_file(%{content: content} = upload) when is_binary(content) do
    {:ok,
     %{
       content: content,
       filename: Map.get(upload, :filename, "upload"),
       content_type: Map.get(upload, :content_type, "application/octet-stream")
     }}
  end

  defp read_file(_file) do
    {:error,
     Error.new(
       :api,
       "file must be a path, {:path, path}, {:binary, content, opts}, or a map with :content."
     )}
  end

  defp field_parts(boundary, fields) do
    fields
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == "" end)
    |> Enum.map(fn {key, value} ->
      [
        "--",
        boundary,
        "\r\n",
        "Content-Disposition: form-data; name=\"",
        escape_name(key),
        "\"\r\n\r\n",
        to_string(value),
        "\r\n"
      ]
    end)
  end

  defp file_part(boundary, upload) do
    [
      "--",
      boundary,
      "\r\n",
      "Content-Disposition: form-data; name=\"file\"; filename=\"",
      escape_name(upload.filename),
      "\"\r\n",
      "Content-Type: ",
      upload.content_type,
      "\r\n\r\n",
      upload.content,
      "\r\n"
    ]
  end

  defp escape_name(value) do
    value
    |> to_string()
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end
end
