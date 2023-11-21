defmodule Macchinette.Caffe do
  @moduledoc """
  Caffè

  ```mermaid
  stateDiagram-v2
    [*] --> idle
    idle --> idle : add_credit
    idle --> idle : select_product
    idle --> dispensing : select_product
    idle --> refunding : request_refund
    idle --> [*] : power_off
    dispensing --> idle : dispensed_product
    dispensing --> [*] : power_off
    refunding --> idle : refunded_change
    refunding --> [*] : power_off
  ```
  """

  require Logger

  @typedoc "State"
  @type state :: :idle | {:dispensing, product()} | :refunding

  @typedoc "Caffè"
  @type t :: :gen_statem.server_ref()

  @typedoc "Amount"
  @type amount :: float()

  @typedoc "Product"
  @type product :: :normale | :lungo | :cappuccino | :cioccolata

  @typedoc "Data"
  @type data :: %__MODULE__{credit: amount(), products: %{product() => amount()}}
  defstruct credit: 0.0, products: %{normale: 1.0, lungo: 1.0, cappuccino: 2.0, cioccolata: 2.50}

  @doc false
  def child_spec(opts), do: %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}

  @doc "Insert coin"
  @spec add_credit(t(), amount()) :: :ok | :error
  def add_credit(t, amount), do: :gen_statem.call(t, {:add_credit, amount})

  @doc "Insert coin"
  @spec request_refund(t()) :: :ok | :error
  def request_refund(t), do: :gen_statem.call(t, :request_refund)

  @doc "Power off"
  @spec power_off(t()) :: :ok
  def power_off(t), do: :gen_statem.cast(t, :power_off)

  @doc "Select product"
  @spec select_product(t(), product()) :: :ok | :error
  def select_product(t, product), do: :gen_statem.call(t, {:select_product, product})

  @doc "Start"
  @spec start_link(Keyword.t()) :: :gen_statem.start_ret()
  def start_link(opts), do: :gen_statem.start_link(__MODULE__, [], opts)

  @doc "Stop"
  @spec stop(t()) :: :ok
  def stop(t), do: :gen_statem.stop(t)

  @behaviour :gen_statem

  @impl :gen_statem
  def callback_mode, do: [:handle_event_function, :state_enter]

  @impl :gen_statem
  def init(_opts), do: {:ok, :idle, %__MODULE__{}}

  @impl :gen_statem
  def handle_event(:enter, old_state, current_state, %__MODULE__{} = data) do
    Logger.debug("#{inspect(old_state)} => #{inspect(current_state)}: credit #{data.credit}")
    :keep_state_and_data
  end

  def handle_event({:call, from}, {:add_credit, coin}, :idle, data),
    do: {:keep_state, %{data | credit: data.credit + coin}, {:reply, from, :ok}}

  def handle_event({:call, from}, {:add_credit, _coin}, _state, _data),
    do: {:keep_state_and_data, {:reply, from, :error}}

  def handle_event({:call, from}, :request_refund, :idle, data),
    do: {:next_state, :refunding, data, [{:reply, from, :ok}, {:state_timeout, 1_000, nil}]}

  def handle_event({:call, from}, :request_refund, _state, _data),
    do: {:keep_state_and_data, {:reply, from, :error}}

  def handle_event({:call, from}, {:select_product, product}, :idle, %__MODULE__{} = data) do
    case data.products[product] do
      nil ->
        {:keep_state_and_data, {:reply, from, {:error, :unknown_product}}}

      price when data.credit < price ->
        {:keep_state_and_data, {:reply, from, {:error, :insufficient_credit}}}

      _price ->
        {
          :next_state,
          {:dispensing, product},
          data,
          [{:reply, from, :ok}, {:state_timeout, 1_000, nil}]
        }
    end
  end

  def handle_event(:state_timeout, _event, :refunding, data),
    do: {:next_state, :idle, data, {:next_event, :internal, :zero_credit}}

  def handle_event(:state_timeout, _event, {:dispensing, product}, %__MODULE__{} = data),
    do: {:next_state, :idle, %{data | credit: data.credit - data.products[product]}}

  def handle_event(:cast, :power_off, _state, _data), do: {:stop, :power_off}

  def handle_event(:internal, :zero_credit, _state, %__MODULE__{} = data),
    do: {:keep_state, %{data | credit: 0}}

  def handle_event(type, event, state, _data) do
    Logger.error("unexpected #{inspect(type)}: #{inspect(event)} in state #{inspect(state)}")
    :keep_state_and_data
  end
end
