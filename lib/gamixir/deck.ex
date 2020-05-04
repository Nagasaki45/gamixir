defmodule Gamixir.Deck do
  alias Gamixir.Card

  @behaviour Access

  defstruct id: nil, pos: [500, 500], cards: []

  # Implementing the Access behaviour by delegating to Map
  defdelegate fetch(data, key), to: Map
  defdelegate get_and_update(data, key, fun), to: Map
  defdelegate pop(data, key), to: Map

  def pop_card(%__MODULE__{cards: []} = d), do: {nil, d}

  def pop_card(%__MODULE__{cards: [card | cards]} = d) do
    {card, Map.put(d, :cards, cards)}
  end

  def pop_card(%__MODULE__{} = deck, card_id) do
    access = [:cards, Access.filter(&(&1.id == card_id))]

    case pop_in(deck, access) do
      {[card], deck} -> {card, deck}
      {[], deck} -> {nil, deck}
    end
  end

  def put(%__MODULE__{} = d, card) do
    update_in(d.cards, &[card | &1])
  end

  def shuffle(%__MODULE__{} = d) do
    update_in(d.cards, &Enum.shuffle/1)
  end

  def dist(%__MODULE__{pos: [x0, y0]}, [x1, y1]) do
    square = fn x -> x * x end
    :math.sqrt(square.(x0 - x1) + square.(y0 - y1))
  end
end
