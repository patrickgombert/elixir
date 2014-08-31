Logger.configure_backend(:console, colors: [enabled: false])
ExUnit.start()

defmodule Logger.Case do
  use ExUnit.CaseTemplate
  import ExUnit.CaptureIO

  using _ do
    quote do
      import Logger.Case
    end
  end

  def msg(msg) do
    ~r/\d\d\:\d\d\:\d\d\.\d\d\d #{Regex.escape(msg)}/
  end

  def wait_for_handler(manager, handler) do
    unless handler in GenEvent.which_handlers(manager) do
      :timer.sleep(10)
      wait_for_handler(manager, handler)
    end
  end

  def wait_for_logger() do
    try do
      GenEvent.which_handlers(Logger)
    else
      _ ->
        :ok
    catch
      :exit, _ ->
        :timer.sleep(10)
        wait_for_logger()
    end
  end

  def capture_log(level \\ :debug, fun) do
    Logger.configure(level: level)
    capture_io(:user, fn ->
      fun.()
      Logger.flush()
    end)
  after
    Logger.configure(level: :debug)
  end

  def last_file_line do
    Logger.flush()
    File.read!("log/#{Mix.env}.log")
      |> String.split("\n")
      |> Enum.reverse
      |> Enum.at(0)
  end

  def in_tmp(function) do
    path = Path.expand("../tmp", __DIR__)
    File.rm_rf! path
    File.mkdir_p! path
    File.cd! path, function
    File.rm_rf! path
  end
end
