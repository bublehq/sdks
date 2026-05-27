defmodule Buble.SSE.Event do
  @moduledoc """
  Server-sent event emitted by Buble streaming endpoints.
  """

  defstruct event: nil, data: "", id: nil, retry: nil

  @type t :: %__MODULE__{
          event: String.t() | nil,
          data: String.t(),
          id: String.t() | nil,
          retry: non_neg_integer() | nil
        }
end

defmodule Buble.SSE do
  @moduledoc """
  Server-sent event parser and text extraction helpers.
  """

  alias Buble.Error
  alias Buble.SSE.Event

  @spec events(binary()) :: Enumerable.t()
  def events(body) when is_binary(body) do
    body
    |> String.split(~r/\r?\n/)
    |> parse_lines()
  end

  @spec events_from_chunks(Enumerable.t()) :: Enumerable.t()
  def events_from_chunks(chunks) do
    chunks
    |> Stream.concat([""])
    |> Stream.transform("", &split_chunk/2)
    |> parse_lines()
  end

  @spec parse_lines(Enumerable.t()) :: Enumerable.t()
  def parse_lines(lines) do
    lines
    |> Stream.concat([""])
    |> Stream.transform(%Event{}, &parse_line/2)
  end

  @spec text_stream(Enumerable.t(), :openai | :anthropic | :gemini) :: Enumerable.t()
  def text_stream(events, protocol) do
    Stream.flat_map(events, fn
      %Event{data: "[DONE]"} ->
        []

      %Event{} = event ->
        case text_from_event(event, protocol) do
          {:ok, ""} -> []
          {:ok, text} -> [text]
          {:error, _error} -> []
        end
    end)
  end

  @spec text_from_event(Event.t(), :openai | :anthropic | :gemini) ::
          {:ok, String.t()} | {:error, Error.t()}
  def text_from_event(%Event{data: data}, protocol) do
    case Jason.decode(data) do
      {:ok, payload} ->
        {:ok, extract_text(payload, protocol)}

      {:error, error} ->
        {:error,
         Error.new(:stream, "Failed to parse stream event: #{Exception.message(error)}",
           raw: data
         )}
    end
  end

  defp parse_line("", %Event{data: ""} = event), do: {[], event}
  defp parse_line("", %Event{} = event), do: {[normalize_event(event)], %Event{}}
  defp parse_line(":" <> _comment, event), do: {[], event}

  defp parse_line(line, %Event{} = event) do
    {field, value} = split_field(line)

    next =
      case field do
        "event" -> %{event | event: value}
        "data" -> %{event | data: append_data(event.data, value)}
        "id" -> %{event | id: value}
        "retry" -> %{event | retry: parse_retry(value)}
        _other -> event
      end

    {[], next}
  end

  defp split_chunk("", buffer), do: {[buffer, ""], ""}

  defp split_chunk(chunk, buffer) do
    parts =
      (buffer <> chunk)
      |> String.split(~r/\r?\n/)

    {lines, rest} = Enum.split(parts, -1)
    {lines, List.first(rest) || ""}
  end

  defp split_field(line) do
    case String.split(line, ":", parts: 2) do
      [field, " " <> value] -> {field, value}
      [field, value] -> {field, value}
      [field] -> {field, ""}
    end
  end

  defp append_data("", value), do: value
  defp append_data(data, value), do: data <> "\n" <> value

  defp parse_retry(value) do
    case Integer.parse(value) do
      {retry, ""} -> retry
      _other -> nil
    end
  end

  defp normalize_event(%Event{data: data} = event),
    do: %{event | data: String.trim_trailing(data, "\n")}

  defp extract_text(%{"choices" => choices}, :openai) when is_list(choices) do
    choices
    |> Enum.map(fn choice ->
      get_in(choice, ["delta", "content"]) ||
        get_in(choice, ["message", "content"]) ||
        Map.get(choice, "text") ||
        ""
    end)
    |> Enum.join("")
  end

  defp extract_text(%{"type" => "content_block_delta", "delta" => %{"text" => text}}, :anthropic),
    do: text

  defp extract_text(%{"content" => content}, :anthropic) when is_list(content) do
    content
    |> Enum.map(fn
      %{"text" => text} -> text
      _part -> ""
    end)
    |> Enum.join("")
  end

  defp extract_text(%{"candidates" => candidates}, :gemini) when is_list(candidates) do
    candidates
    |> Enum.flat_map(&(get_in(&1, ["content", "parts"]) || []))
    |> Enum.map(fn
      %{"text" => text} -> text
      _part -> ""
    end)
    |> Enum.join("")
  end

  defp extract_text(_payload, _protocol), do: ""
end
