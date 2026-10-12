defmodule SubtrackWeb.UserSessionHTML do
  use SubtrackWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:subtrack, Subtrack.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
