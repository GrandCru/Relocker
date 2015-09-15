defmodule Relocker.Mixfile do
  use Mix.Project

  def project do
    [app: :relocker,
     version: "0.0.2",
     elixir: "~> 1.0",
     build_embedded: Mix.env != :test,
     start_permanent: Mix.env != :test,
     elixirc_paths: elixirc_paths(Mix.env),
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
      {:exredis, ">= 0.2.0" }
    ]
  end

  # Include some support code for :test
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
