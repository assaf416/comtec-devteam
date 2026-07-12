Feature: Log Viewer
  As a developer running multiple on-prem applications
  I want a readable, highlighted view of the central logs
  So I can watch activity and spot errors and exceptions quickly

  Background:
    Given I am logged in as a team lead

  Scenario: View the log viewer with filters
    When I visit the log viewer
    Then I should see "Log Viewer"
    And I should see the log filters
    And I should see "GET /tickets 200 in 32ms"

  Scenario: Errors and exceptions are highlighted
    When I visit the log viewer
    Then error lines should be highlighted
    And exception lines should be highlighted
    And the error count should be shown

  Scenario: Filter the logs by level
    When I view the logs filtered by level "error"
    Then error lines should be highlighted
    And I should not see "GET /tickets 200 in 32ms"

  Scenario: The live tail endpoint returns rendered log lines
    When I open the live log tail
    Then I should see "Payment gateway timeout after 30s"

  Scenario: Empty state when there are no matching entries
    Given the log store has no entries
    When I visit the log viewer
    Then I should see "No log entries for the selected filters."

  Scenario: Graceful handling when Loki is unreachable
    Given the log store is unreachable
    When I visit the log viewer
    Then I should see "Loki unreachable"
