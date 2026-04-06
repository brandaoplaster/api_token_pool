defmodule ApiTokenPool.TokenFactory do
  alias ApiTokenPool.Tokens.Token

  defmacro __using__(_opts) do
    quote do
      def token_factory do
        %Token{
          user_id: nil,
          allocated_at: nil,
          status: :available
        }
      end

      def allocated_token_factory do
        %Token{
          user: build(:user),
          allocated_at: DateTime.truncate(DateTime.utc_now(), :second),
          status: :allocated
        }
      end
    end
  end
end
