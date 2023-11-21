defmodule Macchinette.Interruttore do
  @moduledoc """
  Interruttore

  ```mermaid
  stateDiagram-v2
    direction LR
    [*] --> off
    off --> on : flick
    on --> off : flick
  ```
  """

  require Logger

  @typedoc "State"
  @type state :: :on | :off

  @typedoc "Interruttore"
  @type t :: :gen_statem.server_ref()

  @doc false
  def child_spec(opts), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}

  @doc "Start"
  @spec start_link(Keyword.t()) :: :gen_statem.start_ret()
  def start_link(opts), do: :gen_statem.start_link(__MODULE__, [], opts)

  @doc "Stop"
  @spec stop(t()) :: :ok
  def stop(t), do: :gen_statem.stop(t)

  @doc "Flick switch"
  @spec flick(t()) :: state()
  def flick(t), do: :gen_statem.call(t, :flick)

  @behaviour :gen_statem

  @impl :gen_statem
  def callback_mode, do: [:state_functions]

  @impl :gen_statem
  def init(_args), do: {:ok, :off, nil}

  @doc false
  def on({:call, from}, :flick, data), do: {:next_state, :off, data, {:reply, from, :off}}

  @doc false
  def off({:call, from}, :flick, data), do: {:next_state, :on, data, {:reply, from, :on}}
end
