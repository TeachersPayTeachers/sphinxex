defmodule Sphinxex.Connection do
  @moduledoc """
  Main API for Sphinxex. This module handles the connection to .
  """

  defdelegate start_link(opts), to: Sphinxex
  defdelegate query(conn, statement), to: Sphinxex
  defdelegate query(conn, statement, params), to: Sphinxex
  defdelegate query(conn, statement, params, opts), to: Sphinxex
  defdelegate query!(conn, statement), to: Sphinxex
  defdelegate query!(conn, statement, params), to: Sphinxex
  defdelegate query!(conn, statement, params, opts), to: Sphinxex
end
