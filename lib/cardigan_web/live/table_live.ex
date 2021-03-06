defmodule CardiganWeb.TableLive do
  use CardiganWeb, :live_view

  @impl true
  def mount(%{"table_id" => table_id} = params, _session, socket) do
    {:ok, table} = Cardigan.TableManager.lookup(table_id)
    game = Cardigan.Table.get_game(table)

    if connected?(socket), do: Cardigan.Table.subscribe(table_id)

    socket
    |> assign(:table, table)
    |> assign(:table_url, Routes.table_url(CardiganWeb.Endpoint, :show, table_id))
    |> assign(:game, game)
    |> assign(:hand_id, Map.get(params, "hand_id"))
    |> assign(:move_deck, false)
    |> assign(:page_title, game.name)
    |> (fn socket -> {:ok, socket} end).()
  end

  @impl true
  def handle_event("submit", %{"hand" => %{"id" => hand_id}}, socket) do
    {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :join, [hand_id])
    table_id = Cardigan.Table.get_id(socket.assigns.table)
    {:noreply, push_redirect(socket, to: Routes.table_path(socket, :show, table_id, hand_id))}
  end

  @impl true
  def handle_event("start", _params, socket) do
    {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :start)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "move",
        %{
          "from_is" => from_is,
          "from_id" => from_id,
          "card_id" => card_id,
          "to_is" => "play_area",
          "x" => x,
          "y" => y
        },
        socket
      ) do
    from_is = String.to_existing_atom(from_is)

    if socket.assigns.move_deck do
      {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :move, [from_is, from_id, [x, y]])
    else
      {:ok, _} =
        Cardigan.Table.modify(socket.assigns.table, :move, [from_is, from_id, card_id, [x, y]])
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "move",
        %{
          "from_is" => from_is,
          "from_id" => from_id,
          "to_is" => to_is,
          "to_id" => to_id,
          "card_id" => card_id
        },
        socket
      ) do
    from_is = String.to_existing_atom(from_is)
    to_is = String.to_existing_atom(to_is)

    if socket.assigns.move_deck do
      {:ok, _} =
        Cardigan.Table.modify(socket.assigns.table, :move, [from_is, from_id, to_is, to_id])
    else
      {:ok, _} =
        Cardigan.Table.modify(socket.assigns.table, :move, [
          from_is,
          from_id,
          card_id,
          to_is,
          to_id
        ])
    end

    {:noreply, socket}
  end

  # Block flips on hands that are not mine
  @impl true
  def handle_event(
        "key",
        %{"key" => "f", "from_is" => "hands", "from_id" => from_id},
        %{assigns: %{hand_id: hand_id}} = socket
      )
      when from_id != hand_id do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "key",
        %{
          "key" => "f",
          "from_is" => from_is,
          "from_id" => from_id,
          "card_id" => card_id
        },
        socket
      ) do
    from_is = String.to_existing_atom(from_is)
    {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :flip, [from_is, from_id, card_id])
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "key",
        %{
          "key" => "p",
          "from_is" => "decks",
          "from_id" => deck_id,
          "card_id" => card_id
        },
        socket
      ) do
    {:ok, _} =
      Cardigan.Table.modify(
        socket.assigns.table,
        :move,
        [:decks, deck_id, card_id, :hands, socket.assigns.hand_id]
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "key",
        %{
          "key" => "s",
          "from_is" => "decks",
          "from_id" => deck_id
        },
        socket
      ) do
    {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :shuffle, [:decks, deck_id])
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "key",
        %{
          "key" => "m",
          "from_is" => "decks",
          "from_id" => deck_id
        },
        socket
      ) do
    {:ok, _} =
      Cardigan.Table.modify(socket.assigns.table, :toggle_deck_display_mode, [:decks, deck_id])

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "key",
        %{
          "key" => "u",
          "from_is" => "decks",
          "from_id" => deck_id
        },
        socket
      ) do
    {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :deck_up, [:decks, deck_id])
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "key",
        %{
          "key" => "d",
          "from_is" => "decks",
          "from_id" => deck_id
        },
        socket
      ) do
    {:ok, _} = Cardigan.Table.modify(socket.assigns.table, :deck_down, [:decks, deck_id])
    {:noreply, socket}
  end

  @impl true
  def handle_event("key", _args, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("move_mode_card", _args, socket) do
    {:noreply, assign(socket, :move_deck, false)}
  end

  @impl true
  def handle_event("move_mode_deck", _args, socket) do
    {:noreply, assign(socket, :move_deck, true)}
  end

  @impl true
  def handle_info(:table_updated, socket) do
    socket = assign(socket, :game, Cardigan.Table.get_game(socket.assigns.table))
    {:noreply, socket}
  end
end
