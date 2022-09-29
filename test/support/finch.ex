defmodule Support.Finch do
 
  def post_urlencoded(url, body) do
    req = Finch.build(
      :post,
      url,
      [{"Content-Type", "application/x-www-form-urlencoded"}],
      body
    )

    Finch.request(req, Finch)
  end

end

