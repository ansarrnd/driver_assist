Feature: Driver schedule

  Scenario: Complete onboarding once
    Given the app is freshly installed
    When the user finishes the onboarding carousel
    Then onboarding does not appear on next cold start
    And the schedule screen is shown

  Scenario: Empty schedule
    Given there are no drive entries
    When the user opens the schedule
    Then an empty state with a call to add a drive is visible

  Scenario: Seed data appears after first load
    Given Firestore collection drive_entries is empty
    When the repository loads for the first time
    Then sample drives are written
    And the schedule lists them ordered by dateTime ascending

  Scenario: Filter by type
    Given drives of type trip and ticket exist
    When the user selects the Trips tab
    Then only trip drives are listed
    When the user selects the Tickets tab
    Then only ticket drives are listed

  Scenario: Add a drive and see it on the schedule
    Given the user is on the add drive form
    When they submit valid customer, route, datetime, type, and offset
    Then the drive is persisted
    And an alarm is scheduled using the returned id
    And the schedule shows the new drive

  Scenario: Edit a drive
    Given an existing drive on the schedule
    When the user updates destination and saves
    Then the schedule reflects the new destination
    And the alarm is rescheduled

  Scenario: Delete a drive
    Given an existing drive on the schedule
    When the user confirms delete
    Then the drive is removed from the list
    And its alarm is cancelled

  Scenario: Change theme pack
    Given the user opens themes
    When they select pack csk
    Then the app chrome uses CSK tokens
    And the selection persists across restart

  Scenario: Alarms survive restart
    Given future drives with alarm offsets
    When the app cold-starts
    Then alarms for those drives are rescheduled
