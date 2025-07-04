defmodule Bno085UIWeb.DataMonitorWebLive do
  use Bno085UIWeb, :live_view

  alias Plotex.Output.Options
  import Plotex
  import Logger

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(:my_pubsub, "accelerometer")
    # Logger.info("I'm mounting it #{inspect(socket)}")
    {:ok, socket
    |>assign(:data, [])
    |>assign(:svg_str, %{})}
  end

  @impl true
  def handle_info(data, socket) do
    Logger.info("I'm receiving it #{inspect(data)}")
    plt = create_plot(data)
    socket = assign(socket, :opts,
      %Options{
        xaxis: %Options.Axis{
          # label: %Options.Item{rotate: 35, offset: ~c"2.5em"}
          label: %Options.Item{rotate: 35}
        },
        width: 140,
        height: 105
      })
    socket = assign(socket, :plot, plt)

    svg_str =
    socket.assigns
      |> Plotex.Output.Svg.generate()
      # |> Phoenix.HTML.safe_to_string()


    socket = assign(socket, :svg_str,  svg_str)
    # socket = assign(socket, :data, data)
    # socket = assign(socket, :data, data)

    # Logger.info("I'm receiving it #{inspect(socket)}")
    {:noreply, socket}
  end

  @doc " Create Plotex Graph "
  def create_plot(data) do
    xdata =
      data
      |> Enum.reduce([], fn {time, _map}, acc -> [time | acc] end)

    ydata =
      data
      |> Enum.reduce([], fn {_time, map}, acc -> [map[:z] | acc] end)
    Logger.info("x and y data #{inspect(%{xdata: xdata, ydata: ydata})}")
    graph_data = {xdata, ydata}

    plt =
      Plotex.plot(
        [graph_data],
        xaxis: [kind: :datetime, ticks: 5, padding: 0.05]
      )

    # Logger.info("svg plotex cfg: #{inspect(plt, pretty: true)}")

    plt
  end

  def render(assigns) do

    # Logger.info("I'm rendering it #{inspect(assigns)}")
    #  Logger.info("I'm rendering it again #{inspect(assigns[:data])}")

    if assigns[:svg_str] != %{} do
      # plt = create_plot(assigns[:data])

      # # These options aren't really documented, but
      # # the plotex_test.ex contains most of the basic
      # # usages.
      # svg_str =
      #   plt
      #   |> Plotex.Output.Svg.generate()
      #   |> Phoenix.HTML.safe_to_string()

      #   #%Options{
      #   #   xaxis: %Options.Axis{
      #   #     label: %Options.Item{rotate: 35, offset: ~c"2.5em"}
      #   #   },
      #   #   width: 140,
      #   #   height: 105
      #   # }
      # assigns = assign(assigns, :svg_str, svg_str)

      ~H"""
      <html>
        <head>
          <style>
            #{Plotex.Output.Svg.default_css()}
          </style>
        </head>
        <body>
          <%= @svg_str %>
        </body>
      </html>
      """
    else
       # assigns = [svg_str: %{}]

      ~H"""
      <html>
        <head>
        </head>
        <body>
        "Nothing Yet"
        </body>
      </html>
      """
    end
  end
end
