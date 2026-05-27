ExUnit.start()

defmodule Buble.TestTransport do
  @behaviour Buble.Transport

  @impl true
  def request(client, method, path, opts) do
    handler = Process.get(:buble_test_handler)

    if is_function(handler, 4) do
      handler.(client, method, path, opts)
    else
      {:ok, %{}}
    end
  end

  @impl true
  def stream(client, method, path, opts) do
    case request(client, method, path, opts) do
      {:ok, body} when is_binary(body) -> {:ok, Buble.SSE.events(body)}
      {:ok, body} -> {:ok, Buble.SSE.events(Jason.encode!(body))}
      {:error, error} -> {:error, error}
    end
  end
end
