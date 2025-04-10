defmodule Shtp.Shtp do
  @moduledoc File.read!("README.md")
             |> String.split("# Usage")
             |> Enum.fetch!(1)

  use GenServer

  import Bitwise

  alias Circuits.I2C
  alias Circuits.GPIO

  # TODO: Generalize to not just BNO08X

  @serial_cmd true
  @max_buff_length 32
  @requestbytes 4

  @header_length 4

  # Control Channel Write
  @report_command_request 0xF2
  @report_frs_read_request 0xF4
  @report_frs_write_response 0xF5
  @report_frs_write_data 0xF6
  @report_frs_write_request 0xF7
  @report_product_id_request 0xF9
  @report_get_feature_response 0xFC
  @report_set_feature_command 0xFD
  @report_get_feature_request 0xFE

  # Control Channel Read
  @report_command_response 0xF1
  @report_frs_read_response 0xF3
  @report_product_id_response 0xF8

  # Wakeup/Normal Channel Read
  @report_timestamp_rebase 0xFA
  @report_base_timestamp 0xFB
  @report_accelerometer 0x01
  @report_gyroscope 0x02
  @report_magnetic_field 0x03
  @report_linear_acceleration 0x04
  @report_rotation_vector 0x05
  @report_gravity 0x06
  # @report_game_rotation_vector 0x08
  # @report_geomagnetic_rotation_vector 0x09
  # @report_gyro_integrated_rotation_vector 0x2A
  # @report_tap_detector 0x10
  # @report_step_counter 0x11
  # @report_stability_classifier 0x13
  @report_raw_accelerometer 0x14
  @report_raw_gyroscope 0x15
  @report_raw_magnetometer 0x16
  # @report_personal_activity_classifier 0x1E
  # @report_ar_vr_stabilized_rotation_vector 0x28

  # BNO8X Specific Channels
  # May need to move this to BNO086
  @channel_device <<0>>
  @channel_executable <<1>>
  @channel_control <<2>>
  @channel_sensor_reports <<3>>
  @channel_wake_reports <<4>>
  @channel_gyro_rot_vec <<5>>

  # Defaults for rPi zero 2 and BNO086
  @default_i2c_address 0x4B
  @default_i2c_bus_name "i2c-1"
  @default_interrupt_gpio "GPIO4"

  defstruct i2c: @default_i2c_bus_name,
            address: 0x00,
            shtp_data_length: 128,
            sequence: [0, 0, 0, 0, 0, 0],
            gpio_pin: @default_interrupt_gpio,
            accelerometer: nil,
            raw_accelerometer: nil,
            linear_acceleration: nil,
            gravity: nil,
            raw_gyroscope: nil,
            gyroscope: nil,
            raw_magnetometer: nil,
            magnetic_field: nil,
            rotation_vector: nil

  def start_link(name \\ "generic", opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: :"__MODULE__:#{name}")
  end

  @impl GenServer
  def init(opts) do
    bus_name = opts[:bus_name] || @default_i2c_bus_name
    address = opts[:address] || @default_i2c_address
    gpio_pin = opts[:gpio_pin] || @default_interrupt_gpio

    state = %__MODULE__{}

    {:ok, i2c} = I2C.open(bus_name)

    {:ok, %{state | i2c: i2c, address: address, gpio_pin: gpio_pin}, {:continue, :startup}}
  end

  @impl GenServer
  def handle_continue(
        :startup,
        %{i2c: i2c, address: address, sequence: sequence, gpio_pin: gpio_pin} = state
      ) do
    reset_device(i2c, address)

    {:ok, gpio} = GPIO.open(gpio_pin, :input)
    GPIO.set_interrupts(gpio, :falling)

    # Where should sequence counting be handled? ETS?

    data_to_write =
      produce_id_request(Enum.at(sequence, 2))
      |> Enum.map(fn x -> if not is_binary(x), do: <<x::8-unsigned-little-integer>>, else: x end)

    I2C.write(i2c, address, data_to_write)

    # test removing this
    Process.sleep(100)

    {:ok,
     <<len_lsb::8, cont_bit::1, len_msb::7, chan::8, seq::8, report_id::8, reset_cause::8,
       sw_ver_maj::8, sw_ver_min::8, rest::binary>>} = I2C.read(i2c, address, 20)

    <<message_length::unsigned-little-16>> = <<len_lsb, len_msb>>

    IO.inspect({message_length, seq, report_id}, label: "length, seq, report-id: ")

    # sequence = List.replace_at(sequence, 2, Enum.at(sequence, 2) + 1))
    #
    Process.sleep(100)

    {:noreply, %{state | sequence: sequence, gpio_pin: gpio}}
  end

  @impl GenServer
  def handle_info(
        {:circuits_gpio, pin, timestamp, value},
        %{i2c: i2c, address: address, sequence: sequence, gpio_pin: gpio} = state
      ) do
    with {:ok, data} <- I2C.read(i2c, address, 255) do
      <<len_lsb::8, cont_bit::1, len_msb::7, chan::8, seq::8, message::binary>> = data

      <<timestamp::binary-5, id::8, sequence::8, status::2, delay::unsigned-little-14,
        measurements::binary>> = message

      # If cont bit 1, move on we only care about the first entry, if channel != sensor report, not a measurement
      cond do
        cont_bit == 1 or chan != 3 ->
          IO.inspect(chan, label: "Pin Not a good message")
          IO.inspect(message)
          {:noreply, state}

        chan == 3 and id == @report_accelerometer ->
          {x, y, z} = Sensors.parse_message(:accelerometer, measurements)
          state = %{state | accelerometer: {x, y, z}}

          IO.inspect(
            {x, y, z, (x ** 2 + y ** 2 + z ** 2) ** 0.5, status},
            label: "Acceleration"
          )

        chan == 3 and id == @report_raw_accelerometer ->
          {x, y, z} = Sensors.parse_message(:raw_accelerometer, measurements)
          state = %{state | raw_accelerometer: {x, y, z}}

          IO.inspect(
            {x, y, z, status},
            label: "Raw Acceleration"
          )

        chan == 3 and id == @report_linear_acceleration ->
          {x, y, z} = Sensors.parse_message(:accelerometer, measurements)
          state = %{state | linear_acceleration: {x, y, z}}

          IO.inspect(
            {x, y, z, status},
            label: "Linear Acceleration"
          )

        chan == 3 and id == @report_gravity ->
          {x, y, z} = Sensors.parse_message(:accelerometer, measurements)
          state = %{state | gravity: {x, y, z}}

          IO.inspect(
            {x, y, z, status},
            label: "Gravity"
          )

        chan == 3 and id == @report_raw_gyroscope ->
          {x, y, z, temp} = Sensors.parse_message(:raw_gyroscope, measurements)
          state = %{state | raw_gyroscope: {x, y, z, temp}}

          IO.inspect(
            {x, y, z, status, temp},
            label: "Raw Gyroscope"
          )

        chan == 3 and id == @report_gyroscope ->
          {x, y, z} = Sensors.parse_message(:gyroscope, measurements)
          state = %{state | gyroscope: {x, y, z}}

          IO.inspect(
            {x, y, z, status},
            label: "Gyroscope"
          )

        ## skipped uncalibrated gyroscope
        chan == 3 and id == @report_raw_magnetometer ->
          {x, y, z} = Sensors.parse_message(:raw_magnetometer, measurements)
          state = %{state | raw_magnetometer: {x, y, z}}

          IO.inspect(
            {x, y, z, status},
            label: "Raw Magnet"
          )

        chan == 3 and id == @report_magnetic_field ->
          {x, y, z} = Sensors.parse_message(:magnetic_field, measurements)
          state = %{state | magnetic_field: {x, y, z}}

          IO.inspect(
            {x, y, z, status},
            label: "Magnetic Field"
          )

        chan == 3 and id == @report_rotation_vector ->
          {i, j, k, real, accuracy} = Sensors.parse_message(:rotation_vector, measurements)
          state = %{state | rotation_vector: {i, j, k, real, accuracy}}

          IO.inspect(
            {i, j, k, real, accuracy, status},
            label: "Rotation Vector"
          )

        len_lsb == 0 and len_msb == 0 ->
          IO.inspect("zero length")

        true ->
          IO.inspect(message, label: "Something Else")
      end

      {:noreply, state}
    else
      # If read errors out, try again later
      _ -> {:noreply, state}
    end
  end

  @impl GenServer
  def handle_cast(
        {:start, sensor, freq},
        %{i2c: i2c, address: address, sequence: sequence, gpio_pin: gpio} = state
      ) do
    # start accelerometer reporting
    Sensors.start(sensor, i2c, address, Enum.at(sequence, 2), freq)
    {:noreply, %{state | sequence: List.replace_at(sequence, 2, Enum.at(sequence, 2) + 1)}}
  end

  # @impl GenServer
  # def handle_info(:reader, %{i2c: i2c, address: address, sequence: sequence} = state) do
  #   with {:ok, data} <- I2C.read(i2c, address, 255) do
  #     <<len_lsb::8, cont_bit::1, len_msb::7, chan::8, seq::8, message::binary>> = data

  #     # If cont bit 1, move on we only care about the first entry, if channel != sensor report, not a measurement
  #     if cont_bit == 1 or chan != 3 do
  #       IO.inspect(chan, label: "Not a good message")
  #       IO.inspect(message)
  #       Process.send_after(self(), :reader, 100)
  #       {:noreply, state}
  #     else
  #       IO.inspect("Good message")
  #       <<timestamp::binary-5, measurements::binary>> = message

  #       <<id::8, sequence::8, status::2, delay::unsigned-little-14,
  #         raw_x::signed-little-integer-16, raw_y::signed-little-integer-16,
  #         raw_z::signed-little-integer-16, trash::binary>> = measurements

  #       IO.inspect({raw_x / 256, raw_y / 256, raw_z / 256, label: "acceleration measurements"})

  #       Process.send_after(self(), :reader, 100)
  #       {:noreply, state}
  #     end
  #   else
  #     # If read errors out, try again later
  #     _ ->
  #       Process.send_after(self(), :reader, 100)
  #       {:noreply, state}
  #   end
  # end

  def reset_device(i2c, address) do
    I2C.write(i2c, address, [<<5>>, <<0>>, <<1>>, <<0>>, <<1>>])

    read_to_zero(i2c, address)

    :ok
  end

  def read_to_zero(i2c, address) do
    Process.sleep(200)
    message = I2C.read(i2c, address, 20)

    case message do
      {:ok, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>} ->
        IO.inspect("Done Resetting")
        :ok

      {:ok, response} ->
        IO.inspect(response, label: "resetting: ")
        read_to_zero(i2c, address)

      {:error, response} ->
        IO.inspect(response, label: "resetting: ")
        :error
    end
  end

  def produce_id_request(sequence_number) do
    data = [@report_product_id_request, 0]

    send_packet(@channel_control, data, sequence_number)
  end

  @spec send_packet(integer(), list(), integer()) :: boolean()
  def send_packet(channel_number, data, sequence_number) do
    # Data plus header
    packet_length = length(data) + 4

    # Different sequence number series for each channel
    data_to_send = [
      packet_length &&& 0xFF,
      packet_length >>> 8,
      channel_number,
      sequence_number | data
    ]

    data_to_send
  end
end
