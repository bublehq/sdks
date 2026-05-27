defmodule Buble.MediaModelsTest do
  use ExUnit.Case, async: true

  test "lists media models with query filters" do
    {:ok, client} = Buble.Client.new(api_key: "sk-test", transport: Buble.TestTransport)

    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :get
      assert path == "/api/v1/media_models"
      assert Keyword.fetch!(opts, :query) == %{"media_type" => "image"}
      {:ok, %{"data" => []}}
    end)

    assert {:ok, %{"data" => []}} = Buble.MediaModels.list(client, media_type: "image")
  end
end
