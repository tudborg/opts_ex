defmodule Opts do
  @moduledoc """
  `Opts` is a utility module to increase ergonomics when working with
  options in keyword lists given to your functions.
  """
  @compile :inline_list_funcs

  defmodule OptsError do
    defexception [:message, :keys]
  end

  @doc """
  Apply defaults to a `t:Keyword.t`.
  This is identical to `Keyword.merge/2` but in reverse argument order
  such that the subject is the opts.

  ## Examples

      iex> opts = [a: 1, c: 3]
      iex> defaults = [a: 0, b: 2]
      iex> Opts.defaults(opts, defaults)
      [b: 2, a: 1, c: 3]
  """
  @spec defaults(Keyword.t(), Keyword.t()) :: Keyword.t()
  def defaults(opts, defaults) do
    Keyword.merge(defaults, opts)
  end

  @doc """
  Map over a list of options.

  This is identical to `Enum.map/2`, but will only work with list as the enumerable argument.

  ## Examples

      iex> opts = [a: 1, c: 3, b: 2]
      iex> Opts.map(opts, fn {k, v} -> {k, v * 2} end)
      [a: 2, c: 6, b: 4]
  """
  @spec map(Keyword.t(), ({atom(), any()} -> {atom(), any()})) :: Keyword.t()
  def map(opts, fun) when is_function(fun, 1) do
    :lists.map(fun, opts)
  end

  @doc """
  Reduce a list of options into an accumulator.

  This is identical to `Enum.reduce/3`,
  but will only work with list as the enumerable argument.

  ## Examples

      iex> opts = [a: 1, c: 3, b: 2]
      iex> Opts.reduce(opts, 0, fn {_k, v}, acc -> acc + v end)
      6
  """
  @spec reduce(Keyword.t(), any(), (tuple(), any() -> any())) :: any()
  def reduce(opts, acc, fun) when is_function(fun, 2) do
    :lists.foldl(fun, acc, opts)
  end

  @doc """
  Reduce into an accumulator, a `t:Keyword.t`.

  Like `Enum.reduce/3`, but the accumulator is given as the first argument.
  The accumulator is the first argument, such that
  it can be used in a pipeline over some accumulator
  in a "builder" pattern, and can be applied in a pipeline
  again and again, processing the same accumulator (e.g. building a query, etc.)

  ## Examples

      iex> opts = [a: 1, c: 3, b: 2]
      iex> Opts.rereduce(0, opts, fn {_k, v}, acc -> acc + v end)
      6
  """
  @spec rereduce(any(), Keyword.t(), (tuple(), any() -> any())) :: any()
  def rereduce(acc, opts, fun) when is_function(fun, 2) do
    :lists.foldl(fun, acc, opts)
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
      {:ok, value} -> fun.(value, acc)
      :error -> acc
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
  Take the keys from the `t:Keyword.t` first argument.

  Like `Opts.take/2`, but raises if options exist that are
  not present in the list of keys.

  ## Examples

      iex> Opts.take!([a: 1, b: 2], [:a, :b])
      [a: 1, b: 2]

      iex> Opts.take!([a: 1, b: 2], [:a, :b, :c])
      [a: 1, b: 2]

      iex> Opts.take!([a: 1, b: 2], [:a])
      ** (Opts.OptsError) Unknown keys: [:b]

  """
  @spec take!(Keyword.t(), [atom()]) :: Keyword.t() | no_return()
  def take!(opts, keys) do
    case Keyword.split(opts, keys) do
      {take, []} ->
        take

      {_take, drop} ->
        keys = Keyword.keys(drop)
        raise OptsError, message: "Unknown keys: #{inspect(keys)}", keys: keys
    end
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

  # returns the index of needle in heystack
  defp index_of(heystack, needle, index \\ 0)
  defp index_of([needle | _rest], needle, index), do: index
  defp index_of([_ | rest], needle, index), do: index_of(rest, needle, index + 1)
end
