defmodule SubtrackWeb.PaymentMethodHTML do
  use SubtrackWeb, :html

  embed_templates "payment_method_html/*"

  @doc """
  Renders a payment_method form.

  The form is defined in the template at
  payment_method_html/payment_method_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def payment_method_form(assigns)
end
