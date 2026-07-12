Feature: Projects command
  As a developer
  I want to list available projects
  So I can see what is configured on the server

  Background:
    Given the API server is running
    And I am authenticated

  Scenario: List projects
    Given the server has projects:
      | id | name      | repo_url                          |
      | 1  | devteam   | https://git.example.com/devteam   |
      | 2  | api-core  | https://git.example.com/api-core  |
    When I run "devteam projects"
    Then the output contains "devteam"
    And the output contains "api-core"
    And the exit code is 0

  Scenario: Empty project list
    Given the server has no projects
    When I run "devteam projects"
    Then the output contains "no projects"
    And the exit code is 0

  Scenario: Not authenticated
    Given I am not authenticated
    When I run "devteam projects"
    Then the exit code is 1
