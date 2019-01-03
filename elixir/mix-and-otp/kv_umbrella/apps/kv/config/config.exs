# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :kv, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:kv, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

config :logger, :handle_otp_reports, true
config :logger, :handle_sasl_reports, true

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"


# The mix run command also accepts a --config flag, which allows configuration files
# to be given on demand. This could be used to start different nodes, each with its
#  own specific configuration (for example, different routing tables).
#
# App-by-app configuration and the fact that we have built our software as an umbrella
# application gives us plenty of options when deploying the software. We can:
#
#   > deploy the umbrella application to a node that will work as both TCP server and
#     key-value storage
#
#   > deploy the :kv_server application to work only as a TCP server as long as the
#     routing table points only to other nodes
#
#   > deploy only the :kv application when we want a node to work only as storage (no
#     TCP access)

config :kv, :routing_table, [{?a..?m, :foo@scorpio}, {?n..?z, :bar@scorpio}]
