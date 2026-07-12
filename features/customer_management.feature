# features/customer_management.feature
Feature: Customer Management
  As a team lead or project manager
  I want to manage customers in the system
  So I can track which customers use our software

  Background:
    Given I am logged in as a developer

  @customer_create
  Scenario: Create a new customer
    When I visit the customers list page
    And I click "New Customer"
    And I fill in "Name" with "Acme Corp"
    And I fill in "Email" with "contact@acme.com"
    And I fill in "Company" with "Acme Corporation"
    And I submit the form
    Then I should see "Acme Corp"
    And I should see "Customer was successfully created" or a success flash

  @customer_list
  Scenario: View customers list
    Given there are 3 active customers
    When I visit the customers list page
    Then I should see 3 customer rows in the table

  @customer_search
  Scenario: Search for a customer by name
    Given there is a customer named "GlobalTech Ltd"
    And there is a customer named "Local Services"
    When I visit the customers list page
    And I search for "Global"
    Then I should see "GlobalTech Ltd"
    And I should not see "Local Services"

  @customer_deactivate
  Scenario: Filter active customers only
    Given there is an active customer named "Active Co"
    And there is an inactive customer named "Closed Corp"
    When I visit the customers list page and filter active only
    Then I should see "Active Co"
    And I should not see "Closed Corp"

  @customer_edit
  Scenario: Edit an existing customer
    Given there is a customer named "Old Name Corp"
    When I edit that customer and change the name to "New Name Corp"
    Then I should see "New Name Corp"
    And I should see "Customer was successfully updated" or a success flash
