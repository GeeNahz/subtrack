defmodule Subtrack.Money do
  def format(nil, _currency), do: "-"

  def format(%Decimal{} = amount, currency) do
    "#{currency} #{amount |> Decimal.round(2) |> Decimal.to_string(:normal)}"
  end
end
