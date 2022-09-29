defmodule Support.DockerCompose do
  @interval 100

  def wait_for_log(dc_pid, tag, pattern, timeout) do
    deadline = timeout + :erlang.monotonic_time(:millisecond)
    wait_for_log_till(dc_pid, tag, pattern, deadline)
  end

  defp wait_for_log_till(dc_pid, tag, pattern, deadline) do
    if :erlang.monotonic_time(:millisecond) > deadline do
      :timeout
    else
      case EMQXTest.DockerCompose.get_logs(dc_pid, tag, pattern) do
        [log | _] -> {:ok, log}
        [] ->
          :timer.sleep(@interval)
          wait_for_log_till(dc_pid, tag, pattern, deadline)
      end
    end
  end

end
