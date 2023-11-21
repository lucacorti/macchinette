defmodule Macchinette.Tornello do
  @moduledoc """
  Tornello

  ```mermaid
  stateDiagram-v2
    direction LR
    [*] --> locked
    locked --> unlocked : insert_coin
    locked --> locked : push_handle
    unlocked --> unlocked : insert_coin
    unlocked --> locked : push_handle
  ```
  """

  require Logger

  @typedoc "State"
  @type state :: :locked | :unlocked

  @typedoc "Tornello"
  @type t :: :gen_statem.server_ref()

  @doc false
  def child_spec(opts), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}

  @doc "Start"
  @spec start_link(Keyword.t()) :: :gen_statem.start_ret()
  def start_link(opts), do: :gen_statem.start_link(__MODULE__, [], opts)

  @doc "Insert coin"
  @spec insert_coin(t()) :: :ok
  def insert_coin(t), do: :gen_statem.call(t, :insert_coin)

  @doc "Push handle"
  @spec push_handle(t()) :: :ok | :locked
  def push_handle(t), do: :gen_statem.call(t, :push_handle)

  @doc "Stop"
  @spec stop(t()) :: :ok
  def stop(t), do: :gen_statem.stop(t)

  @behaviour :gen_statem

  @impl :gen_statem
  def callback_mode, do: [:state_functions]

  @impl :gen_statem
  def init(_args), do: {:ok, :locked, 0}

  @doc false
  def locked({:call, from}, :push_handle, _coins),
    do: {:keep_state_and_data, {:reply, from, :locked}}

  @doc false
  def locked({:call, from}, :insert_coin, coins),
    do: {:next_state, :unlocked, coins + 1, {:reply, from, :ok}}

  @doc false
  def unlocked({:call, from}, :insert_coin, coins),
    do: {:keep_state, coins + 1, {:reply, from, :ok}}

  @doc false
  def unlocked({:call, from}, :push_handle, coins),
    do: {:next_state, :locked, coins, {:reply, from, :ok}}
end
