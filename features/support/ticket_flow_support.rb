# Reset the TicketGithubIssueService test seam between scenarios so a stubbed
# GitHub issue result never leaks across scenarios.
After do
  TicketGithubIssueService.test_result = nil
end
