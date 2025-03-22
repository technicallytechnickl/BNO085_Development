defmodule Bno085 do
  @moduledoc File.read!("README.md")
             |> String.split("# Usage")
             |> Enum.fetch!(1)

  use GenServer

  require Logger

  alias Circuits.I2C

  def start_link(opts \\ []) do
    :world
  end
end
