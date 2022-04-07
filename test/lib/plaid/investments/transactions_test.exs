defmodule Plaid.Investments.TransactionsTest do
  use ExUnit.Case, async: true

  import Mox
  import Plaid.Factory

  setup do
    verify_on_exit!()

    {:ok,
     params: %{access_token: "my-token"},
     config: %{
       client: PlaidMock,
       client_id: "test_id",
       secret: "test_secret",
       root_uri: "http://localhost:4000/"
     }}
  end

  @moduletag :"investments/transactions"

  @tag :unit
  test "investments/transactions data structure encodes with Jason" do
    assert {:ok, _} =
             Jason.encode(%Plaid.Investments.Transactions{
               accounts: [%Plaid.Accounts.Account{}],
               item: %Plaid.Item{},
               securities: [%Plaid.Investments.Security{}],
               investment_transactions: [%Plaid.Investments.Transactions.Transaction{}]
             })
  end

  describe "investments/transactions get/2" do
    @tag :unit
    test "submits request and unmarshalls response", %{params: params, config: config} do
      PlaidMock
      |> expect(:send_request, fn request, _client ->
        assert request.method == :post
        assert request.endpoint == "investments/transactions/get"
        assert %{metadata: _} = request.opts
        {:ok, %Tesla.Env{}}
      end)
      |> expect(:handle_response, fn _response, mapper ->
        body = http_response_body(:"investments/transactions")
        {:ok, mapper.(body)}
      end)

      assert {:ok, ds} = Plaid.Investments.Transactions.get(params, config)
      assert Plaid.Investments.Transactions == ds.__struct__
      assert Plaid.Accounts.Account == List.first(ds.accounts).__struct__
      assert Plaid.Investments.Security == List.first(ds.securities).__struct__

      assert Plaid.Investments.Transactions.Transaction ==
               List.first(ds.investment_transactions).__struct__

      assert Plaid.Item == ds.item.__struct__
    end

    @tag :integration
    test "success integration test", %{params: params} do
      bypass = Bypass.open()

      config = %{
        client_id: "test_id",
        secret: "test_secret",
        root_uri: "http://localhost:#{bypass.port}/"
      }

      body = http_response_body(:"investments/transactions")

      Bypass.expect(bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(200, Poison.encode!(body))
      end)

      assert {:ok, %Plaid.Investments.Transactions{}} =
               Plaid.Investments.Transactions.get(params, config)
    end

    @tag :integration
    test "error integration test", %{params: params} do
      bypass = Bypass.open()

      config = %{
        client_id: "test_id",
        secret: "test_secret",
        root_uri: "http://localhost:#{bypass.port}/"
      }

      body = http_response_body(:error)

      Bypass.expect(bypass, fn conn ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.resp(400, Poison.encode!(body))
      end)

      assert {:error, %Plaid.Error{}} = Plaid.Investments.Transactions.get(params, config)
    end
  end
end
