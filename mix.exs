defmodule Mnemonist.MixProject do
  use Mix.Project

  @app :mnemonist
  @project_url "https://github.com/halostatue/mnemonist"
  @version "1.0.0"

  def project do
    [
      app: @app,
      description: "BIP-39 mnemonic tools for Elixir",
      version: @version,
      source_url: @project_url,
      name: "Mnemonist",
      elixir: "~> 1.14",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.github": :test,
        "coveralls.html": :test
      ],
      test_coverage: test_coverage(),
      elixirc_paths: elixirc_paths(Mix.env()),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_local_path: "priv/plts/project",
        plt_core_path: "priv/plts/core"
      ]
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      maintainers: "Austin Ziegler",
      licenses: ["Apache-2.0", "MIT"],
      files: ~w(lib .formatter.exs mix.exs *.md),
      links: %{
        "Source" => @project_url,
        "Issues" => @project_url <> "/issues"
      }
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.29", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: [:test]},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:quokka, "~> 2.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "Mnemonist",
      extras: [
        "README.md",
        "CONTRIBUTING.md": [filename: "CONTRIBUTING.md", title: "Contributing"],
        "CODE_OF_CONDUCT.md": [filename: "CODE_OF_CONDUCT.md", title: "Code of Conduct"],
        "CHANGELOG.md": [filename: "CHANGELOG.md", title: "CHANGELOG"],
        "LICENCE.md": [filename: "LICENCE.md", title: "Licence"],
        "licences/APACHE-2.0.txt": [
          filename: "APACHE-2.0.txt",
          title: "Apache License, version 2.0"
        ],
        "licences/MIT.txt": [filename: "MIT.txt", title: "MIT License"],
        "licences/dco.txt": [filename: "dco.txt", title: "Developer Certificate of Origin"],
        "SECURITY.md": [filename: "SECURITY.md", title: "Security"]
      ],
      source_ref: "v#{@version}",
      source_url: @project_url,
      canonical: "https://hexdocs.pm/#{@app}"
    ]
  end

  defp test_coverage do
    [
      tool: ExCoveralls
    ]
  end
end
