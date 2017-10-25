defmodule StartTest do
  use ExUnit.Case, async: true

  test "connection_errors" do
    Process.flag :trap_exit, true
    assert {:error, {%Sphinxex.Error{mariadb: %{message: "Unknown database 'non_existing'"}}, _}} =
      Sphinxex.Connection.start_link(username: "mariaex_user", password: "mariaex_pass", database: "non_existing", sync_connect: true, backoff_type: :stop)
    assert {:error, {%Sphinxex.Error{mariadb: %{message: "Access denied for user " <> _}}, _}} =
      Sphinxex.Connection.start_link(username: "non_existing", database: "mariaex_test", sync_connect: true, backoff_type: :stop)
    assert {:error, {%Sphinxex.Error{message: "tcp connect: econnrefused"}, _}} =
      Sphinxex.Connection.start_link(username: "mariaex_user", password: "mariaex_pass", database: "mariaex_test", port: 60999, sync_connect: true, backoff_type: :stop)
  end

  ## Tests tagged with :ssl_tests are excluded from running by default (see test_helper.exs)
  ## as they require that your Sphinxex/MySQL server instance be configured for SSL logins:
  ## https://dev.mysql.com/doc/refman/5.7/en/creating-ssl-files-using-openssl.html
  @tag :ssl_tests
  test "ssl_connection_errors" do
    test_opts = [username: "mariaex_user",
                     password: "mariaex_pass",
                     database: "mariaex_test",
                     sync_connect: true,
                     ssl: true,
                     ssl_opts: [cacertfile: "",
                                verify: :verify_peer,
                                versions: [:"tlsv1.2"]],
                     backoff_type: :stop]

    Process.flag :trap_exit, true
    assert {:error, {%Sphinxex.Error{message: "failed to upgraded socket: {:tls_alert, 'unknown ca'}"}, _}} =
      Sphinxex.Connection.start_link(test_opts)
    assert {:error, {%Sphinxex.Error{message: "failed to upgraded socket: {:options, {:cacertfile, []}}"}, _}}  =
      Sphinxex.Connection.start_link(Keyword.put(test_opts, :ssl_opts, Keyword.drop(test_opts[:ssl_opts], [:cacertfile])))
  end
end
