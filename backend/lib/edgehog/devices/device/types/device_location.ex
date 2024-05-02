#
# This file is part of Edgehog.
#
# Copyright 2024 SECO Mind Srl
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0
#

defmodule Edgehog.Devices.Device.Types.DeviceLocation do
  @enforce_keys [
    :latitude,
    :longitude,
    :accuracy,
    :altitude,
    :altitude_accuracy,
    :heading,
    :speed,
    :timestamp,
    :address
  ]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          latitude: float(),
          longitude: float(),
          accuracy: float() | nil,
          altitude: float() | nil,
          altitude_accuracy: float() | nil,
          heading: float() | nil,
          speed: float() | nil,
          timestamp: DateTime.t(),
          address: String.t() | nil
        }

  use Ash.Type.NewType,
    subtype_of: :struct,
    constraints: [instance_of: __MODULE__]

  use AshGraphql.Type

  @impl true
  def graphql_type(_), do: :device_location
end
