defmodule Macchinette.TornelloTest do
  use ExUnit.Case, async: true

  alias Macchinette.Tornello

  setup do
    %{pid: start_link_supervised!(Tornello)}
  end

  test "locked on push handle", %{pid: pid} do
    assert :locked = Tornello.push_handle(pid)
  end

  test "unlocked on insert coin", %{pid: pid} do
    assert :ok = Tornello.insert_coin(pid)
    assert :ok = Tornello.insert_coin(pid)
  end

  test "locked after push handle", %{pid: pid} do
    assert :ok = Tornello.insert_coin(pid)
    assert :ok = Tornello.push_handle(pid)
    assert :ok = Tornello.insert_coin(pid)
    assert :ok = Tornello.push_handle(pid)
    assert :locked = Tornello.push_handle(pid)
  end
end
