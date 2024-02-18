defmodule TodoApp.Accounts do
  use Ash.Api

  resources do
    resource TodoApp.Accounts.User
    resource TodoApp.Accounts.Token
  end
end
