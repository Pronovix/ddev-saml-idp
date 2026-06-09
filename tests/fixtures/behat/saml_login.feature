@api @javascript
Feature: SAML Auth Login
  Scenario: Log in via SimpleSAMLphp IDP
    Given I am on "/saml/login"
    Then I fill in "username" with "user1"
    And I fill in "password" with "password"
    And I press "loginsubmit"
    Then I should see the link "Log out"
