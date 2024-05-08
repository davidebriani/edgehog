#
# This file is part of Edgehog.
#
# Copyright 2021-2024 SECO Mind Srl
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

defmodule Edgehog.GeolocationMockCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Edgehog.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Mox
      import Edgehog.GeolocationMockCase
    end
  end

  import Mox

  setup :verify_on_exit!

  setup do
    Mox.stub_with(
      Edgehog.Geolocation.GeolocationProviderMock,
      Edgehog.Mocks.Geolocation.GeolocationProvider
    )

    Mox.stub_with(
      Edgehog.Geolocation.GeocodingProviderMock,
      Edgehog.Mocks.Geolocation.GeocodingProvider
    )

    Mox.defmock(Edgehog.Geolocation.GeolocationProviderMock,
      for: Edgehog.Geolocation.GeolocationProvider
    )

    Mox.defmock(Edgehog.Geolocation.GeocodingProviderMock,
      for: Edgehog.Geolocation.GeocodingProvider
    )

    :ok
  end
end
