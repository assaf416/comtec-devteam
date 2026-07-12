# features/customer_tickets.feature
Feature: Customer Support Tickets
  As a support agent or team member
  I want to manage customer support tickets
  So I can track and resolve customer issues

  Background:
    Given I am logged in as a developer
    And there is a customer named "Beta Client"

  @ticket_submit
  Scenario: Customer submits a new support ticket
    When I visit the customer's tickets page for "Beta Client"
    And I click "New Ticket"
    And I fill in "Title" with "Cannot install version 2.5"
    And I fill in "Message / Description" with "The installer fails at step 3 with error code 1603"
    And I select "high" for "priority"
    And I submit the form
    Then I should see "Cannot install version 2.5"
    And I should see "high" priority tag

  @ticket_resolve
  Scenario: Resolve a customer support ticket
    Given "Beta Client" has an open ticket titled "Login fails after update"
    When I view that customer ticket
    And I click "Mark Resolved"
    Then the ticket should be marked as resolved
    And I should see a resolved status tag

  @ticket_link_internal
  Scenario: Link customer ticket to internal ticket
    Given "Beta Client" has an open ticket titled "Feature request: dark mode"
    And there is a project called "Digital Internet Services"
    And that project has a ticket titled "Dark mode support"
    When I view the customer ticket "Feature request: dark mode"
    And I link it to the internal ticket "Dark mode support"
    Then I should see the internal ticket linked

  @ticket_assign
  Scenario: Assign a customer ticket to a team member
    Given "Beta Client" has an open ticket titled "Data export broken"
    When I edit that customer ticket
    And I assign it to a team member
    And I submit the form
    Then the ticket should be assigned to that team member

  @ticket_list_filter
  Scenario: Filter customer tickets by status
    Given "Beta Client" has 2 open tickets and 1 resolved ticket
    When I visit the customer's tickets page for "Beta Client"
    And I filter by "open" status
    Then I should see 2 tickets
    And I should not see resolved tickets
