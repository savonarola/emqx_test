defmodule EMQXTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :emqx_test,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: false,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
    ]
  end
end
