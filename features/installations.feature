# features/installations.feature
Feature: Installation Tracking
  As a support engineer
  I want to track software installations at customer sites
  So I know what version each customer is running

  Background:
    Given I am logged in as a developer
    And there is a customer named "Gamma Industries"

  @installation_track
  Scenario: Track a new software installation
    When I visit the installations page for "Gamma Industries"
    And I click "Track New Installation"
    And I fill in "Software / Product Name" with "TDI2 Server"
    And I fill in "Version" with "3.1.0"
    And I select "production" for "Environment"
    And I submit the form
    Then I should see "TDI2 Server"
    And I should see version "3.1.0"

  @installation_update
  Scenario: Update installation version after upgrade
    Given "Gamma Industries" has an installation of "Print Server" version "1.0.0" in production
    When I edit that installation and change the version to "1.1.0"
    And I submit the form
    Then I should see version "1.1.0"
    And the old version should be marked as outdated

  @installation_auto_outdated
  Scenario: New active installation marks previous one as outdated
    Given "Gamma Industries" has an active installation of "TDI2" version "2.0"
    When I create a new active installation of "TDI2" version "3.0" for "Gamma Industries"
    Then the "2.0" installation should be marked as outdated
    And the "3.0" installation should be active

  @installation_filter_env
  Scenario: Filter installations by environment
    Given "Gamma Industries" has a production installation of "Print Server"
    And "Gamma Industries" has a staging installation of "Print Server"
    When I filter installations by "production" environment
    Then I should see the production installation
    And I should not see the staging installation

  @installation_link_deployment
  Scenario: Link an installation to a deployment record
    Given there is a project called "TDI2"
    And there is a deployment for that project
    And "Gamma Industries" is a customer
    When I track a new installation for "Gamma Industries" linked to that deployment
    Then the installation should show the deployment reference
