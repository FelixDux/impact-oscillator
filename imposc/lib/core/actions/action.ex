
defmodule Action do

  @callback execute(map()) :: nil | number() | {atom(), iodata()} | struct()

end
