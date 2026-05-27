defmodule Buble.HTTP do
  @moduledoc false

  @spec encode_path_segment(term()) :: String.t()
  def encode_path_segment(value) do
    value
    |> to_string()
    |> URI.encode(&URI.char_unreserved?/1)
  end

  @spec encode_model_path(term()) :: String.t()
  def encode_model_path(value) do
    value
    |> to_string()
    |> String.split("/")
    |> Enum.map(&encode_path_segment/1)
    |> Enum.join("/")
  end
end
