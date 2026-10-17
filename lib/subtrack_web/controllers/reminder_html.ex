defmodule SubtrackWeb.ReminderHTML do
  use SubtrackWeb, :html

  embed_templates "reminder_html/*"

  @doc """
  Renders a reminder form.

  The form is defined in the template at
  reminder_html/reminder_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def reminder_form(assigns)
end
