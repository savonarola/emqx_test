defmodule EMQXTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :emqx_test,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: true,
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [debug_info: Mix.env() == :dev],
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EMQXTest.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.13"},
      {:emqtt, github: "emqx/emqtt", tag: "1.6.1", system_env: [{"BUILD_WITHOUT_QUIC", "1"}]}
    ]
  end
end
