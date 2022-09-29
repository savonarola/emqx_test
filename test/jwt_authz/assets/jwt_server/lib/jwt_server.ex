defmodule JwtServer do
  require Logger

  use Plug.Router

  plug(Plug.Parsers,
    parsers: [:urlencoded]
  )

  plug(Plug.Logger, log: :debug)

  plug(:match)
  plug(:dispatch)

  @user_data %{
    "pubuser" => %{
      password: "pass1",
      acl: %{
        "pub" => ["foo"]
      }
    },
    "subuser" => %{
      password: "pass2",
      acl: %{
        "sub" => ["foo"]
      }
    }
  }

  @ttl 600

  @secret "emqxsecret"

  @jwk_hs JOSE.JWK.from_oct(@secret)
  @jws_hs %{"alg" => "HS256"}

  @kid "testkey@emqx.io"
  @jwk_rs_files %{
    priv: "private_key.pem",
    pub: "public_key.pem"
  }
  @jws_rs %{"alg" => "RS256", "kid" => @kid}

  post "/hs/authn_acl_token" do
    with %{"password" => pass, "username" => username} <- conn.params,
         user_data <- @user_data[username],
         %{password: ^pass} <- user_data do
      now = now()

      payload = %{
        username: username,
        exp: now + @ttl,
        iat: now,
        acl: user_data[:acl]
      }

      send_resp(conn, 200, sign(@jwk_hs, payload, @jws_hs))
    else
      _ -> send_resp(conn, 403, "forbidden")
    end
  end

  post "/rs/authn_acl_token" do
    with %{"password" => pass, "username" => username} <- conn.params,
         user_data <- @user_data[username],
         %{password: ^pass} <- user_data do
      now = now()

      payload = %{
        username: username,
        exp: now + @ttl,
        iat: now,
        acl: user_data[:acl]
      }

      send_resp(conn, 200, sign(jwk_rs(:priv), payload, @jws_rs))
    else
      _ -> send_resp(conn, 403, "forbidden")
    end
  end

  get "/keys.json" do
    jwks_rs = jwk_rs(:pub)
    {_, key} = JOSE.JWK.to_map(jwks_rs)
    jwks = %{<<"keys">> => [key]}

    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, Jason.encode!(jwks))
  end

  match _ do
    send_resp(conn, 404, "not found")
  end

  defp sign(jwk, payload, jws) do
    {_, jwt} =
      jwk
      |> JOSE.JWS.sign(Jason.encode!(payload), jws)
      |> JOSE.JWS.compact()

    jwt
  end

  defp now() do
    DateTime.utc_now()
    |> DateTime.to_unix()
  end

  defp jwk_rs(kind) do
    jwk = JOSE.JWK.from_pem_file(Path.join(:code.priv_dir(:jwt_server), @jwk_rs_files[kind]))
    %JOSE.JWK{jwk | fields: Map.put(jwk.fields, "kid", @kid)}
  end
end
