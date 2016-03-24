defmodule Relocker.Mixfile do
  use Mix.Project

  def project do
    [app: :relocker,
     version: "0.0.8",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     elixirc_paths: elixirc_paths(Mix.env),
     description: description,
     package: package,
     dialyzer: [flags: ["-Woverspecs"]],
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
      {:exredis, ">= 0.2.3" },
      {:poolboy, github: "devinus/poolboy", tag: "1.5.1"},
      {:ex_doc, "~> 0.9", only: :dev},
      {:earmark, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    A library for holding a lock in Redis.
    """
  end

  defp package do
    [
     files: ["lib", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["Roope Kangas"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/grandCru/relocker"}
   ]
  end

  # Include some support code for :test
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/iex"]
  defp elixirc_paths(_), do: ["lib"]
end
