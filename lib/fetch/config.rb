module Fetch
  Config = Struct.new(
    :connection_max_idle_time,
    :on_connection_create,
    :json_parse_options
  )
end
