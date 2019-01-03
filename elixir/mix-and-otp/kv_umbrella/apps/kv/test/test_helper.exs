# Create an exclusion list. if the test run was started with
#
#   $ mix test
#
# Then the exclusions will be made of all tests with @tag :distributed
# Whereas if the following was used instead
#
#   $ elixir --sname foo -S mix test
#
# Then the exclusions list will be empty.
# Alternatively, you could also have done
#
#   $ mix test --include distributed
#
# To include the tests with @tag :distributed regardless of the value set
# in this file. You can also use --exclude to exclude particular tags from
# the command line. Finally, --only can be used to run only tests with a
# particular tag:
#
#   $ elixir --sname foo -S mix test --only distributed
exclude =
  if Node.alive?, do: [], else: [distributed: true]

ExUnit.start(exclude: exclude)
