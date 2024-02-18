defmodule TodoApp.Repo do
  use AshPostgres.Repo,
    otp_app: :todo_app,
    adapter: Ecto.Adapters.Postgres

  # Installs Postgres extensions that ash commonly uses
  def installed_extensions do
    ["uuid-ossp", "citext"]
  end
end
