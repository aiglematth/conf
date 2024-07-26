def create_left_prompt [] {
    let status = if $env.LAST_EXIT_CODE == 0 { 
            echo $"(ansi blue)($env.LAST_EXIT_CODE)(ansi reset)" 
        } else { 
            echo $"(ansi red)($env.LAST_EXIT_CODE)(ansi reset)" 
        }
    echo $"(ansi purple)($env.USER)(ansi reset):[($status)]:($env.PWD)"
}
$env.PROMPT_COMMAND = { create_left_prompt }


def create_right_prompt [] {
    let time_segment = ([
        (date now | format date "%H:%M | %d %B %Y")
    ] | str join)

    echo $"(ansi red)($time_segment)(ansi reset)"
}
$env.PROMPT_COMMAND_RIGHT = { create_right_prompt }

$env.CARGO_HOME = ($env.HOME | path join .cargo)

$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
    ($nu.data-dir | path join 'completions') # default home for nushell completions
]

$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

$env.PATH = (
  $env.PATH
  | split row (char esep)
  | append /usr/local/bin
  | append ($env.CARGO_HOME | path join bin)
  | append ($env.HOME | path join .local bin)
  | uniq
)

source /home/aiglematth/.config/nushell/zellij.nu
source /home/aiglematth/.config/nushell/alias.nu