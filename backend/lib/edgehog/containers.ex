defmodule Edgehog.Containers do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Edgehog.Containers.ReleaseContainers
  end
end
