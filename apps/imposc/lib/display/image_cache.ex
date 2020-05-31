defmodule ImageCache do
  @moduledoc """
  Generates image file names on request and maintains a cache of image files.
  """

  defstruct directory: "images", size_limit: 1024 * 1024 * 512

  @type t :: %ImageCache{directory: binary(), size_limit: integer()}

  @doc """
  Ensures the cache specified in `:image_cache` is below the size limit and
  returns a new unique file name.
  """
  @spec offer_new_file(ImageCache.t(), binary()) :: {atom(), binary()}
  def offer_new_file(%ImageCache{} = image_cache, extension \\ "png") do
    # TODO: put in its own process
    reduce_cache(image_cache)
    new_file_name(image_cache, extension)
  end

  @doc """
  Returns a path for a new file in the cache specified in `:image_cache` with 
  an extension specified in `:extension`.
  """
  @spec new_file_name(ImageCache.t(), binary()) :: {atom(), binary()}
  def new_file_name(%ImageCache{} = image_cache, extension \\ "png") do
    with {:ok, directory} <- create_cache_dir(image_cache),
         do: unique_file_name(extension) |> (&Path.join(directory, &1)).() |> (&{:ok, &1}).()
  end

  @spec unique_file_name(binary()) :: binary()
  def unique_file_name(extension) do
    System.monotonic_time(:second)
    |> abs
    |> (&"#{&1}_#{System.unique_integer([:positive, :monotonic])}.#{extension}").()
  end

  @doc """

  """
  @spec create_cache_dir(%ImageCache{}) :: {atom(), binary()}
  def create_cache_dir(%ImageCache{} = image_cache) do
    # get absolute path
    image_cache
    |> cache_path
    |> (fn response ->
          with {:ok, dir_name} <- response,
               do:
                 dir_name
                 |> (fn dir_name ->
                       # check if it exists
                       if File.dir?(dir_name) do
                         {:ok, dir_name}
                       else
                         # if not, create directory
                         dir_name
                         |> File.mkdir()
                         |> (&with(:ok <- &1, do: {:ok, dir_name})).()
                       end
                     end).()
        end).()
  end

  @doc """
  Returns the absolute path to the cache directory.
  """
  @spec cache_path(%ImageCache{}) :: {atom(), binary()}
  def cache_path(%ImageCache{} = image_cache) do
    # get application path
    # TODO: need to do better than just cwd
    File.cwd()
    |> (fn cwd_reason ->
          with {:ok, path_name} <- cwd_reason,
               # create absolute path
               do: path_name |> Path.join(image_cache.directory) |> (&{:ok, &1}).()
        end).()

    # {:ok, Application.app_dir(:imposc, image_cache.directory)}
  end

  @spec reduce_cache(ImageCache.t()) :: integer()
  def reduce_cache(%ImageCache{} = image_cache) do
    with {:ok, directory_path} <- cache_path(image_cache),
         true <- File.dir?(directory_path) do
      cache_files(directory_path)
      |> (fn files ->
            size = files_size(files)

            decrement_cache_size(size, files, directory_path, image_cache.size_limit)
          end).()
    else
      # Not created yet
      {:error, _} -> 0
      false -> 0
    end
  end

  @spec decrement_cache_size(integer(), [{binary(), %File.Stat{}}], binary(), integer()) ::
          integer()
  defp decrement_cache_size(size, files, directory_path, size_limit)

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

  @spec cache_files(binary()) :: [{binary(), %File.Stat{}}]
  def cache_files(directory_path) do
    case directory_path |> File.ls() do
      {:ok, files} ->
        Enum.map(files, fn x -> Path.join(directory_path, x) end)
        |> Enum.map(fn x -> File.stat(x) |> (&{x, elem(&1, 1)}).() end)
        |> Enum.filter(fn x -> Map.fetch(elem(x, 1), :type) == {:ok, :regular} end)
        |> Enum.sort(&(Map.fetch!(elem(&1, 1), :mtime) <= Map.fetch!(elem(&2, 1), :mtime)))

      {:error, _reason} ->
        {:error, "Could not open image cache directory #{directory_path}"}
    end
  end

  @spec files_size([{binary(), %File.Stat{}}]) :: integer()
  defp files_size(files) do
    files
    |> Enum.map(fn x -> elem(x, 1) end)
    |> Enum.reduce(0, fn x, acc -> acc + Map.fetch!(x, :size) end)
  end

  @spec cache_size(binary()) :: integer()
  def cache_size(directory_path) do
    cache_files(directory_path) |> files_size
  end
end
