defmodule ApiTokenPool.Workers.ReleaseTokenWorkerTest do
  use ApiTokenPool.DataCase, async: true
  use Oban.Testing, repo: ApiTokenPool.Repo

  alias ApiTokenPool.Repo
  alias ApiTokenPool.Tokens.Token
  alias ApiTokenPool.Workers.ReleaseTokenWorker

  import ApiTokenPool.Factory

  describe "perform/1" do
    test "releases an allocated token successfully" do
      user = insert(:user)

      token =
        insert(:token,
          status: :allocated,
          user_id: user.id,
          allocated_at: DateTime.utc_now()
        )

      insert(:usage_history, token: token, user: user)

      assert :ok = perform_job(ReleaseTokenWorker, %{token_id: token.id})

      updated_token = Repo.get(Token, token.id)
      assert updated_token.status == :available
      assert is_nil(updated_token.user_id)
      assert is_nil(updated_token.allocated_at)
    end

    test "does nothing if token is already available" do
      token = insert(:token, status: :available)

      assert :ok = perform_job(ReleaseTokenWorker, %{token_id: token.id})

      updated_token = Repo.get(Token, token.id)
      assert updated_token.status == :available
    end

    test "does nothing if token does not exist" do
      fake_id = Ecto.UUID.generate()

      assert :ok = perform_job(ReleaseTokenWorker, %{token_id: fake_id})
    end

    test "returns error if release fails" do
      user = insert(:user)

      token =
        insert(:token,
          status: :allocated,
          user_id: user.id,
          allocated_at: DateTime.utc_now()
        )

      assert {:error, _} = perform_job(ReleaseTokenWorker, %{token_id: token.id})
    end
  end
end
