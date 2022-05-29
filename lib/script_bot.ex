defmodule ScriptBot do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Struct.Message

  require Logger

  @prefix ">:("

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  def handle_event({:MESSAGE_CREATE, %Message{content: @prefix <> " " <> content} = msg, _ws_state}) do
    handle_message(content, msg)
  end
  
  def handle_event(_event) do
    :noop
  end

  defp handle_message("ping", msg) do
    Api.create_message(msg.channel_id, "pong")
  end

  defp handle_message("add cmd " <> rest, msg) do
    name = rest |> String.splitter([" ", "\n"]) |> Enum.at(0)
    rest = rest |> String.replace_prefix("#{name} ", "")
    captures = Regex.named_captures(~r/((```py)|(```))(?<code>.*)```/Uus, rest)
    with %{"code" => code} <- captures do
      PyExec.store_code(name, code |> String.trim())
      Api.create_message(msg.channel_id, "Added command #{name}")
    else
      _ -> Api.create_message(msg.channel_id, "Invalid Code Block")
    end
  end

  defp handle_message(content, msg) do
    cmd = content |> String.splitter([" ", "\n"]) |> Enum.at(0)
    rest = content |> String.replace_prefix("#{cmd} ", "")
    with {:no_cmd, true} <- {:no_cmd, File.ls!("cmds") |> Enum.any?(& &1 == "#{cmd}.py")},
         {res, 0} <- cmd |> PyExec.exec_cmd(msg.author.username, rest)
    do
      Api.create_message(msg.channel_id, res)
    else
      {:no_cmd, _} -> 
        Api.create_message(msg.channel_id, "Command #{cmd} not found")
      {res, err_code} ->
        Api.create_message(msg.channel_id, "Error code #{err_code} after executing script:\n```#{res}```")
    end
  end
end


defmodule ScriptBot.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [ScriptBot]
    IO.puts("Starting bot")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
