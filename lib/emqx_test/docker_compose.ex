defmodule EMQXTest.DockerCompose do
  alias __MODULE__, as: DC

  use GenServer

  @docker_compose "docker-compose"
  @line_max 9_999
  @shutdown 30_000

  defstruct port: nil,
            file: "",
            env: [],
            current_line: "",
            lines: %{}

  def start_supervised(id, file, env) do
    child_spec = %{
      id: id,
      start: {DC, :start_link, [file, env]},
      restart: :temporary,
      shutdown: @shutdown,
      type: :worker
    }
    Supervisor.start_child(EMQXTest.Supervisor, child_spec)
  end


  def start_link(file, env) do
    GenServer.start_link(__MODULE__, %{file: file, env: env})
  end

  def get_logs(pid, tag) do
    GenServer.call(pid, {:get_logs, tag})
  end

  def get_logs(pid, tag, pattern) do
    GenServer.call(pid, {:get_logs, tag, pattern})
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  def init(%{file: file, env: env}) do
    Process.flag(:trap_exit, true)

    port =
      Port.open(
        {:spawn_executable, docker_compose()},
        [
          :binary,
          # :stderr_to_stdout,
          args: ["-f", file, "up", "--build", "--no-color"],
          env: charlist_env(env),
          line: @line_max
        ]
      )

    {:ok, %DC{port: port, file: file, env: env}}
  end

  def handle_call({:get_logs, tag}, _from, %DC{lines: lines} = st) do
    log_lines = Map.get(lines, tag, [])
    {:reply, log_lines, st}
  end

  def handle_call({:get_logs, tag, pattern}, _from, %DC{lines: lines} = st) do
    log_lines = Map.get(lines, tag, [])
    filtered_log_lines = Enum.filter(log_lines, fn log -> log =~ pattern end)
    {:reply, filtered_log_lines, st}
  end

  def handle_call(:stop, _from, st) do
    do_stop(st)
    {:stop, :normal, :ok, st}
  end

  def handle_info({port, {:data, {flag, line}}}, %DC{port: port} = st) do
    new_st = append_line(flag, line, st)
    {:noreply, new_st}
  end

  def handle_info({port, :closed}, %DC{port: port} = st) do
    {:stop, :closed, st}
  end

  def handle_info({:EXIT, port, reason}, %DC{port: port} = st) do
    {:stop, reason, st}
  end

  def terminate(st) do
    do_stop(st)
  end

  defp docker_compose() do
    System.find_executable(@docker_compose)
  end

  defp do_stop(%DC{port: port, file: file, env: env}) do
    true = Port.close(port)
    System.cmd(
      docker_compose(),
      ["-f", file, "down", "--remove-orphans"],
      [
        {:env, env},
        # :stderr_to_stdout
      ]
    )
  end

  defp append_line(:eol, line, %DC{current_line: current_line, lines: lines} = st) do
    full_line = current_line <> line
    {tag, log_line} = parse_line(full_line)

    %DC{
      st
      | current_line: "",
        lines: Map.update(lines, tag, [log_line], fn log_lines -> [log_line | log_lines] end)
    }
  end

  defp append_line(:noeol, line, %DC{current_line: current_line} = st) do
    new_current_line = current_line <> line
    %DC{st | current_line: new_current_line}
  end

  @dc_log_sep "|"
  @default_tag ""

  defp parse_line(line) do
    case String.split(line, @dc_log_sep, parts: 2) do
      [tag, line] ->
        {String.trim(tag), String.trim_leading(line)}

      [line] ->
        {@default_tag, line}
    end
  end

  defp charlist_env(env) do
    Enum.map(
      env,
      fn {name, val} -> {to_charlist(name), to_charlist(val)} end
    )
  end
end
