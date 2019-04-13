defmodule VirtuosoWeb.V1.SlackAuthController do
  use VirtuosoWeb, :controller

  require Logger

  @redirect_uri Application.get_env(:virtuoso, :redirect_uri)
  @client_id Application.get_env(:virtuoso, :client_id)
  @client_secret Application.get_env(:virtuoso, :client_secret)
  @slack_workspace_domain Application.get_env(:virtuoso, :slack_workspace_domain)

  def request(conn, %{"provider" => _provider, "code" => code, "state" => _state}) do
    can_perform_request? = slack_setup_successful?()
    slack_account_details = get_slack_account_details(conn, code, can_perform_request?)

    case slack_account_details["ok"] do
      false ->
        Logger.info(":error Slack reponded with : \n#{inspect(slack_account_details["error"])}")

        conn
        |> put_status(401)
        |> json(%{
          message: "Slack error: #{inspect(slack_account_details["error"])}"
        })

      _ ->
        Logger.info("Registered Slack user #{slack_account_details["user_id"]}")

        conn
        |> put_status(302)
        |> redirect(external: "https://#{@slack_workspace_domain}.slack.com")

    end
  end

  defp get_slack_account_details(conn, code, false) do
    conn
    |> put_status(400)
    |> json(%{message: "Missing Slack configs"})
  end

  defp get_slack_account_details(_conn, code, true) do
    Logger.info("slack redirect url: #{@redirect_uri}")

    Slack.Web.Oauth.access(
      @client_id, @client_secret,
      code,
      %{
        redirect_uri: @redirect_uri
      }
    )
  end

  defp get_slack_account_details(_conn, nil, _can_perform_request?), do: "Missing code"

  defp slack_setup_successful?() do
    if @redirect_uri && @client_id && @client_secret, do: true, else: false
  end

end
