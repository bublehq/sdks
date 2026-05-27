client = Buble.Client.new!()

{:ok, response} =
  Buble.Chat.Completions.create(client, %{
    model: "chatgpt-5-4",
    messages: [
      %{role: "user", content: "Say hello from Elixir in one short sentence."}
    ]
  })

IO.inspect(response)
