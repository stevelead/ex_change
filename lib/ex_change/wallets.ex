defmodule ExChange.Wallets do
  @moduledoc """
  The Wallets context.
  """

  import Ecto.Query, warn: false
  alias ExChange.Repo
  alias EctoShorts.Actions

  alias ExChange.Wallets.Wallet

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
end
