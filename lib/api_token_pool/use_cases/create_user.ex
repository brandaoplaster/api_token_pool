defmodule ApiTokenPool.UseCases.CreateUser do
  alias ApiTokenPool.Repositories.UserRepository

  def execute(attrs) do
    UserRepository.create(attrs)
  end
end
