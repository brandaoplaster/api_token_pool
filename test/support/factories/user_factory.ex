defmodule ApiTokenPool.UserFactory do
  alias ApiTokenPool.Accounts.User

  defmacro __using__(_opts) do
    quote do
      def user_factory do
        %User{
          name: Faker.Person.name()
        }
      end
    end
  end
end
