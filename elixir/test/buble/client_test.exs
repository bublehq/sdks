defmodule Buble.ClientTest do
  use ExUnit.Case, async: true

  test "new/1 requires an API key" do
    original = System.get_env("BUBLE_API_KEY")

    try do
      System.delete_env("BUBLE_API_KEY")
      assert {:error, %Buble.Error{type: :missing_api_key}} = Buble.Client.new()
    after
      if original, do: System.put_env("BUBLE_API_KEY", original)
    end
  end

  test "new/1 uses explicit configuration" do
    assert {:ok, client} =
             Buble.Client.new(
               api_key: "sk-test",
               base_url: "https://example.test/",
               timeout: 123,
               headers: [{"x-test", "yes"}],
               transport: Buble.TestTransport
             )

    assert client.api_key == "sk-test"
    assert client.base_url == "https://example.test"
    assert client.timeout == 123
    assert client.headers == [{"x-test", "yes"}]
    assert client.transport == Buble.TestTransport
  end
end
