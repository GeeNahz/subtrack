defmodule Subtrack.Timezones do
  @default "Etc/UTC"

  def default, do: @default

  @doc """
  Zone names for a dropdown. Includes the default which isn't always canonical.
  """
  def options do
    [@default | Tzdata.canonical_zone_list()]
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Accepts any zone Tzdata knows, including legacy aliases like Asia/Calcutta.
  """
  def valid?(zone) when is_binary(zone), do: Tzdata.zone_exists?(zone)
  def valid?(_), do: false
end
