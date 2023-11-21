defmodule Macchinette.InterruttoreTest do
  use ExUnit.Case, async: true

  alias Macchinette.Interruttore

  setup do
    %{pid: start_link_supervised!(Interruttore)}
  end

  test "flicking toggles state", %{pid: pid} do
    assert :on = Interruttore.flick(pid)
    assert :off = Interruttore.flick(pid)
    assert :on = Interruttore.flick(pid)
  end
end
