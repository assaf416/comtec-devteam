Feature: Customer workflow in Bun service
  As a product owner
  I want customer operations in Gherkin
  So business behavior is always executable

  Background:
    Given the customer service is running

  Scenario: Create customer succeeds
    When I call POST /customers with payload:
      | name  | Bun Holdings |
      | email | qa@bun.test |
    Then the response status is 201
    And the response contains customer name "Bun Holdings"

  Scenario: Duplicate email is blocked
    Given a customer exists with email "qa@bun.test"
    When I call POST /customers with payload:
      | name  | Duplicate |
      | email | qa@bun.test |
    Then the response status is 409
    And the response contains error code "CUSTOMER_EMAIL_CONFLICT"
