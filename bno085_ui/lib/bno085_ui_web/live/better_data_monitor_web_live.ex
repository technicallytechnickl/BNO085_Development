defmodule Bno085UIWeb.BetterDataMonitorWebLive do
  use Bno085UIWeb, :live_view

  import Contex
  alias Contex
  import Logger

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(:my_pubsub, "accelerometer")
    # Logger.info("I'm mounting it #{inspect(socket)}")
    {:ok,
     socket
     |> assign(:data, [])
     |> assign(:svg_str1, %{})
     |> assign(:svg_str2, %{})
     |> assign(:svg_str3, %{})}
  end

  @impl true
  def handle_info(data, socket) do
    Logger.info("I'm receiving it Contex #{inspect(data)}")
    svg_strs = create_contex_plot(data)

    socket =
      socket
      |> assign(:svg_str1, svg_strs[:x])
      |> assign(:svg_str2, svg_strs[:y])
      |> assign(:svg_str3, svg_strs[:z])

    # socket = assign(socket, :data, data)
    # socket = assign(socket, :data, data)

    # Logger.info("I'm receiving it #{inspect(socket)}")
    {:noreply, socket}
  end

  def create_contex_plot(data) do
    contex_data =
      data
      |> Enum.reduce([], fn {time, map}, acc -> [{time, map[:x]} | acc] end)

    ds = Contex.Dataset.new(contex_data, ["time", "x_acc"])

    point_plot = Contex.LinePlot.new(ds)

    plot =
      Contex.Plot.new(600, 400, point_plot)
      |> Contex.Plot.plot_options(%{
        legend_setting: :legend_right,
        y_scale:
          Contex.ContinuousLinearScale.new()
          |> Contex.ContinuousLinearScale.domain(-1.0, 1.0)
          |> Contex.Scale.set_range(-15.0, 15.0),
        custom_y_scale:
          Contex.ContinuousLinearScale.new()
          |> Contex.ContinuousLinearScale.domain(-1.0, 1.0)
          |> Contex.Scale.set_range(-15.0, 15.0)
      })
      |> Contex.Plot.titles("X Acceleration", "BNO085")

    svg1 = Contex.Plot.to_svg(plot)

    contex_data =
      data
      |> Enum.reduce([], fn {time, map}, acc -> [{time, map[:y]} | acc] end)

    ds = Contex.Dataset.new(contex_data, ["time", "y_acc"])

    point_plot = Contex.LinePlot.new(ds)

    plot =
      Contex.Plot.new(600, 400, point_plot)
      |> Contex.Plot.plot_options(%{
        legend_setting: :legend_right,
        y_scale:
          Contex.ContinuousLinearScale.new()
          |> Contex.ContinuousLinearScale.domain(-1.0, 1.0)
          |> Contex.Scale.set_range(-15.0, 15.0),
        custom_y_scale:
          Contex.ContinuousLinearScale.new()
          |> Contex.ContinuousLinearScale.domain(-1.0, 1.0)
          |> Contex.Scale.set_range(-15.0, 15.0)
      })
      |> Contex.Plot.titles("Y Acceleration", "BNO085")

    svg2 = Contex.Plot.to_svg(plot)

    contex_data =
      data
      |> Enum.reduce([], fn {time, map}, acc -> [{time, map[:z]} | acc] end)

    ds = Contex.Dataset.new(contex_data, ["time", "z_acc"])

    point_plot = Contex.LinePlot.new(ds)

    plot =
      Contex.Plot.new(600, 400, point_plot)
      |> Contex.Plot.plot_options(%{
        legend_setting: :legend_right,
        y_scale:
          Contex.ContinuousLinearScale.new()
          |> Contex.ContinuousLinearScale.domain(-1.0, 1.0)
          |> Contex.Scale.set_range(-15.0, 15.0),
        custom_y_scale:
          Contex.ContinuousLinearScale.new()
          |> Contex.ContinuousLinearScale.domain(-1.0, 1.0)
          |> Contex.Scale.set_range(-15.0, 15.0)
      })
      |> Contex.Plot.titles("Z Acceleration", "BNO085")

    svg3 = Contex.Plot.to_svg(plot)

    %{:x => svg1, :y => svg2, :z => svg3}
  end

  def render(assigns) do
    # Logger.info("I'm rendering it #{inspect(assigns)}")
    #  Logger.info("I'm rendering it again #{inspect(assigns[:data])}")

    if assigns[:svg_str1] != %{} do
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
        </head>
        <body>
          <%= @svg_str1 %>
          <%= @svg_str2 %>
          <%= @svg_str3 %>
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
