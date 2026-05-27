defmodule Buble.Error do
  @moduledoc """
  Error returned by the Buble SDK.

  Non-bang functions return `{:error, %Buble.Error{}}`. Bang functions raise the
  same exception struct.
  """

  defexception [:type, :message, :status, :code, :details, :raw]

  @type t :: %__MODULE__{
          type:
            :api
            | :timeout
            | :missing_api_key
            | :unsupported_generation_field
            | :generation_failed
            | :generation_canceled
            | :app_generation_failed
            | :app_generation_canceled
            | :stream,
          message: String.t(),
          status: pos_integer() | nil,
          code: String.t() | nil,
          details: term(),
          raw: term()
        }

  @impl true
  def exception(opts) do
    type = Keyword.fetch!(opts, :type)
    message = Keyword.fetch!(opts, :message)

    %__MODULE__{
      type: type,
      message: message,
      status: Keyword.get(opts, :status),
      code: Keyword.get(opts, :code),
      details: Keyword.get(opts, :details),
      raw: Keyword.get(opts, :raw)
    }
  end

  @doc false
  @spec new(atom(), String.t(), keyword()) :: t()
  def new(type, message, opts \\ []) do
    exception(Keyword.merge(opts, type: type, message: message))
  end
end
