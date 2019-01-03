defmodule KV.MixProject do
  use Mix.Project

  def project do
    [
      app: :kv,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      # env returns the application default environment
      # the app would ship with an empty routing table, to be configured
      # depending on the testing/deployment scenario
      # a default routing table has been configured for the umbrella project
      # in kv_umbrella/config/config.exs
      env: [routing_table: []],
      # `:mod` specifies the "application callback module", plus args
      # to be passed on app start. Application module must implement
      # the `Application` behaviour
      mod: {KV, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
