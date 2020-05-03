defmodule Gamixir.Game do
  alias Gamixir.{Deck, Card}

  @behaviour Access

  defstruct name: nil,
            min_num_of_players: 1,
            max_num_of_players: 20,
            decks: [],
            hands: [],
            started: false

  # Implementing the Access behaviour by delegating to Map
  defdelegate fetch(data, key), to: Map
  defdelegate get_and_update(data, key, fun), to: Map
  defdelegate pop(data, key), to: Map

  @doc """
  Get a hand by name.
  """
  def get_hand(game, name) do
    Enum.find(game.hands, &(Deck.get_id(&1) == name))
  end

  @doc """
  Get a deck by ID.
  """
  def get_deck(game, deck_id) do
    Enum.find(game.decks, &(Deck.get_id(&1) == deck_id))
  end

  @doc """
  TODO
  """
  def startable?(game) do
    n = length(game.hands)
    not game.started and n >= game.min_num_of_players and n <= game.max_num_of_players
  end

  @doc """
  Join a yet to start game, by hand name.
  """
  def join(%__MODULE__{started: false} = game, hand_id) do
    if length(game.hands) < game.max_num_of_players do
      hand = %Deck{id: hand_id}
      {:ok, update_in(game.hands, &[hand | &1])}
    else
      {:error, :table_full}
    end
  end

  @doc """
  Start the game.
  """
  def start(game) do
    {:ok, Map.put(game, :started, true)}
  end

  @doc """
  Move a card from a deck/hand to new position, either to a new deck or snapped to existing deck.
  """
  def move(game, from_is, from_id, card_id, pos) do
    case pop_from(game, from_is, from_id, card_id) do
      {:error, reason} ->
        {:error, reason}

      {:ok, card, game} ->
        game
        |> place(card, pos)
        |> drop_empty_decks()
        |> (fn x -> {:ok, x} end).()
    end
  end

  def move(game, from_is, from_id, card_id, to_is, to_id) do
    case pop_from(game, from_is, from_id, card_id) do
      {:error, reason} ->
        {:error, reason}

      {:ok, card, game} ->
        card =
          case to_is do
            :hands -> Map.put(card, :face, true)
            :decks -> card
          end

        game
        |> update_in([to_is, id_access(to_id)], &Deck.put(&1, card))
        |> drop_empty_decks()
        |> (fn x -> {:ok, x} end).()
    end
  end

  @doc """
  Flip a card in deck or hand.
  """
  def flip(game, where, where_id, card_id) when where in [:decks, :hands] do
    game
    |> update_in([where, id_access(where_id), :cards, id_access(card_id)], &Card.flip/1)
    |> (fn x -> {:ok, x} end).()
  end

  @doc """
  Shuffle a deck / hand.
  """
  def shuffle(game, where, where_id) do
    {:ok, update_in(game, [where, id_access(where_id)], &Deck.shuffle/1)}
  end

  # Internals

  defp pop_from(game, where, where_id, card_id) do
    case get_and_update_in(game, [where, id_access(where_id)], &Deck.pop_card(&1, card_id)) do
      # When there's no such hand
      {[], _} ->
        {:error, :not_found}

        # When there's no such card
        {[nil], _} ->
        {:error, :not_found}

      {[%Card{} = card], game} ->
        {:ok, card, game}
    end
  end

  defp place(game, card, pos) do
    deck = %Deck{id: Gamixir.Random.id(8), pos: pos} |> Deck.put(card)
    update_in(game.decks, &[deck | &1])
  end

  defp id_access(id) do
    Access.filter(&(&1.id == id))
  end

  defp drop_empty_decks(game) do
    update_in(game.decks, fn decks ->
      Enum.filter(decks, fn d -> not Enum.empty?(d.cards) end)
    end)
  end
end