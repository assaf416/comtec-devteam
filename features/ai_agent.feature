Feature: AI Agent services backed by the local on-prem LLM
  As a development team running an on-prem Ollama machine
  I want AI-assisted reviews and analyses inside DevTeam Hub
  So the team gets fast feedback without sending code to a SaaS provider

  Background:
    Given I am logged in as a team lead
    And the local AI model is available

  Scenario: Verify story telling — a well-written ticket passes
    Given an AI project "Acme" with a ticket "Add SSO login"
    And the AI model will return verdict "pass"
    When I run the AI readiness check on that ticket
    Then I should see "Pass"
    And an AI review of kind "ticket_quality" should exist

  Scenario: Verify story telling — a poor ticket is reassigned to its owner
    Given an AI project "Acme" with a ticket "fix stuff" owned by "Olive Owner" and assigned to "Adam Assignee"
    And the AI model will return verdict "needs_work"
    When I run the AI readiness check on that ticket
    Then the ticket should be reassigned to its owner
    And an AI review of kind "ticket_quality" should exist

  Scenario: Code review of a diff across our stack
    Given an AI project "Acme" with a ticket "Add SSO login"
    When I submit a code review for that ticket in "go"
    Then I should see the AI review result
    And an AI review of kind "code_review" should exist

  Scenario: Review cucumber tests and suggest missing coverage
    Given an AI project "Acme" with a ticket "Add SSO login"
    When I submit a cucumber test review for that ticket
    Then I should see the AI review result
    And an AI review of kind "test_review" should exist

  Scenario: Suggest a solution for a ticket
    Given an AI project "Acme" with a ticket "Add SSO login"
    When I ask the AI to suggest a solution for that ticket
    Then I should see the AI review result
    And an AI review of kind "solution_suggestion" should exist

  Scenario: Track estimation vs actual delivery time for a project
    Given an AI project "Acme" with a ticket "Add SSO login"
    And that project has a ticket estimated 8 hours that actually took "10h"
    When I run AI estimation analysis on that project
    Then I should see the AI review result
    And an AI review of kind "estimation_analysis" should exist

  Scenario: The AI Reports dashboard lists recent runs
    Given an AI project "Acme" with a ticket "Add SSO login"
    And the AI model will return verdict "pass"
    When I run the AI readiness check on that ticket
    And I visit the AI reports page
    Then I should see "Ticket quality"

  Scenario: Graceful handling when the LLM machine is offline
    Given an AI project "Acme" with a ticket "Add SSO login"
    And the local AI model is offline
    When I ask the AI to suggest a solution for that ticket
    Then the AI review should be marked failed
    And an AI review of kind "solution_suggestion" should exist
