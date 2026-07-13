Feature: Tickets sourced from GitHub issues
  As a developer
  I want the project's tickets to mirror its GitHub issues
  So that GitHub stays the single source of truth for work items

  Background:
    Given I am logged in as a developer
    And there is a GitHub-backed project called "TDI2"

  Scenario: Syncing imports GitHub issues as tickets
    Given the project's GitHub repo has issues:
      | number | title         | state | labels |
      | 1      | Fix login bug | open  | bug    |
      | 2      | Add dark mode | open  |        |
    When I sync the project's GitHub issues
    Then I should see "Fix login bug" on the project tickets page
    And I should see "Add dark mode" on the project tickets page
    And the ticket "Fix login bug" should be a bug_fix

  Scenario: Tickets are read-only and link back to GitHub
    Given the project's GitHub repo has issues:
      | number | title         | state | labels |
      | 7      | Fix login bug | open  |        |
    When I sync the project's GitHub issues
    And I open the ticket "Fix login bug"
    Then I should see a link to the GitHub issue
    And there should be no "New Ticket" button

  Scenario: Re-syncing updates in place without duplicating
    Given the project's GitHub repo has issues:
      | number | title         | state  | labels |
      | 5      | Fix login bug | open   |        |
    When I sync the project's GitHub issues
    And the GitHub issue "5" is closed and retitled "Fix login bug (done)"
    And I sync the project's GitHub issues
    Then the project should have exactly 1 ticket
    And the ticket for issue "5" should be closed
