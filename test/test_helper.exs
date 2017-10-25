ExUnit.configure exclude: [:ssl_tests]
ExUnit.start()

run_cmd = fn cmd ->
  key = :ecto_setup_cmd_output
  Process.put(key, "")
  status = Mix.Shell.cmd(cmd, fn(data) ->
    current = Process.get(key)
    Process.put(key, current <> data)
  end)
  output = Process.get(key)
  Process.put(key, "")
  {status, output}
end

mysql_pass_switch = if mysql_root_pass = System.get_env("MYSQL_ROOT_PASSWORD") do
  "-p#{mysql_root_pass}"
else
  ""
end

sql = """
  CREATE TABLE test1 (id serial, title text);
  INSERT INTO test1 VALUES(1, 'test');
  INSERT INTO test1 VALUES(2, 'test2');
  DROP TABLE test1;
"""

cmds = [
  ~s(mysql -u root #{mysql_pass_switch} -e "GRANT ALL ON *.* TO 'sphinxex_user'@'localhost' IDENTIFIED BY 'sphinxex_pass';"),
  ~s(mysql -u root #{mysql_pass_switch} -e "DROP DATABASE IF EXISTS sphinxex_test;"),
  ~s(mysql -u root #{mysql_pass_switch} -e "CREATE DATABASE sphinxex_test DEFAULT CHARACTER SET 'utf8' COLLATE 'utf8_general_ci'";),
  ~s(mysql -u root #{mysql_pass_switch} sphinxex_test -e "#{sql}"),
  ~s(mysql -u sphinxex_user -psphinxex_pass sphinxex_test -e "#{sql}")
]

Enum.each(cmds, fn cmd ->
  {status, output} = run_cmd.(cmd)
  IO.puts "--> #{output}"

  if status != 0 do
    IO.puts """
    Command:
    #{cmd}
    error'd with:
    #{output}
    Please verify the user "root" exists and it has permissions to
    create databases and users.
    If the "root" user requires a password, set the environment
    variable MYSQL_ROOT_PASSWORD to its value.
    Beware that the password may be visible in the process list!
    """
    System.halt(1)
  end
end)

defmodule Sphinxex.TestHelper do
  defmacro query(stat, params, opts \\ []) do
    quote do
      case Sphinxex.Connection.query(var!(context)[:pid], unquote(stat),
                                     unquote(params), unquote(opts)) do
        {:ok, %Sphinxex.Result{rows: nil}} -> :ok
        {:ok, %Sphinxex.Result{rows: rows}} -> rows
        {:error, %Sphinxex.Error{} = err} -> err
      end
    end
  end

  defmacro execute_text(stat, params, opts \\ []) do
    quote do
      case Sphinxex.execute(var!(context)[:pid], %Sphinxex.Query{type: :text, statement: unquote(stat)},
            unquote(params), unquote(opts)) do
        {:ok, %Sphinxex.Result{rows: nil}} -> :ok
        {:ok, %Sphinxex.Result{rows: rows}} -> rows
        {:error, %Sphinxex.Error{} = err} -> err
      end
    end
  end

  defmacro with_prepare!(name, stat, params, opts \\ []) do
    quote do
      conn = var!(context)[:pid]
      query = Sphinxex.prepare!(conn, unquote(name), unquote(stat), unquote(opts))
      case Sphinxex.execute!(conn, query, unquote(params)) do
        %Sphinxex.Result{rows: nil} -> :ok
        %Sphinxex.Result{rows: rows} -> rows
      end
    end
  end

  def capture_log(fun) do
    Logger.remove_backend(:console)
    fun.()
    Logger.add_backend(:console, flush: true)
  end

  def length_encode_row(row) do
    Enum.map_join(row, &(<<String.length(&1)>> <> &1))
  end

end
