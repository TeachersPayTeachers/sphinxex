defmodule PreparedQueryTest do
  use ExUnit.Case
  import Sphinxex.TestHelper

  setup do
    opts = [database: "sphinxex_test", username: "sphinxex_user", password: "sphinxex_pass", backoff_type: :stop]
    {:ok, pid} = Sphinxex.Connection.start_link(opts)
    {:ok, [pid: pid]}
  end

  test "simple prepared query", context do
    :ok = query("CREATE TABLE prepared_test (id int, text text)", [])
    assert with_prepare!("test", "SELECT * FROM prepared_test", []) == []
  end

  test "unprepared query should work", context do
    :ok = query("CREATE TABLE unprepared_test (id int, text text)", [])
    conn = context[:pid]
    query = %Sphinxex.Query{type: :binary, name: "unprepared_test", statement: "SELECT * FROM unprepared_test"}
    assert %{rows: []} = Sphinxex.execute!(conn, query, [])
  end
end
