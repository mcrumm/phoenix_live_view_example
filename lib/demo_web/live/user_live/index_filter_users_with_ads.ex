defmodule DemoWeb.UserLive.IndexFilterUsersWithAds do
  require Integer
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <script async src="https://www.googletagservices.com/tag/js/gpt.js"></script>
    <form id="filters-form" phx-change="filter_change">
      <div class="filters">
        <label>
          <input type="checkbox" id="even" name="even">
          Filter results to even numbers only
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
    {:noreply, assign(socket, users: fetch_even_users())}
  end

  def handle_event("filter_change", %{"_target" => ["odd"], "odd" => "on"}, socket) do
    {:noreply, assign(socket, users: fetch_odd_users())}
  end

  def handle_event("filter_change", _payload, socket) do
    all_users = fetch_all_users()
    {:noreply, assign(socket, users: all_users)}
  end

  def mount(_session, socket) do
    {:ok, assign(socket, users: fetch_all_users())}
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
