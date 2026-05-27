defmodule Buble.Generations do
  @moduledoc """
  Direct asynchronous image, video, and audio generation methods.

  Generation requests use Buble's flat public API shape. Put model-specific
  controls at the request root and discover supported names from media model
  discovery.
  """

  alias Buble.Client
  alias Buble.Error

  @forbidden_fields MapSet.new(~w[
    input
    options
    scene
    sub_mode_id
    subModeId
    provider
    mediaType
    media_type
    images
    image_input
    video_input
    audio_input
  ])
  @terminal_statuses MapSet.new(~w[success failed canceled])

  @spec create(Client.t(), keyword() | map()) :: {:ok, map()} | {:error, Error.t()}
  def create(%Client{} = client, attrs) do
    with {:ok, body} <- generation_body(attrs) do
      Client.request(client, :post, "/api/v1/generations", json: body)
    end
  end

  @spec create!(Client.t(), keyword() | map()) :: map()
  def create!(%Client{} = client, attrs), do: Buble.unwrap!(create(client, attrs))

  @spec retrieve(Client.t(), String.t()) :: {:ok, map()} | {:error, Error.t()}
  def retrieve(%Client{} = client, id) do
    Client.request(client, :get, "/api/v1/generations/#{Buble.HTTP.encode_path_segment(id)}")
  end

  @spec retrieve!(Client.t(), String.t()) :: map()
  def retrieve!(%Client{} = client, id), do: Buble.unwrap!(retrieve(client, id))

  @spec wait(Client.t(), String.t(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def wait(%Client{} = client, id, opts \\ []) do
    interval = Keyword.get(opts, :interval, 2_000)
    timeout = Keyword.get(opts, :timeout, 600_000)
    throw_on_failed = Keyword.get(opts, :throw_on_failed, true)
    throw_on_canceled = Keyword.get(opts, :throw_on_canceled, true)
    deadline = System.monotonic_time(:millisecond) + timeout

    do_wait(client, id, interval, deadline, timeout, throw_on_failed, throw_on_canceled)
  end

  @spec wait!(Client.t(), String.t(), keyword()) :: map()
  def wait!(%Client{} = client, id, opts \\ []), do: Buble.unwrap!(wait(client, id, opts))

  @doc false
  def generation_body(attrs) do
    {params, attrs} =
      attrs
      |> Buble.normalize_params()
      |> Map.pop("params", %{})

    body =
      attrs
      |> Map.merge(Buble.normalize_params(params || %{}))
      |> Buble.compact_params()

    case Enum.find(Map.keys(body), &MapSet.member?(@forbidden_fields, &1)) do
      nil ->
        {:ok, body}

      field ->
        {:error,
         Error.new(:unsupported_generation_field, "Unsupported generation field: #{field}",
           details: field
         )}
    end
  end

  defp do_wait(client, id, interval, deadline, timeout, throw_on_failed, throw_on_canceled) do
    case retrieve(client, id) do
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
               "Generation #{id} did not finish within #{timeout} milliseconds.",
               details: %{timeout: timeout}
             )}
          else
            Process.sleep(interval)
            do_wait(client, id, interval, deadline, timeout, throw_on_failed, throw_on_canceled)
          end
        end

      {:error, error} ->
        {:error, error}
    end
  end

  defp terminal_result(_envelope, task, "failed", _id, true, _throw_on_canceled) do
    message = get_in(task, ["error", "message"]) || "Generation failed."
    {:error, Error.new(:generation_failed, message, details: task, raw: task)}
  end

  defp terminal_result(_envelope, task, "canceled", id, _throw_on_failed, true) do
    {:error,
     Error.new(:generation_canceled, "Generation #{id} was canceled.", details: task, raw: task)}
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
