Feature: Dashboard
  As a team member
  I want to see a real-time dashboard
  So that I have visibility into CI, deployments, and meetings

  Scenario: Dashboard shows CI stats
    Given there are 5 passed and 2 failed CI runs in the last 7 days
    When I visit the dashboard
    Then I should see "5" in the passed builds stat
    And I should see "2" in the failed builds stat

  Scenario: Dashboard supports Hebrew
    Given my preferred language is Hebrew
    When I visit the dashboard
    Then the page direction should be "rtl"
    And I should see "לוח מחוונים"

  Scenario: Dashboard shows upcoming meetings
    Given there is a meeting "Daily Standup" scheduled tomorrow
    When I visit the dashboard
    Then I should see "Daily Standup"
    And I should see a "Join" button
