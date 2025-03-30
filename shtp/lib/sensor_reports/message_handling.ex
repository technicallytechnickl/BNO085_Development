defmodule Message_Handling do
  @format_set_feature_command_defaults %{
    feature_flags: 0x0,
    change_sensitivity: 0,
    report_interval: 1_000_000,
    batch_interval: 0,
    sensor_specific_config: [<<0>>, <<0>>, <<0>>, <<0>>]
  }

  def add_header(message, sequence, channel) do
    message_len = length(message) + 4

    <<len_lsb, len_msb>> = <<message_len::unsigned-integer-16-little>>

    header = [
      <<len_lsb>>,
      <<len_msb>>,
      <<channel>>,
      <<sequence>>
    ]

    header ++ message
  end

  def parse_dynamic_feature_report() do
  end

  def format_get_feature_request(feature_report_id) do
    report_id = 0xFE
  end

  def format_set_feature_command(feature_report_id, opts \\ []) do
    %{
      feature_flags: feature_flags,
      change_sensitivity: change_sensitivity,
      report_interval: report_interval,
      batch_interval: batch_interval,
      sensor_specific_config: sensor_specific_config
    } = Enum.into(opts, @format_set_feature_command_defaults)

    report_id = 0xFD

    <<change_sensitivity_lsb, change_sensitivity_msb>> =
      <<change_sensitivity::16-signed-little>>

    <<report_interval_lsb, report_interval_1, report_interval_2, report_interval_msb>> =
      <<report_interval::32-unsigned-little>>

    <<batch_interval_lsb, batch_interval_1, batch_interval_2, batch_interval_msb>> =
      <<batch_interval::32-unsigned-little>>

    set_feature_command =
      List.flatten([
        report_id,
        feature_report_id,
        feature_flags,
        change_sensitivity_lsb,
        change_sensitivity_msb,
        report_interval_lsb,
        report_interval_1,
        report_interval_2,
        report_interval_msb,
        batch_interval_lsb,
        batch_interval_1,
        batch_interval_2,
        batch_interval_msb,
        sensor_specific_config
      ])
      |> Enum.map(fn entry ->
        if is_bitstring(entry) do
          entry
        else
          <<entry::8>>
        end
      end)

    IO.inspect(set_feature_command, label: "command")

    set_feature_command
  end
end
