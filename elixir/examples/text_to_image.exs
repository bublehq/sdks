client = Buble.Client.new!()

{:ok, task} =
  Buble.Generations.create(client, %{
    model: "nano-banana",
    prompt: "A cinematic studio product photo of a translucent blue cube"
  })

id = task["data"]["id"]
{:ok, result} = Buble.Generations.wait(client, id)

IO.inspect(result)
