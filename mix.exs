defmodule Carrot.MixProject do
  use Mix.Project

  @url "https://github.com/bleacherreport/carrot"
  @version "1.1.0"

  def project do
    [
      app: :carrot,
      deps: deps(),
      description: "AMQP connection manager",
      dialyzer: dialyzer(),
      elixir: "~> 1.5 or ~> 1.6",
      homepage_url: @url,
      name: "Carrot",
      package: package(),
      preferred_cli_env: preferred_cli_env(),
      source_url: @url,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:amqp, "~> 1.0"},

      # dev and test dependencies
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:excoveralls, "~> 0.9", only: :test},
      {:ex_doc, "> 0.0.0", only: :dev}
    ]
  end

  defp dialyzer do
    [
      plt_add_deps: true,
      plt_add_apps: [:ssl]
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.json": :test
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/bleacherreport/carrot"},
      maintainers: ["Sonny Scroggin"]
    ]
  end
end
