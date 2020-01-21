defmodule DemoWeb.ScheduleLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias DemoWeb.Router.Helpers, as: Routes

  @available_floors ["1", "2", "3"]

  @available_rooms %{
    "1" => ["A", "B", "C"],
    "2" => ["D", "E", "F"],
    "3" => ["G", "H", "I"]
  }

  @available_times %{
    "1A" => ["8:00 AM", "9:00 AM", "10:00 AM"],
    "1B" => ["11:00 AM", "12:00 PM", "1:00 PM"],
    "1C" => ["2:00 PM", "3:00 PM", "4:00 PM"],
    "2D" => ["5:00 PM", "6:00 PM", "7:00 PM"],
    "2E" => ["8:00 PM", "9:00 PM", "10:00 PM"],
    "2F" => ["11:00 PM", "12:00 AM", "1:00 AM"],
    "3G" => ["2:00 AM", "3:00 PM", "4:00 AM"],
    "3H" => ["5:00 PM", "6:00 AM", "7:00 AM"],
    "3I" => ["9:00 AM", "10:00 AM", "11:00 AM"]
  }

  @impl true
  def mount(_, socket) do
    {:ok, do_pristine(socket)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <p>This is an example of a group of form inputs connected in a tree structure.</p>
    <form action="" phx-change="form_changed" phx-submit="form_submitted" <%= if @booked, do: ~s(disabled) %>>
      <select name="floor" required>
        <option value=""<%= if is_nil(@selected_floor), do: ~s( selected) %>>Floor</option>
      <%= for floor <- @floors do %>
        <option value="<%= floor %>"<%= if floor == @selected_floor, do: ~s( selected) %>>Floor <%= floor %></option>
      <% end %>
      </select>

      <select name="room" required>
        <option value=""<%= if is_nil(@selected_room), do: ~s( selected) %>>Room</option>
      <%= for room <- @rooms do %>
        <option value="<%= room %>"<%= if room == @selected_room, do: ~s( selected) %>>Room <%= room %></option>
      <% end %>
      </select>

      <select name="time" required>
        <option value=""<%= if is_nil(@selected_time), do: ~s( selected) %>>Time</option>
      <%= for time <- @times do %>
        <option value="<%= time %>"<%= if time == @selected_time, do: ~s( selected) %>><%= time %></option>
      <% end %>
      </select>

      <input type="submit" value="Book Room" />
    </form>

    <%= if @booked do %>
      <h2>You're all booked!</h2>
      <dl>
        <dt>Time</dt>
        <dd><%= @selected_time %></dd>
        <dt>Floor</dt>
        <dd><%= @selected_floor %></dd>
        <dt>Room</dt>
        <dd><%= @selected_room %></dd>
      </dl>
      <input type="button" phx-click="booking_reset" value="Book Again" />
    <% end %>
    """
  end

  @impl true
  def handle_event("form_changed", %{"_target" => ["floor"], "floor" => ""}, socket) do
    # Full reset
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__))}
  end

  def handle_event("form_changed", %{"_target" => ["floor"]} = params, socket) do
    IO.inspect(params, label: "FLOOR changed")

    # The floor is the root of the tree. When it changes,
    # we only send the floor in the query string so the
    # `room` and `time` values will be reset.
    %{"floor" => floor} = params
    new_path = Routes.live_path(socket, __MODULE__, floor: floor)

    {:noreply, live_redirect(socket, to: new_path)}
  end

  def handle_event("form_changed", %{"_target" => ["room"]} = params, socket) do
    IO.inspect(params, label: "ROOM changed")

    # The room is a branch of the tree. When it changes,
    # we only send the floor and the room in the query
    # string so the `time` values will be reset.
    query = Map.take(params, ~w(floor room))
    new_path = Routes.live_path(socket, __MODULE__, query)

    {:noreply, live_redirect(socket, to: new_path)}
  end

  def handle_event("form_changed", %{"_target" => ["time"]} = params, socket) do
    IO.inspect(params, label: "TIME changed")

    # The time is a leaf of the tree. When it changes,
    # we send all the form params.
    query = Map.take(params, ~w(floor room time))
    new_path = Routes.live_path(socket, __MODULE__, query)

    {:noreply, live_redirect(socket, to: new_path)}
  end

  def handle_event("form_submitted", _params, socket) do
    {:noreply, assign(socket, booked: true)}
  end

  def handle_event("booking_reset", _, socket) do
    # Full reset
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, __MODULE__))}
  end

  @impl true
  def handle_params(%{"floor" => selected_floor} = params, _uri, socket) do
    IO.inspect(params, label: "handle_params/3")
    selected_room = Map.get(params, "room")
    selected_time = Map.get(params, "time")

    available_rooms = Map.get(@available_rooms, selected_floor, [])

    if not is_nil(selected_room) and selected_room not in available_rooms do
      raise "Invalid room selected for Floor #{selected_floor}, got: #{selected_room}"
    end

    room_to_floor = selected_floor <> (selected_room || "")
    IO.inspect(room_to_floor, label: "Floor/Room")
    available_times = Map.get(@available_times, room_to_floor, [])

    if not is_nil(selected_time) and selected_time not in available_times do
      raise "Invalid time selected for Room #{room_to_floor}, got: #{selected_time}"
    end

    {:noreply,
     assign(socket,
       rooms: available_rooms,
       times: available_times,
       selected_floor: selected_floor,
       selected_room: selected_room,
       selected_time: selected_time
     )}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, do_pristine(socket)}
  end

  defp do_pristine(socket) do
    assign(socket,
      floors: @available_floors,
      rooms: [],
      times: [],
      selected_floor: nil,
      selected_room: nil,
      selected_time: nil,
      booked: false
    )
  end
end
