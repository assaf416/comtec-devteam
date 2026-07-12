Feature: Customer lifecycle
  As a support engineer
  I want business rules captured in BDD
  So the Rails API behavior is verifiable end to end

  Background:
    Given an authenticated API client

  Scenario: Create a customer with a valid payload
    When I send a POST request to "/api/v1/customers" with:
      | name  | Acme Corp |
      | email | ops@acme.test |
    Then the response status should be 201
    And the JSON response should include "id"
    And the JSON response should include "name" = "Acme Corp"

  Scenario: Reject customer creation without email
    When I send a POST request to "/api/v1/customers" with:
      | name | Missing Email Inc |
    Then the response status should be 422
    And the JSON response should include validation error for "email"
