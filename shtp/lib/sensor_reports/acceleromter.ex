defmodule Accelerometer do
  alias Circuits.I2C
  import Message_Handling

  @feature_report_id 0x01
  @channel 0x02

  # Common fields
  # Sequence is incrementing count for messages sent on this channel
  # Interval 32bit microseconds
  # Batch interval defines time between sample and reporting 0 = no delay
  # Feature flags TBD
  # Change sensitivity absolute
  # Change sensitivity relative
  # Sensor specific word
  # Status accuracy two first bits 0b00=unreliable 0b10=high
  # Delay how long ago reading was taken, last 6 bits plus next byte

  @spec start(Circuits.I2C.Bus.t(), String.t(), Integer, Integer) :: Atom
  def start(i2c, address, sequence, interval) do
    opts = [
      report_interval: interval
    ]

    message =
      format_set_feature_command(@feature_report_id, opts)
      |> add_header(sequence, @channel)

    IO.inspect(message)
    I2C.write(i2c, address, message)
    # I2C.write(i2c, address, [
    #   0x15,
    #   0x00,
    #   0x02,
    #   0x00,
    #   0xFD,
    #   0x01,
    #   0x00,
    #   0x00,
    #   0x00,
    #   <<96, 234, 0, 0>>,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00,
    #   0x00
    # ])
  end

  def stop() do
  end
end
