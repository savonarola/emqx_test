defmodule Support.EMQTT do
 
  def connect(opts) do
    with {:ok, client} <- :emqtt.start_link(opts),
         {:ok, _} <- :emqtt.connect(client)
    do
      {:ok, client}
    end
  end

end


