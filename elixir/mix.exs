defmodule Buble.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/bublehq/sdks"

  def project do
    [
      app: :buble,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Official Elixir SDK for the Buble public API.",
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: "https://buble.ai"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "buble",
      licenses: ["MIT"],
      links: %{
        "Buble" => "https://buble.ai/",
        "Buble API Docs" => "https://buble.ai/docs",
        "GitHub" => @source_url
      },
      files: [
        "lib",
        "examples",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE"
      ]
    ]
  end

  defp docs do
    [
      main: "Buble",
      source_ref: "main",
      source_url: @source_url,
      extras: ["README.md", "CHANGELOG.md"],
      groups_for_modules: [
        Client: [
          Buble,
          Buble.Client,
          Buble.Error
        ],
        Resources: [
          Buble.Apps,
          Buble.Apps.Generations,
          Buble.Chat,
          Buble.Chat.Completions,
          Buble.Chat.Gemini,
          Buble.Chat.Messages,
          Buble.Chat.Models,
          Buble.Files,
          Buble.Generations,
          Buble.MediaModels
        ],
        Internals: [
          Buble.HTTP,
          Buble.Multipart,
          Buble.SSE,
          Buble.SSE.Event,
          Buble.Transport,
          Buble.Transport.Req,
          Buble.Types
        ]
      ]
    ]
  end
end
