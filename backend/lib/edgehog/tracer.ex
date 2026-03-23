#
# This file is part of Edgehog.
#
# Copyright 2026 SECO Mind Srl
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

defmodule Edgehog.Tracer do
  @moduledoc """
  Documentation for `Edgehog.Tracer`.
  """

  use Ash.Tracer

  require OpenTelemetry.Tracer

  OpentelemetryAsh

  @impl Ash.Tracer
  defdelegate start_span(type, name), to: OpentelemetryAsh

  @impl Ash.Tracer
  defdelegate stop_span, to: OpentelemetryAsh

  @impl Ash.Tracer
  defdelegate trace_type?(type), to: OpentelemetryAsh

  @impl Ash.Tracer
  defdelegate get_span_context, to: OpentelemetryAsh

  @impl Ash.Tracer
  defdelegate set_span_context(context), to: OpentelemetryAsh

  @impl Ash.Tracer
  def set_metadata(_type, metadata) do
    OpenTelemetry.Tracer.set_attributes(metadata)

    :ok
  end

  @impl Ash.Tracer
  defdelegate set_error(error, opts), to: OpentelemetryAsh
end
