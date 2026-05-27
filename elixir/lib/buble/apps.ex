defmodule Buble.Apps do
  @moduledoc """
  Preconfigured Buble app workflow methods.
  """

  alias Buble.Client
  alias Buble.Error

  @spec list(Client.t()) :: {:ok, map()} | {:error, Error.t()}
  def list(%Client{} = client), do: Client.request(client, :get, "/api/v1/apps")

  @spec list!(Client.t()) :: map()
  def list!(%Client{} = client), do: Buble.unwrap!(list(client))

  @spec retrieve(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def retrieve(%Client{} = client, app_id) do
    Client.request(client, :get, "/api/v1/apps/#{Buble.HTTP.encode_path_segment(app_id)}")
  end

  @spec retrieve!(Client.t(), String.t()) :: map()
  def retrieve!(%Client{} = client, app_id), do: Buble.unwrap!(retrieve(client, app_id))
end

defmodule Buble.Apps.Generations do
  @moduledoc """
  App generation methods.
  """

  alias Buble.Client
  alias Buble.Error

  @terminal_statuses MapSet.new(~w[success failed canceled])

  @spec create(Client.t(), String.t(), keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def create(%Client{} = client, app_id, params \\ %{}) do
    Client.request(
      client,
      :post,
      "/api/v1/apps/#{Buble.HTTP.encode_path_segment(app_id)}/generations",
      json: Buble.normalize_params(params)
    )
  end

  @spec create!(Client.t(), String.t(), keyword() | map()) :: map()
  def create!(%Client{} = client, app_id, params \\ %{}),
    do: Buble.unwrap!(create(client, app_id, params))

  @spec retrieve(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def retrieve(%Client{} = client, app_id, id) do
    Client.request(
      client,
      :get,
      "/api/v1/apps/#{Buble.HTTP.encode_path_segment(app_id)}/generations/#{Buble.HTTP.encode_path_segment(id)}"
    )
  end

  @spec retrieve!(Client.t(), String.t(), String.t()) :: map()
  def retrieve!(%Client{} = client, app_id, id), do: Buble.unwrap!(retrieve(client, app_id, id))

  @spec wait(Client.t(), String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def wait(%Client{} = client, app_id, id, opts \\ []) do
    interval = Keyword.get(opts, :interval, 2_000)
    timeout = Keyword.get(opts, :timeout, 600_000)
    throw_on_failed = Keyword.get(opts, :throw_on_failed, true)
    throw_on_canceled = Keyword.get(opts, :throw_on_canceled, true)
    deadline = System.monotonic_time(:millisecond) + timeout

    do_wait(client, app_id, id, interval, deadline, timeout, throw_on_failed, throw_on_canceled)
  end

  @spec wait!(Client.t(), String.t(), String.t(), keyword()) :: map()
  def wait!(%Client{} = client, app_id, id, opts \\ []),
    do: Buble.unwrap!(wait(client, app_id, id, opts))

  defp do_wait(
         client,
         app_id,
         id,
         interval,
         deadline,
         timeout,
         throw_on_failed,
         throw_on_canceled
       ) do
    case retrieve(client, app_id, id) do
      {:ok, envelope} ->
        task = response_data(envelope)
        status = task_status(task)

        if MapSet.member?(@terminal_statuses, status) do
          terminal_result(envelope, task, status, id, throw_on_failed, throw_on_canceled)
        else
          if System.monotonic_time(:millisecond) >= deadline do
            {:error,
             Error.new(
               :timeout,
               "App generation #{id} did not finish within #{timeout} milliseconds.",
               details: %{timeout: timeout}
             )}
          else
            Process.sleep(interval)

            do_wait(
              client,
              app_id,
              id,
              interval,
              deadline,
              timeout,
              throw_on_failed,
              throw_on_canceled
            )
          end
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp terminal_result(_envelope, task, "failed", _id, true, _throw_on_canceled) do
    message = get_in(task, ["error", "message"]) || "App generation failed."
    {:error, Error.new(:app_generation_failed, message, details: task, raw: task)}
  end

  defp terminal_result(_envelope, task, "canceled", id, _throw_on_failed, true) do
    {:error,
     Error.new(:app_generation_canceled, "App generation #{id} was canceled.",
       details: task,
       raw: task
     )}
  end

  defp terminal_result(envelope, _task, _status, _id, _throw_on_failed, _throw_on_canceled),
    do: {:ok, envelope}

  defp response_data(%{"data" => data}), do: data
  defp response_data(%{data: data}), do: data
  defp response_data(data), do: data

  defp task_status(%{"status" => status}), do: status
  defp task_status(%{status: status}), do: to_string(status)
  defp task_status(_task), do: nil
end
