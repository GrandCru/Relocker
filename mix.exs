defmodule Relocker.Mixfile do
  use Mix.Project

  def project do
    [app: :relocker,
     version: "0.0.1",
     elixir: "~> 1.0",
     build_embedded: Mix.env != :test,
     start_permanent: Mix.env != :test,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger],
     mod: {Relocker, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:timex, "~> 0.13.3"},
      {:exredis, ">= 0.1.1" }
    ]
  end
end
