Feature: Customer API workflow
  In order to protect business behavior
  As a delivery team
  We want BDD scenarios that run in CI

  Scenario: Create customer with valid data
    Given the API is available
    When I submit a customer request with name "Northwind" and email "qa@northwind.test"
    Then the API should respond with status code 201

  Scenario: Validation error for missing email
    Given the API is available
    When I submit a customer request with name "Northwind" and no email
    Then the API should respond with status code 400
