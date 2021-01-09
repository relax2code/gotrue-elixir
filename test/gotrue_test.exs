defmodule GoTrueTest do
  use ExUnit.Case

  import Tesla.Mock

  test "settings/0" do
    mock(fn
      %{method: :get, url: "http://auth.example.com/settings"} ->
        json(%{"a_setting" => 1234})
    end)

    assert GoTrue.settings() == %{"a_setting" => 1234}
  end

  describe "sign_up/1" do
    test "with invalid response" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/signup"} ->
          json(%{"msg" => "invalid"}, status: 422)
      end)

      assert GoTrue.sign_up(%{email: "user@example.com", password: "oops"}) ==
               {:error, %{code: 422, message: "invalid"}}
    end

    test "with duplicate response" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/signup"} ->
          json(%{"msg" => "already exists"}, status: 400)
      end)

      assert GoTrue.sign_up(%{email: "exists@example.com", password: "12345"}) ==
               {:error, %{code: 400, message: "already exists"}}
    end

    test "with valid params" do
      mock(fn
        %{
          method: :post,
          url: "http://auth.example.com/signup",
          body:
            ~s|{"aud":null,"data":{"favorite_language":"elixir"},"email":"user@example.com","password":"12345"}|
        } ->
          json(
            %{
              access_token: "1234",
              expires_in: 60,
              token_type: "bearer",
              refresh_token: "abcd",
              user: %{}
            },
            status: 200
          )
      end)

      assert GoTrue.sign_up(%{
               email: "user@example.com",
               password: "12345",
               data: %{favorite_language: "elixir"}
             }) ==
               {:ok,
                %{
                  access_token: "1234",
                  expires_in: 60,
                  refresh_token: "abcd",
                  token_type: "bearer",
                  user: %{}
                }}
    end

    test "with extra params" do
      mock(fn
        %{
          method: :post,
          url: "http://auth.example.com/signup",
          body:
            ~s|{"aud":"superheros","data":{"favorite_language":"elixir"},"email":"user@example.com","password":"12345","provider":"email"}|
        } ->
          json(
            %{
              access_token: "1234",
              expires_in: 60,
              token_type: "bearer",
              refresh_token: "abcd",
              user: %{}
            },
            status: 200
          )
      end)

      assert GoTrue.sign_up(%{
               email: "user@example.com",
               password: "12345",
               data: %{favorite_language: "elixir"},
               audience: "superheros",
               provider: "email"
             }) ==
               {:ok,
                %{
                  access_token: "1234",
                  expires_in: 60,
                  refresh_token: "abcd",
                  token_type: "bearer",
                  user: %{}
                }}
    end
  end

  describe "recover/1" do
    test "valid params" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/recover"} ->
          json(%{})
      end)

      assert GoTrue.recover("user@example.com") == :ok
    end

    test "invalid params" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/recover"} ->
          json(%{msg: "oops"}, status: 422)
      end)

      assert GoTrue.recover("") ==
               {:error, %{message: "oops", code: 422}}
    end
  end

  describe "send_magic_link/1" do
    test "valid params" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/magiclink"} ->
          json(%{})
      end)

      assert GoTrue.send_magic_link("user@example.com") == :ok
    end

    test "invalid params" do
      mock(fn
        %{method: :post, url: "http://auth.example.com/magiclink"} ->
          json(%{msg: "oops"}, status: 422)
      end)

      assert GoTrue.send_magic_link("") ==
               {:error, %{message: "oops", code: 422}}
    end
  end

  describe "invite/1" do
    setup do
      mock(fn
        %{
          method: :post,
          url: "http://auth.example.com/invite",
          body: ~s|{"email":"existing@example.com"}|
        } ->
          json(%{"msg" => "already registered"}, status: 422)

        %{method: :post, url: "http://auth.example.com/invite"} ->
          json(%{"email" => "user@example.com"})
      end)

      :ok
    end

    test "with invalid params" do
      assert GoTrue.invite(%{email: "existing@example.com"}) ==
               {:error, %{code: 422, message: "already registered"}}
    end

    test "with valid params" do
      assert GoTrue.invite(%{
               email: "user@example.com",
               data: %{favorite_language: "elixir"}
             }) == {:ok, %{"email" => "user@example.com"}}
    end
  end

  test "url_for_provider/1" do
    assert GoTrue.url_for_provider("google") ==
             "http://auth.example.com/authorize?provider=google"
  end
end
