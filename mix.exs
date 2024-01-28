defmodule Topex.MixProject do
  use Mix.Project

  def project do
    [
      app: :topex,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Topex.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp releases do
    [
      topex_cli: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64]
          ]
        ]
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:toml, "~> 0.7"},
      {:dialyxir, "~> 1.4", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: &run_tests/1,
      "test.with_logs": fn args ->
        System.put_env("SHOW_LOGS", "1")
        run_tests(args)
      end
    ]
  end

  defp run_tests(args) do
    Mix.env(:test)
    Mix.Task.run("test", ["--no-start"] ++ args)
  end
end
