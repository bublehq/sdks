defmodule Buble.Types do
  @moduledoc """
  Shared public types used by the Buble Elixir SDK.

  The API is configuration-driven, so responses are returned as decoded JSON maps.
  These types document the stable outer shapes without discarding newly introduced
  fields returned by Buble.
  """

  @type envelope(data) :: %{required(:data) => data} | %{optional(String.t()) => data}
  @type json ::
          nil | boolean() | number() | String.t() | [json()] | %{optional(String.t()) => json()}
  @type task_status :: String.t()
  @type generation_task :: map()
  @type app_generation_task :: map()
  @type chat_request :: map()
  @type chat_response :: map()
end
