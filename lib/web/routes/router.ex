defmodule RinhaVanilla.Plug.Router do
  use Plug.Router

  alias RinhaVanillaWeb.Controllers.PaymentsController

  plug(:match)
  plug(:dispatch)

  post("/payments", do: PaymentsController.handle_payment(conn))

  get("/payments-summary", do: PaymentsController.summary(conn))

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
