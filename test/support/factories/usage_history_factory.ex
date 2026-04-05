defmodule ApiTokenPool.UsageHistoryFactory do
  alias ApiTokenPool.Tokens.UsageHistory

  defmacro __using__(_opts) do
    quote do
      def usage_history_factory do
        %UsageHistory{
          token: build(:token),
          user: build(:user),
          started_at: DateTime.utc_now() |> DateTime.truncate(:second),
          ended_at: nil
        }
      end

      def closed_usage_history_factory do
        %UsageHistory{
          token: build(:token),
          user: build(:user),
          started_at:
            DateTime.add(DateTime.utc_now(), -120, :second) |> DateTime.truncate(:second),
          ended_at: DateTime.utc_now() |> DateTime.truncate(:second)
        }
      end
    end
  end
end
