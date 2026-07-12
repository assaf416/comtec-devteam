Feature: CI Dashboard
  As a team lead
  I want to see all CI runs for a project
  So I can track build health

  Scenario: View CI dashboard for a project
    Given there is a project "Digital Services" with 3 CI runs
    When I visit the CI dashboard for "Digital Services"
    Then I should see 3 build rows
    And each row shows build number, branch, and status

  Scenario: Failed builds are highlighted
    Given there is a failed CI run for branch "main"
    When I view the CI dashboard
    Then the failed build row should have a danger background

  Scenario: CI run links to test results
    Given a CI run with 10 passed and 2 failed tests
    When I view the CI dashboard
    Then I should see "10✓" and "2✗"
