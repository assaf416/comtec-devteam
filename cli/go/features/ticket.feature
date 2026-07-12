Feature: Ticket commands
  As a developer
  I want to manage tickets from the CLI
  So I can track and update work without leaving the terminal

  Background:
    Given the API server is running
    And I am authenticated

  Scenario: Show ticket details
    Given a ticket with id 42, title "Fix login bug", status "open"
    When I run "devteam ticket 42 show"
    Then the output contains "T-42"
    And the output contains "Fix login bug"
    And the output contains "open"
    And the exit code is 0

  Scenario: Show ticket with a branch
    Given a ticket with id 10, title "Add search", status "in_progress", branch "feature/t-10-add-search"
    When I run "devteam ticket 10 show"
    Then the output contains "feature/t-10-add-search"
    And the exit code is 0

  Scenario: Start work on a ticket
    Given a ticket with id 42, title "Fix login bug", status "open"
    When I run "devteam ticket 42 start"
    Then the output contains "in_progress"
    And the exit code is 0

  Scenario: Mark a ticket as done
    Given a ticket with id 42, title "Fix login bug", status "in_progress"
    When I run "devteam ticket 42 done"
    Then the output contains "done"
    And the exit code is 0

  Scenario: Set an explicit ticket status
    Given a ticket with id 42, title "Fix login bug", status "open"
    When I run "devteam ticket 42 status in_review"
    Then the output contains "in_review"
    And the exit code is 0

  Scenario: Stop a ticket session
    Given a ticket with id 42, title "Fix login bug", status "in_progress"
    When I run "devteam ticket 42 stop"
    Then the output contains "paused"
    And the exit code is 0

  Scenario: Show ticket help
    When I run "devteam ticket --help"
    Then the output contains "USAGE"
    And the output contains "devteam ticket"
    And the exit code is 0

  Scenario: Non-numeric ticket ID fails gracefully
    When I run "devteam ticket abc show"
    Then the exit code is 2

  Scenario: Unknown ticket action fails gracefully
    Given a ticket with id 42, title "Fix login bug", status "open"
    When I run "devteam ticket 42 fly"
    Then the exit code is 2
