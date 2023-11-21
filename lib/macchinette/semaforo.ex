defmodule Macchinette.Semaforo do
  @moduledoc """
  Semaforo

  ```mermaid
  stateDiagram-v2
    [*] --> green
    green --> yellow : timeout
    yellow --> red : timeout
    red --> green : timeout
  ```
  """

  require Logger

  @typedoc "State"
  @type state :: :green | :red | :yellow

  @typedoc "Semaforo"
  @type t :: :gen_statem.server_ref()

  @doc false
  def child_spec(opts), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}

  @doc "Start"
  @spec start_link(Keyword.t()) :: :gen_statem.start_ret()
  def start_link(opts), do: :gen_statem.start_link(__MODULE__, [], opts)

  @doc "Stop"
  @spec stop(t()) :: :ok
  def stop(t), do: :gen_statem.stop(t)

  @behaviour :gen_statem

  @impl :gen_statem
  def callback_mode, do: [:state_functions]

  @impl :gen_statem
  def init(_args), do: {:ok, :green, nil, {:state_timeout, 3_000, nil}}

  @doc false
  def green(:state_timeout, _event, data),
    do: {:next_state, :yellow, data, {:state_timeout, 1_000, nil}}

  @doc false
  def yellow(:state_timeout, _event, data),
    do: {:next_state, :red, data, {:state_timeout, 3_000, nil}}

  @doc false
  def red(:state_timeout, _event, data),
    do: {:next_state, :green, data, {:state_timeout, 3_000, nil}}
end
