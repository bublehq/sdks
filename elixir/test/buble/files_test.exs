defmodule Buble.FilesTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, client} = Buble.Client.new(api_key: "sk-test", transport: Buble.TestTransport)
    %{client: client}
  end

  test "uploads binary multipart payloads", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :post
      assert path == "/api/v1/files"
      body = Keyword.fetch!(opts, :body)
      headers = Keyword.fetch!(opts, :headers)

      assert {"content-type", content_type} = List.keyfind(headers, "content-type", 0)
      assert String.starts_with?(content_type, "multipart/form-data; boundary=")
      assert body =~ ~s(name="file"; filename="reference.png")
      assert body =~ ~s(name="file_type")
      assert body =~ "image"

      {:ok, %{"data" => %{"url" => "https://example.test/reference.png"}}}
    end)

    assert {:ok, %{"data" => %{"url" => _url}}} =
             Buble.Files.upload(
               client,
               {:binary, "png-bytes", filename: "reference.png", content_type: "image/png"},
               file_type: "image",
               model: "nano-banana"
             )
  end
end
