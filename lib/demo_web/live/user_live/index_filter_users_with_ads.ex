defmodule DemoWeb.UserLive.IndexFilterUsersWithAds do
  require Integer
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <script async src="https://www.googletagservices.com/tag/js/gpt.js"></script>
    <form id="filters-form" phx-change="filter_change">
      <div class="filters">
        <label>
          <input type="radio" name="filter" value="none" <%= if @filter not in ~w(even odd), do: ~s( checked="checked") %>>
          Reset filter
        </label>
        <label>
          <input type="radio" name="filter" value="even" <%= if @filter == "even", do: ~s( checked="checked") %>>
          Filter results to even numbers only
        </label>
        <label>
          <input type="radio" name="filter" value="odd" <%= if @filter == "odd", do: ~s( checked="checked") %>>
          Filter results to ODD numbers only
        </label>
      </div>
    </form>

    <div id="ad-1" class="advertising" phx-update="ignore"
      data-ad-unit-path="/35096353/amptesting/image/static"></div>

    <table id="results" phx-hook="Ads">
      <tbody id="users">
        <%= for {user, index} <- @users do %>
          <%= if index == 4 do %>
          <tr id="ad-<%= index %>" style="background-color: whitesmoke;" phx-update="ignore">
            <td colspan="3">
              <span>Random number generated server-side</span>
              <%= :rand.uniform(9999) %>
              <div id="ad-2" class="advertising" data-ad-unit-path="/6355419/Travel/Europe/France/Paris"></div>
            </td>
          </tr>
          <% end %>
          <tr id="user-<%= user.id %>">
            <td><%= user.id %></td>
            <td><%= user.username %></td>
            <td><%= user.email %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end

  def handle_event("filter_change", %{"_target" => ["even"], "even" => "on"}, socket) do
    {:noreply, assign(socket, filtered: true, users: fetch_even_users())}
  end

  def handle_event("filter_change", %{"_target" => ["even"]}, socket) do
    {:noreply, assign(socket, filtered: true, users: fetch_all_users())}
  end

  def handle_event("filter_change", %{"_target" => ["filter"], "filter" => "even"}, socket) do
    {:noreply, assign(socket, filter: "even", users: fetch_even_users())}
  end

  def handle_event("filter_change", %{"_target" => ["filter"], "filter" => "odd"}, socket) do
    {:noreply, assign(socket, filter: "odd", users: fetch_odd_users())}
  end

  def handle_event("filter_change", payload, socket) do
    IO.inspect(payload, label: "filter_change")
    {:noreply, assign(socket, filtered: false, filter: nil, users: fetch_all_users())}
  end

  def mount(_session, socket) do
    {:ok, assign(socket, filtered: false, filter: nil, users: fetch_all_users())}
  end

  defp fetch_all_users() do
    Demo.Accounts.list_users(1, 20)
    |> Enum.with_index()
  end

  defp fetch_even_users() do
    Demo.Accounts.list_users(1, 20)
    |> Enum.filter(&Integer.is_even(&1.id))
    |> Enum.with_index()
  end

  defp fetch_odd_users() do
    Demo.Accounts.list_users(1, 20)
    |> Enum.filter(&Integer.is_odd(&1.id))
    |> Enum.with_index()
  end
end
