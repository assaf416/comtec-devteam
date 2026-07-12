Feature: Ticket Management
  As a developer
  I want to manage tickets
  So that work is tracked and branches are created automatically

  Background:
    Given I am logged in as a developer
    And there is a project called "TDI2"

  Scenario: Create a new ticket
    Given I am on the project tickets page for "TDI2"
    When I click "New Ticket"
    And I fill in "Title" with "Fix login bug"
    And I select "High" for "Priority"
    And I click "Create Ticket"
    Then I should see "Ticket created successfully"
    And I should see "Fix login bug"

  Scenario: Assigning a ticket creates a branch
    Given there is an unassigned ticket "Fix login bug" in project "TDI2"
    When I assign the ticket to "john@example.com"
    Then a branch "ticket/1-fix-login-bug" should be created in Gitea
    And the ticket should show branch "ticket/1-fix-login-bug"

  Scenario: Ticket shows latest CI status
    Given there is a ticket "Fix login bug" with a failed CI run
    When I visit the ticket page
    Then I should see CI status "Failed"
    And an email should be sent to the assignee
