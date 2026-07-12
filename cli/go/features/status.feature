Feature: Status command
  As a developer
  I want to see the status of my current folder
  So I have a quick overview of where I am

  Scenario: Status shows the current folder
    When I run "devteam status"
    Then the output contains "folder"
    And the exit code is 0

  Scenario: Status shows not-logged-in tip when no credentials
    Given I am not authenticated
    When I run "devteam status"
    Then the output contains "not logged in"
    And the exit code is 0
