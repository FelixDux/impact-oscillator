defmodule ImageCache do
  @moduledoc """
  Generates image file names on request and maintains a cache of image files.
  """

  defstruct directory: "images", size_limit: 1024 * 1024 * 512

  @doc """
  Ensures the cache specified in `:image_cache` is below the size limit and
  returns a new unique file name.
  """
  def offer_new_file(%ImageCache{} = image_cache, extension \\ "png") do
    # TODO: put in its own process
    reduce_cache(image_cache)
    new_file_name(image_cache, extension)
  end

  @doc """
  Returns a path for a new file in the cache specified in `:image_cache` with 
  an extension specified in `:extension`.
  """
  @spec new_file_name(ImageCache, iodata()) :: {atom(), atom() | iodata()}
  def new_file_name(%ImageCache{} = image_cache, extension \\ "png") do
    case create_cache_dir(image_cache) do
      {:ok, directory} ->
        unique_file_name(extension) |> (&Path.join(directory, &1)).() |> (&{:ok, &1}).()

      {:error, reason} ->
        {:error, reason}
    end
  end

  def unique_file_name(extension) do
    System.monotonic_time(:second)
    |> abs
    |> (&"#{&1}_#{System.unique_integer([:positive, :monotonic])}.#{extension}").()
  end

  @doc """

  """
  def create_cache_dir(%ImageCache{} = image_cache) do
    # get absolute path
    image_cache
    |> cache_path
    |> (fn response ->
          case response do
            {:ok, dir_name} ->
              # check if it exists
              if File.dir?(dir_name) do
                {:ok, dir_name}
              else
                # if not, create directory
                dir_name
                |> File.mkdir()
                |> (&(case &1 do
                        :ok -> {:ok, dir_name}
                        {:error, reason} -> {:error, reason}
                      end)).()
              end

            {:error, reason} ->
              {:error, reason}
          end
        end).()
  end

  @doc """
  Returns the absolute path to the cache directory.
  """
  def cache_path(%ImageCache{} = image_cache) do
    # get application path
    # TODO: need to do better than just cwd
    File.cwd()
    |> (fn cwd_reason ->
          case cwd_reason do
            # create absolute path
            {:ok, path_name} -> path_name |> Path.join(image_cache.directory) |> (&{:ok, &1}).()
            {:error, _} -> cwd_reason
          end
        end).()
  end

  def reduce_cache(%ImageCache{} = image_cache) do
    {:ok, directory_path} = cache_path(image_cache)

    files = cache_files(directory_path)

    size = files_size(files)

    decrement_cache_size(size, files, directory_path, image_cache.size_limit)
  end

  defp decrement_cache_size(size, _files, _directory_path, size_limit) when size <= size_limit do
    size
  end

  defp decrement_cache_size(size, files, directory_path, size_limit) do
    [{head_path, head_stat} | tail] = files

    new_size = size - head_stat[:size]

    # TODO: handle error conditions
    File.rm!(head_path)

    decrement_cache_size(new_size, tail, directory_path, size_limit)
  end

  def cache_files(directory_path) do
    {:ok, files} = directory_path |> File.ls()

    Enum.map(files, fn x -> Path.join(directory_path, x) end)
    |> Enum.map(fn x -> File.stat(x) |> (&{x, elem(&1, 1)}).() end)
    |> Enum.filter(fn x -> Map.fetch(elem(x, 1), :type) == {:ok, :regular} end)
    |> Enum.sort(&(Map.fetch!(elem(&1, 1), :mtime) <= Map.fetch!(elem(&2, 1), :mtime)))
  end

  defp files_size(files) do
    files
    |> Enum.map(fn x -> elem(x, 1) end)
    |> Enum.reduce(0, fn x, acc -> acc + Map.fetch!(x, :size) end)
  end

  def cache_size(directory_path) do
    cache_files(directory_path) |> files_size

    # Enum.map(fn x -> elem(x, 1) end) |> Enum.reduce(0, fn x, acc -> acc + Map.fetch!(x, :size) end)
  end
end
