defmodule Buble.AppsTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, client} = Buble.Client.new(api_key: "sk-test", transport: Buble.TestTransport)
    %{client: client}
  end

  test "lists and retrieves apps", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, _opts ->
      assert method == :get
      assert path in ["/api/v1/apps", "/api/v1/apps/video-background-remover"]
      {:ok, %{"data" => []}}
    end)

    assert {:ok, _} = Buble.Apps.list(client)
    assert {:ok, _} = Buble.Apps.retrieve(client, "video-background-remover")
  end

  test "creates app generations", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :post
      assert path == "/api/v1/apps/video-background-remover/generations"
      assert Keyword.fetch!(opts, :json) == %{"video_url" => "https://example.test/input.mp4"}
      {:ok, %{"data" => %{"id" => "app_gen_123"}}}
    end)

    assert {:ok, %{"data" => %{"id" => "app_gen_123"}}} =
             Buble.Apps.Generations.create(client, "video-background-remover",
               video_url: "https://example.test/input.mp4"
             )
  end
end
