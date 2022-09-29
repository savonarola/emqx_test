defmodule JwtAuthzTest do
  use ExUnit.Case

  alias EMQXTest.DockerCompose, as: DC

  alias Support.DockerCompose, as: DCHelpers
  alias Support.Finch, as: FinchHelpers
  alias Support.EMQTT, as: EMQTTHelpers

  alias Finch.Response, as: Response

  @dc_file "test/jwt_authz/docker-compose.yml"
  @timeout 60_000

  setup_all do
    emqx_version = System.get_env("EMQX_VERSION")

    {:ok, pid} = DC.start_supervised(__MODULE__, @dc_file, [{"EMQX_VERSION", emqx_version}])

    {:ok, _} = DCHelpers.wait_for_log(pid, "emqx_hs_1", ~r/EMQ X Broker .*? is running now/, @timeout)
    {:ok, _} = DCHelpers.wait_for_log(pid, "emqx_rs_1", ~r/EMQ X Broker .*? is running now/, @timeout)

    on_exit(fn -> DC.stop(pid) end)
    %{dc: pid}
  end

  test "authorize with JWT (hmac)" do
    assert {:ok, %Response{body: jwt, status: 200}} = FinchHelpers.post_urlencoded(
      "http://localhost:4001/hs/authn_acl_token",
      "username=subuser&password=pass2"
    )

    {:ok, client} = EMQTTHelpers.connect(username: "subuser", password: jwt)

    assert {:ok, _, [0]} = :emqtt.subscribe(client, "foo")
    assert {:ok, _, [128]} = :emqtt.subscribe(client, "bar")

    :emqtt.disconnect(client)
  end

  test "authorize with JWT (rsa)" do
    assert {:ok, %Response{body: jwt, status: 200}} = FinchHelpers.post_urlencoded(
      "http://localhost:4001/rs/authn_acl_token",
      "username=subuser&password=pass2"
    )

    {:ok, client} = EMQTTHelpers.connect(username: "subuser", password: jwt, port: 1884)

    assert {:ok, _, [0]} = :emqtt.subscribe(client, "foo")
    assert {:ok, _, [128]} = :emqtt.subscribe(client, "bar")

    :emqtt.disconnect(client)
  end
end
