defmodule ExChange.Wallets do
  @moduledoc """
  The Wallets context.
  """

  import Ecto.Query, warn: false
  alias ExChange.Repo
  alias Ecto.Multi
  alias ExChangeWeb.Endpoint
  alias EctoShorts.Actions

  alias ExChange.Wallets.Wallet
  alias ExChange.RatesServer

  @doc """
  Returns the list of wallets.

  ## Examples

      iex> list_wallets()
      [%Wallet{}, ...]

  """
  def list_wallets do
    Repo.all(Wallet)
  end

  @doc """
  Returns the list of wallets.

  ## Examples

      iex> list_wallets_by_user_id(1)
      [%Wallet{}, ...]

  """
  def list_wallets_by_user_id(user_id) do
    Actions.all(Wallet, user_id: user_id)
  end

  @doc """
  Returns the list of wallets.

  ## Examples

      iex> get_users_total_worth(1, "USD")
      "100"

  """
  def get_users_total_worth(user_id, currency, server \\ nil) do
    with wallets when is_list(wallets) <- list_wallets_by_user_id(user_id),
         total_worth <- get_total_worth_value(wallets, currency, server) do
      {:ok, %{user_id: String.to_integer(user_id), currency: currency, total_worth: total_worth}}
    end
  end

  defp get_total_worth_value(wallets, currency, server) do
    Enum.reduce(wallets, Decimal.new(0), fn
      %{currency: ^currency, balance: balance}, acc ->
        balance
        |> Decimal.new()
        |> Decimal.add(acc)

      wallet, acc ->
        with rate <- get_exchange_rate(wallet, currency, server),
             wallet_balance <- Decimal.new(wallet.balance),
             multiplied_decimal <- Decimal.mult(rate, wallet_balance) do
          multiplied_decimal |> Decimal.add(acc) |> Decimal.to_string()
        end
    end)
  end

  @doc """
  Gets a single wallet.

  Raises `Ecto.NoResultsError` if the Wallet does not exist.

  ## Examples

      iex> get_wallet!(123)
      %Wallet{}

      iex> get_wallet!(456)
      ** (Ecto.NoResultsError)

  """
  def get_wallet!(id), do: Repo.get!(Wallet, id)

  @doc """
  Finds a single wallet.

  Returns %{code: :not_found, ...} if the Wallet does not exist.

  ## Examples

      iex> find_wallet(%{user_id: 123, currency: "NZD"})
      %Wallet{}

      iex> find_wallet(%{user_id: 123, currency: "HUH"})
      {:error, %{code: :not_found, details: %{params: %{user_id: 123, currency: "HUH"}, query: Wallet}, message: "no records found"}}

  """
  def find_wallet(params), do: Actions.find(Wallet, params)

  @doc """
  Creates a wallet.

  ## Examples

      iex> create_wallet(%{field: value})
      {:ok, %Wallet{}}

      iex> create_wallet(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_wallet(attrs \\ %{}) do
    %Wallet{}
    |> Wallet.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a wallet.

  ## Examples

      iex> update_wallet(wallet, %{field: new_value})
      {:ok, %Wallet{}}

      iex> update_wallet(wallet, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_wallet(%Wallet{} = wallet, attrs) do
    wallet
    |> Wallet.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a wallet.

  ## Examples

      iex> delete_wallet(wallet)
      {:ok, %Wallet{}}

      iex> delete_wallet(wallet)
      {:error, %Ecto.Changeset{}}

  """
  def delete_wallet(%Wallet{} = wallet) do
    Repo.delete(wallet)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking wallet changes.

  ## Examples

      iex> change_wallet(wallet)
      %Ecto.Changeset{data: %Wallet{}}

  """
  def change_wallet(%Wallet{} = wallet, attrs \\ %{}) do
    Wallet.changeset(wallet, attrs)
  end

  @doc """
  Returns a Map of the frequencies of each currency in a list of wallets

  ## Examples

      iex> get_currency_count([%Wallet{currency: "NZD"}])
      %{"NZD" => 1}

  """
  def get_currency_count(wallets_list) do
    wallets_list
    |> Enum.reduce(%{}, &add_currency/2)
  end

  @doc """
  Returns a Map of the frequencies of each currency from a %Wallet{} and the result of get_currency_count/1

  ## Examples

      iex> add_currency([%Wallet{currency: "NZD"}, %{"NZD" => 1}])
      %{"NZD" => 2}

  """
  def add_currency(wallet, currency_count) do
    Map.update(currency_count, wallet.currency, 1, &(&1 + 1))
  end

  @doc """
  Returns a list of tuples containing the total combinations from a the result of get_currency_count/1 or add_currency/2

  Combinations of the same currency are not included in the result.

  ## Examples

      iex> get_exchange_combinations(%{"NZD" => 2}, "USD" => 2)
      [{"NZD", "USD}, {"USD", "NZD"}]

  """
  def get_exchange_combinations(currency_count) do
    held_currencies = Map.keys(currency_count)

    for from <- held_currencies, to <- held_currencies, from !== to do
      {from, to}
    end
  end

  @doc """
  Sends a payment from one wallet to another wallet

  The payment wallet must hold the same or greater amount of the send_currency and amount.

  The amount param must be a string and a valid param of Decimal.new/1 (i.e. "2.43" or "1")

  The receiving wallet must hold the receive_currency passed into the params.

  ## Examples

      iex> send_payment(1, 2, "NZD", 5, "USD")
      {:ok, %{sender_id: 1, receiver_id: 2}}

      iex> send_payment(1, 2, "HMM", 5, "HUH")
      {:error, ...}

  """

  def send_payment(send_id, rec_id, send_cur, amount, rec_cur, api_server \\ nil) do
    with {:ok, send_wallet} <- get_wallet(send_id, send_cur, :send),
         :ok <- check_send_balance(send_wallet, amount),
         {:ok, rec_wallet} <- get_wallet(rec_id, rec_cur, :rec),
         rate <- get_exchange_rate(send_wallet, rec_cur, api_server),
         rec_amount <- Decimal.mult(rate, amount),
         {:ok, _} <- do_transaction(send_wallet, amount, rec_wallet, rec_amount),
         details = %{
           sender_id: "#{send_wallet.user_id}",
           receiver_id: "#{rec_wallet.user_id}",
           send_currency: send_cur,
           send_amount: amount,
           receive_currency: rec_cur,
           received_amount: rec_amount,
           api_server: api_server
         },
         :ok <-
           Absinthe.Subscription.publish(Endpoint, details,
             total_worth_changed: [
               "total_worth_changed:" <> "#{send_id}",
               "total_worth_changed:" <> "#{rec_id}"
             ]
           ) do
      {:ok, details}
    end
  end

  defp get_wallet(user_id, cur, type) do
    case find_wallet(%{user_id: user_id, currency: cur}) do
      {:ok, wallet} ->
        {:ok, wallet}

      {:error, %{code: :not_found}} ->
        {:error, "#{type} wallet for #{cur} currency not found"}
    end
  end

  def check_send_balance(send_wallet, amount) do
    if send_wallet.balance === amount do
      :ok
    else
      {:error, :insufficient_send_wallet_balance}
    end
  end

  defp do_transaction(send_wallet, amount, rec_wallet, rec_amount) do
    with new_send_balance <- Decimal.sub(send_wallet.balance, amount),
         %Ecto.Changeset{} = send_cs <- change_wallet(send_wallet, %{balance: new_send_balance}),
         new_rec_balance <- Decimal.add(rec_wallet.balance, rec_amount),
         %Ecto.Changeset{} = rec_cs <- change_wallet(rec_wallet, %{balance: new_rec_balance}) do
      Multi.new()
      |> Multi.update(:send_wallet, send_cs)
      |> Multi.update(:rec_wallet, rec_cs)
      |> Repo.transaction()
    end
  end

  defp get_exchange_rate(wallet, currency, nil) when wallet.currency === currency,
    do: Decimal.new(1)

  defp get_exchange_rate(wallet, currency, nil) do
    RatesServer.get_exchange_rate("#{wallet.currency}:#{currency}")
  end

  defp get_exchange_rate(wallet, currency, server) do
    RatesServer.get_exchange_rate("#{wallet.currency}:#{currency}", server)
  end
end
