Feature: Config command
  As a developer
  I want to view and update CLI configuration
  So I can connect to the right server

  Scenario: Show config prints the config file path
    Given a config with server "https://hub.example.com" and token "abc123"
    When I run "devteam config"
    Then the output contains "hub.example.com"
    And the exit code is 0

  Scenario: config path prints the config file location
    When I run "devteam config path"
    Then the output contains "devteam"
    And the output contains "config.yml"
    And the exit code is 0

  Scenario: Set a config key
    When I run "devteam config set server https://new.example.com"
    Then the exit code is 0

  Scenario: Unknown config subcommand fails
    When I run "devteam config foobar"
    Then the exit code is 2
