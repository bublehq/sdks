defmodule Buble.GenerationsTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, client} = Buble.Client.new(api_key: "sk-test", transport: Buble.TestTransport)
    %{client: client}
  end

  test "create/2 sends the flat public generation body", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :post
      assert path == "/api/v1/generations"

      assert Keyword.fetch!(opts, :json) == %{
               "model" => "nano-banana",
               "prompt" => "A small robot on a desk",
               "aspect_ratio" => "16:9"
             }

      {:ok, %{"data" => %{"id" => "gen_123", "status" => "pending"}}}
    end)

    assert {:ok, %{"data" => %{"id" => "gen_123"}}} =
             Buble.Generations.create(client,
               model: "nano-banana",
               prompt: "A small robot on a desk",
               params: %{aspect_ratio: "16:9"},
               image_urls: []
             )
  end

  test "create/2 rejects known internal generation fields", %{client: client} do
    assert {:error, %Buble.Error{type: :unsupported_generation_field, details: "options"}} =
             Buble.Generations.create(client, model: "nano-banana", options: %{})
  end

  test "retrieve/2 percent-encodes path segments", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, _opts ->
      assert method == :get
      assert path == "/api/v1/generations/id%20with%20space%2Fslash"
      {:ok, %{"data" => %{"id" => "id with space/slash"}}}
    end)

    assert {:ok, _body} = Buble.Generations.retrieve(client, "id with space/slash")
  end

  test "wait/3 returns successful terminal task", %{client: client} do
    Process.put(:buble_test_handler, fn _client, :get, _path, _opts ->
      {:ok, %{"data" => %{"id" => "gen_123", "status" => "success"}}}
    end)

    assert {:ok, %{"data" => %{"status" => "success"}}} =
             Buble.Generations.wait(client, "gen_123", interval: 1, timeout: 50)
  end
end
