
defmodule Action do

  @callback execute(map()) :: nil | number() | {atom(), iodata()} | struct()

  @callback requirements() :: map()

end
