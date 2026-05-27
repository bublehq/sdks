defmodule Buble.SSETest do
  use ExUnit.Case, async: true

  test "parses server-sent events" do
    body = """
    event: message
    id: 1
    data: {"choices":[{"delta":{"content":"Hello"}}]}

    data: [DONE]

    """

    assert [
             %Buble.SSE.Event{event: "message", id: "1", data: data},
             %Buble.SSE.Event{data: "[DONE]"}
           ] = Enum.to_list(Buble.SSE.events(body))

    assert data == ~s({"choices":[{"delta":{"content":"Hello"}}]})
  end

  test "parses events across response chunks" do
    chunks = [
      "data: {\"choices\":[{\"delta\"",
      ":{\"content\":\"Hel\"}}]}\n\n",
      "data: {\"choices\":[{\"delta\":{\"content\":\"lo\"}}]}\n\n"
    ]

    assert ["Hel", "lo"] =
             chunks
             |> Buble.SSE.events_from_chunks()
             |> Buble.SSE.text_stream(:openai)
             |> Enum.to_list()
  end

  test "extracts text by protocol" do
    event = %Buble.SSE.Event{data: ~s({"choices":[{"delta":{"content":"Hello"}}]})}
    assert {:ok, "Hello"} = Buble.SSE.text_from_event(event, :openai)

    event = %Buble.SSE.Event{data: ~s({"type":"content_block_delta","delta":{"text":"Hi"}})}
    assert {:ok, "Hi"} = Buble.SSE.text_from_event(event, :anthropic)

    event = %Buble.SSE.Event{data: ~s({"candidates":[{"content":{"parts":[{"text":"Hey"}]}}]})}
    assert {:ok, "Hey"} = Buble.SSE.text_from_event(event, :gemini)
  end
end
