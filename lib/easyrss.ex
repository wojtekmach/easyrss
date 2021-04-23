defmodule EasyRSS do
  defmodule Feed do
    defstruct [:id, :updated, :title, :subtitle, links: [], entries: []]
  end

  defmodule Entry do
    defstruct [:id, :updated, :title, :summary, :content, :author, links: []]
  end

  def parse!(string) do
    {"feed", _, feed} = EasyXML.parse!(string)
    parse_feed(feed, %Feed{})
  end

  defp parse_feed([{field, value} | rest], acc) when field in ~w(id title subtitle) do
    atom_field = String.to_atom(field)
    parse_feed(rest, Map.replace!(acc, atom_field, value))
  end

  defp parse_feed([{"link", link, []} | rest], acc) do
    parse_feed(rest, update_in(acc.links, &[link | &1]))
  end

  defp parse_feed([{"updated", updated} | rest], acc) do
    {:ok, datetime, 0} = DateTime.from_iso8601(updated)
    parse_feed(rest, %{acc | updated: datetime})
  end

  defp parse_feed([{"entry", entry} | rest], acc) do
    parse_feed(rest, update_in(acc.entries, &[entry | &1]))
  end

  defp parse_feed([], acc) do
    %{acc | links: Enum.reverse(acc.links), entries: parse_entries(acc.entries, [])}
  end

  defp parse_entries([entry | rest], acc) do
    parse_entries(rest, [parse_entry(entry) | acc])
  end

  defp parse_entries([], acc) do
    acc
  end

  defp parse_entry(entry) do
    parse_entry(entry, %Entry{})
  end

  defp parse_entry([{field, value} | rest], acc) when field in ~w(id title summary author) do
    atom_field = String.to_atom(field)
    parse_entry(rest, Map.replace!(acc, atom_field, value))
  end

  defp parse_entry([{"link", link, []} | rest], acc) do
    parse_entry(rest, update_in(acc.links, &[link | &1]))
  end

  defp parse_entry([{"updated", updated} | rest], acc) do
    {:ok, datetime, 0} = DateTime.from_iso8601(updated)
    parse_entry(rest, %{acc | updated: datetime})
  end

  defp parse_entry([{"content", _, content} | rest], acc) do
    parse_entry(rest, %{acc | content: content})
  end

  defp parse_entry([], acc) do
    update_in(acc.links, &Enum.reverse/1)
  end
end
