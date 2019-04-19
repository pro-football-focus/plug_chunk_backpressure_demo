defmodule ChunkBackpressureDemoWeb.DemoController do
  use ChunkBackpressureDemoWeb, :controller

  require WaitForIt

  def flood(conn, _params) do
    Enum.reduce_while(csv_stream(300_000), send_chunked(conn, 200), fn chunk, conn ->
      send_chunk(conn, chunk)
    end)
  end

  def backpressure(conn, _params) do
    {Plug.Cowboy.Conn, %{pid: stream_pid}} = conn.adapter

    Enum.reduce_while(csv_stream(300_000), send_chunked(conn, 200), fn chunk, conn ->
      WaitForIt.case_wait Process.info(stream_pid, :message_queue_len), frequency: 10, timeout: 60_000 do
        {:message_queue_len, len} when len < 500 ->
          send_chunk(conn, chunk)
      else
        len ->
          raise "Timeout while sending stream response. [message_queue_len: #{len}]"
      end
    end)
  end

  defp csv_stream(count) do
    rows =
      for i <- 1..10 do
        row = to_string(i) |> String.duplicate(100) |> List.duplicate(10)
        Enum.join(row, ",") <> "\n"
      end

    stream = Stream.cycle(rows) |> Stream.take(count)
    header_row = "1,2,3,4,5,6,7,8,9,10\n"
    Stream.concat([header_row], stream)
  end

  defp send_chunk(conn, chunk) do
    case Plug.Conn.chunk(conn, chunk) do
      {:ok, conn} -> {:cont, conn}
      {:error, :closed} -> {:halt, conn}
    end
  end
end
