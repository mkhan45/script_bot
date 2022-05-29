defmodule PyExec do
  require EEx
  EEx.function_from_file(:def, :template, "lib/templates/pytemplate.py", [:code])

  def exec_cmd(cmd, user_id, args) do
    System.cmd("python3.10", ["cmds/#{cmd}.py", user_id |> to_string(), args], stderr_to_stdout: true)
  end

  def store_code(name, code) do
    File.write!("cmds/#{name}.py", template(code))
  end
end
