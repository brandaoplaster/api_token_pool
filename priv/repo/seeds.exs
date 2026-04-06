# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ApiTokenPool.Repo.insert!(%ApiTokenPool.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias ApiTokenPool.Repo
alias ApiTokenPool.Accounts.User
alias ApiTokenPool.Tokens.Token

Repo.transaction(fn ->
  Enum.each(1..100, fn _ ->
    %Token{}
    |> Token.changeset(%{})
    |> Repo.insert!()
  end)
end)


Repo.transaction(fn ->
  Enum.each(1..105, fn _ ->
    %User{}
    |> User.changeset(%{name: Faker.Person.name()})
    |> Repo.insert!()
  end)
end)
