defmodule ApiTokenPool.UseCases.ListUsers do
  alias ApiTokenPool.Repositories.UserRepository

  def execute do
    UserRepository.list_all()
  end
end
