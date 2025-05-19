# Shtp

GenServer to run an SHTP interface to a device.

## Installation

```elixir
def deps do
  {:shtp, "~> 0.1"}
end
```

# Usage

{:ok, pid} = Shtp.Shtp.start_link()
GenServer.cast(pid, :initialize)
GenServer.cast(pid, :produce_id)
GenServer.cast(pid, :initialize)
