# before execute this tests, you sould start redis server on your host.

redlock_conf = [
  pool_size: 2,
  max_retry: 5,
  retry_interval_base: 300,
  retry_interval_max: 3000,
  reconnection_interval_base: 300,
  reconnection_interval_max: 3000,
  servers: [
    [host: "127.0.0.1", port: 6379, database: 5]
  ]
]

Supervisor.start_link(
  [{Redlock, redlock_conf}],
  strategy: :one_for_one,
  name: Redlock.TestSupervisor
)

ExUnit.start()
