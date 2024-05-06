defmodule Opts do
  @moduledoc """
  Documentation for `Opts`.
  """

  @compile :inline_list_funcs

  @doc """
  Reduce a a subset of keys from a `t:Keyword.t`.

  Like `Enum.reduce/3` but iterates over only keys from `keys`
  and in the order they are given.

  Note the argument order is different from `Enum.reduce/3`.
  The accumulator is the first argument, such that
  it can be used in a pipeline over some accumulator
  in a "builder" pattern.

  ## Example

      iex> opts = [a: 1, c: 3, b: 2]
      iex> Opts.reduce(0, opts, [:b, :c], fn {_k, v}, acc -> acc + v end)
      5
  """
  def reduce(acc, opts, keys, fun) do
    :lists.foldl(fun, acc, take(opts, keys))
  end

  @doc """
  Apply a function to the acc and a value of a key in the opts.
  If the key is not present, the acc is returned as-is.

  This function is useful for conditionally building some
  accumlator based on optional values.

  A common use-case is to build an Ecto query based on options
  like `offset`, `limit`, `offset`, `where`'s etc.

  This is similar to `Enum.reduce/3` over the options with
  the query as the accumulator, but with the ability to
  determine order and inject other actions in the middle of
  the pipeline.

  ## Examples

      iex> opts = [a: 1, c: 3]
      iex> acc = 0
      iex> acc
      iex> |> Opts.apply(opts, :a, &+/2)
      iex> |> Opts.apply(opts, :b, &+/2)
      iex> # example of modification in the middle of the pipeline:
      iex> |> Function.identity()
      iex> |> Opts.apply(opts, :c, &+/2)
      4
  """
  def apply(acc, opts, key, fun) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> fun.(acc, value)
      :error -> acc
    end
  end

  @doc """
  Apply a function to the acc and a value of a key in the opts.
  If the key is not present, the default value is used.

  Works like `Opts.apply/4`, but instead of skipping the
  application when `key` is not found in `opts`, it applies
  the function with the default value instead.

  ## Examples

      iex> opts = [a: 1, c: 3]
      iex> 0
      iex> |> Opts.apply(opts, :a, 100, &+/2)
      iex> |> Opts.apply(opts, :b, 100, &+/2)
      iex> |> Opts.apply(opts, :c, 100, &+/2)
      104
  """
  def apply(acc, opts, key, default, fun) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> fun.(acc, value)
      :error -> fun.(acc, default)
    end
  end

  @doc """
  Take the keys from the `t:Keyword.t` first argument.
  The order of the keys in the resulting keyword list
  is the same as the order of the keys in the second argument.

  Duplicates are preserved.

  ## Examples

      iex> Opts.take([a: 1, c: 3, b: 2], [:b, :c])
      [b: 2, c: 3]

      iex> Opts.take([a: 1, c: 3, b: 2], [:c, :b])
      [c: 3, b: 2]
  """
  @spec take(Keyword.t(), [atom()]) :: Keyword.t()
  def take(opts, keys) do
    {take, _drop} = split(opts, keys)
    take
  end

  @doc """
  Split a `t:Keyword.t` like `Keyword.split/2`

  In addition to the guarantees of `Keyword.split/2`,
  it also guarantees that the order of the keys of the keyword list
  in the first tuple element is the same as the order of the specified keys,
  and that the order of the keys of the keyword list in the second tuple element
  is maintained from the original keyword list.

  Duplicates are preserved.

  ## Examples

      iex> Opts.split([a: 1, c: 3, b: 2], [:b, :c])
      {[b: 2, c: 3], [a: 1]}

      iex> Opts.split([a: 1, c: 3, b: 2], [:c, :b])
      {[c: 3, b: 2], [a: 1]}

      iex> Opts.split([a: 1, c: 3, b: 2], [:a])
      {[a: 1], [c: 3, b: 2]}
  """
  @spec split(Keyword.t(), [atom()]) :: {Keyword.t(), Keyword.t()}
  def split(keywords, keys) when is_list(keywords) and is_list(keys) do
    splitter = fn {k, v}, {take, drop} ->
      case k in keys do
        true -> {[{k, v} | take], drop}
        false -> {take, [{k, v} | drop]}
      end
    end

    {take, drop} = :lists.foldl(splitter, {[], []}, keywords)

    # Sort the take list by the order of the keys
    sorter = fn {k1, _}, {k2, _} ->
      index_of(keys, k1) < index_of(keys, k2)
    end

    {:lists.sort(sorter, take), :lists.reverse(drop)}
  end

  # returns the index of needle in heystack (or nil if not found)
  defp index_of(heystack, needle, index \\ 0)
  defp index_of([], _needle, _index), do: nil
  defp index_of([needle | _rest], needle, index), do: index
  defp index_of([_ | rest], needle, index), do: index_of(rest, needle, index + 1)
end
