defmodule Sensors do
  alias Circuits.I2C
  import Message_Handling

  @channel 0x02

  defstruct accelerometer: 0x01,
            raw_accelerometer: 0x014,
            linear_acceleration: 0x04,
            gravity: 0x06,
            raw_gyroscope: 0x15,
            gyroscope: 0x02,
            raw_magnetometer: 0x16,
            magnetic_field: 0x03,
            rotation_vector: 0x05

  @behaviour Access

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

  @spec start(Atom, Circuits.I2C.Bus.t(), String.t(), Integer, Integer) :: Atom
  # when sensor == :accelerometer do
  def start(sensor, i2c, address, sequence, interval) do
    opts = [
      report_interval: interval
    ]

    feature_report_id = Map.get(%__MODULE__{}, sensor)

    message =
      format_set_feature_command(feature_report_id, opts)
      |> add_header(sequence, @channel)

    I2C.write(i2c, address, message)
  end

  def stop(sensor, i2c, address, sequence) do
    start(sensor, i2c, address, sequence, 0)
  end

  def parse_message(sensor, message) do
    case sensor do
      :accelerometer ->
        <<x::signed-little-integer-16, y::signed-little-integer-16, z::signed-little-integer-16,
          _trash::binary>> = message

        {x / 2 ** 8, y / 2 ** 8, z / 2 ** 8}

      :raw_accelerometer ->
        <<x::signed-little-integer-16, y::signed-little-integer-16, z::signed-little-integer-16,
          _trash::binary>> = message

        {x, y, z}

      :raw_gyroscope ->
        # timestamp not included
        <<x::signed-little-integer-16, y::signed-little-integer-16, z::signed-little-integer-16,
          temp::signed-little-integer-16, _trash::binary>> = message

        {x, y, z, temp}

      :gyroscope ->
        <<x::signed-little-integer-16, y::signed-little-integer-16, z::signed-little-integer-16,
          _trash::binary>> = message

        {x / 2 ** 9, y / 2 ** 9, z / 2 ** 9}

      :raw_magnetometer ->
        <<x::signed-little-integer-16, y::signed-little-integer-16, z::signed-little-integer-16,
          temp::signed-little-integer-16, _trash::binary>> = message

        {x, y, z}

      :magnetic_field ->
        <<x::signed-little-integer-16, y::signed-little-integer-16, z::signed-little-integer-16,
          _trash::binary>> = message

        {x / 2 ** 4, y / 2 ** 4, z / 2 ** 4}

      :rotation_vector ->
        <<i::signed-little-integer-16, j::signed-little-integer-16, k::signed-little-integer-16,
          real::signed-little-integer-16, accuracy::signed-little-integer-16,
          _trash::binary>> = message

        {i / 2 ** 14, j / 2 ** 14, k / 2 ** 14, real / 2 ** 14, accuracy / 2 ** 12}

      _ ->
        :error
    end
  end
end
