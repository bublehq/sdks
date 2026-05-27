defmodule Buble.ChatTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, client} = Buble.Client.new(api_key: "sk-test", transport: Buble.TestTransport)
    %{client: client}
  end

  test "creates OpenAI-compatible chat completions", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :post
      assert path == "/api/v1/chat/completions"
      assert Keyword.fetch!(opts, :json)["stream"] == false
      {:ok, %{"choices" => [%{"message" => %{"content" => "Hello"}}]}}
    end)

    assert {:ok, %{"choices" => [_]}} =
             Buble.Chat.Completions.create(client, %{
               model: "chatgpt-5-4",
               messages: [%{role: "user", content: "Hello"}]
             })
  end

  test "streams OpenAI-compatible text", %{client: client} do
    Process.put(:buble_test_handler, fn _client, _method, _path, _opts ->
      {:ok,
       """
       data: {"choices":[{"delta":{"content":"Hel"}}]}

       data: {"choices":[{"delta":{"content":"lo"}}]}

       data: [DONE]

       """}
    end)

    assert {:ok, stream} =
             Buble.Chat.Completions.stream_text(client, %{model: "chatgpt-5-4", messages: []})

    assert Enum.to_list(stream) == ["Hel", "lo"]
  end

  test "calls Anthropic Messages-compatible endpoint", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :post
      assert path == "/api/v1/messages"
      assert Keyword.fetch!(opts, :json)["stream"] == false
      {:ok, %{"content" => [%{"text" => "Hello"}]}}
    end)

    assert {:ok, %{"content" => [_]}} =
             Buble.Chat.Messages.create(client, model: "claude", messages: [])
  end

  test "calls Gemini-compatible endpoint", %{client: client} do
    Process.put(:buble_test_handler, fn _client, method, path, opts ->
      assert method == :post
      assert path == "/api/v1beta/models/gemini-3-pro:generateContent"
      assert Keyword.fetch!(opts, :json) == %{"contents" => []}
      {:ok, %{"candidates" => []}}
    end)

    assert {:ok, %{"candidates" => []}} =
             Buble.Chat.Gemini.generate_content(client, "gemini-3-pro", contents: [])
  end
end
