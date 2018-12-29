defmodule KV.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    # Once the supervisor starts, it traverses the list of children
    # and invokes the child_spec/1 function on each module.
    # The child_spec/1 function returns the child specification which
    # describes: how to start the process; if the process is a worker or
    # a supervisor; if the process is temporary, transient or permanent;
    # and so on. The child_spec/1 function is automatically defined
    # when we `use Agent`, `use GenServer`, `use Supervisor`, etc. Give
    # it a try in the terminal with iex -S mix:
    #
    # iex(1)> KV.Registry.child_spec([])
    # %{
    #   id: KV.Registry,
    #   restart: :permanent,
    #   shutdown: 5000,
    #   start: {KV.Registry, :start_link, [[name: KV.Registry]]},
    #   type: :worker
    # }
    #
    # Children are started one by one, in the order they were defined,
    # using the information in the :start key in the child specification.
    # For the below, it will call KV.Registry.start_link([name: KV.Registry])

    children = [
      # tuple elements 1..n are passed as opts to start_link
      {KV.Registry, name: KV.Registry},
      # `DynamicSupervisor` is used when you want supervision but don't know
      # the exact children you will need ahead of time. No need to create our
      # own module that will `use DynamicSupervisor` because there are no
      # children to explicitly create
      {DynamicSupervisor, name: KV.BucketSupervisor, strategy: :one_for_one}
    ]

    # Since `KV.Registry` invokes `KV.BucketSupervisor`, then the `KV.BucketSupervisor`
    # must be started before `KV.Registry`. Otherwise, it may happen that the
    # registry attempts to reach the bucket supervisor before it has started.
    #
    # But if `KV.Registry` dies, all information linking bucket names to bucket
    # processes is lost -- so the `KV.BucketSupervisor` and all children must terminate
    # too, otherwise we would have orphan processes.
    #
    # In light of this observation, :one_for_one is not a good supervision strategy for
    # the root supervisor. The two other candidates are :one_for_all and :rest_for_one.
    # A supervisor using the :rest_for_one will kill and restart child processes which
    # were started after the crashed child. To have `KV.BucketSupervisor` terminate if
    # `KV.Registry terminates would require the bucket supervisor to be created after
    # the registry, which violates the ordering we established above.
    #
    # So our last option is to go all in and pick :one_for_all. The supervisor will
    # kill and restart all of its children processes whenever any one of them dies.
    #
    # This is a completely reasonable approach for our application, since the registry
    # can’t work without the bucket supervisor, and the bucket supervisor should
    # terminate without the registry.
    Supervisor.init(children, strategy: :one_for_all)
  end
end
