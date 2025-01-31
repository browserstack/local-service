# ToDo -> apply the implementaion in the correct way
IS_APP_AUTOMATE = true
APP_AUTOMATE = "app_automate"
AUTOMATE = "automate"

LOCAL_CONSTANTS = {
  'json_version' => 1,
  'api_version' => 1,
  'disconnects' => {
    1 => 'Disconnected using Local API',
    2 => 'User pressed Control + C',
    3 => 'Possibly killed forcefully by user',
    4 => 'Disconnected because of possible network issues'
  }
}

BINARY_ANALYTIC_POSTBACK_TIME = 60 * 15
BINARY_ANALYTIC_INIT_POSTBACK = true

NODE_CMD_LINE_TUNNEL_VERSION = 7.4
CMD_LINE_TUNNEL_VERSION = 16.0