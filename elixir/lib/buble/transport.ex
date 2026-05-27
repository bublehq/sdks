defmodule Buble.Transport do
  @moduledoc """
  Behaviour for Buble HTTP transports.

  Applications normally use the default `Buble.Transport.Req` transport. Tests can
  inject a small module implementing this behaviour through `Buble.Client.new/1`.
  """

  alias Buble.Client
  alias Buble.Error

  @callback request(Client.t(), atom(), String.t(), keyword()) ::
              {:ok, term()} | {:error, Error.t()}
  @callback stream(Client.t(), atom(), String.t(), keyword()) ::
              {:ok, Enumerable.t()} | {:error, Error.t()}
end
