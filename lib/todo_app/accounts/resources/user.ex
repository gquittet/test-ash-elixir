defmodule TodoApp.Accounts.User do
  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  attributes do
    uuid_primary_key :id
    attribute :email, :ci_string, allow_nil?: false
    attribute :hashed_password, :string, allow_nil?: false, sensitive?: true
  end

  actions do
    read :read do
      primary? true
    end
  end

  authentication do
    api TodoApp.Accounts

    strategies do
      password :password do
        identity_field :email

        resettable do
          sender TodoApp.Accounts.User.Senders.SendPasswordResetEmail
        end
      end
    end

    tokens do
      enabled? true
      token_resource TodoApp.Accounts.Token

      signing_secret TodoApp.Accounts.Secrets
    end
  end

  postgres do
    table "users"
    repo TodoApp.Repo
  end

  identities do
    identity :unique_email, [:email]
  end

  # If using policies, add the following bypass:
  # policies do
  #   bypass AshAuthentication.Checks.AshAuthenticationInteraction do
  #     authorize_if always()
  #   end
  # end
end
